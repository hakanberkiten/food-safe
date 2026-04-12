from __future__ import annotations

import json
import logging

from app.core.config import settings
from app.schemas.food_safe import (
    IngredientExtraction,
    ModelExecutionTrace,
    RiskAssessment,
    ToxicologyFinding,
    UserHealthProfile,
)
from app.services.google_ai import GoogleAIJSONClient
from app.services.market import MarketRecommendationService

logger = logging.getLogger(__name__)


class FoodSafetyReasoner:
    def __init__(
        self,
        market_service: MarketRecommendationService | None = None,
        model_name: str | None = None,
    ) -> None:
        self.market_service = market_service or MarketRecommendationService()
        self.model_name = model_name or settings.REASONING_MODEL or settings.GEMMA_REASONING_MODEL
        self.fallback_model = settings.REASONING_FALLBACK_MODEL
        self.ai_client = GoogleAIJSONClient()

    async def synthesize(
        self,
        extracted_label: IngredientExtraction,
        retrieved_evidence: list[ToxicologyFinding],
        user_profile: UserHealthProfile,
    ) -> tuple[RiskAssessment, ModelExecutionTrace]:
        if self.ai_client.available:
            try:
                llm_result = await self.ai_client.generate_json(
                    stage="reasoning",
                    preferred_model=self.model_name,
                    fallback_model=self.fallback_model,
                    contents=self._build_reasoning_prompt(
                        extracted_label=extracted_label,
                        retrieved_evidence=retrieved_evidence,
                        user_profile=user_profile,
                    ),
                    schema=RiskAssessment,
                    temperature=0.1,
                )
                report = self._normalize_report(llm_result.payload)
                report = self._post_process_report(
                    report=report,
                    extracted_label=extracted_label,
                    user_profile=user_profile,
                )
                return report, llm_result.trace
            except Exception as error:
                logger.warning(
                    "Reasoning stage failed on Google models and switched to heuristic synthesis.",
                    exc_info=error,
                )

        report = self._heuristic_synthesis(
            extracted_label=extracted_label,
            retrieved_evidence=retrieved_evidence,
            user_profile=user_profile,
        )
        if not self.ai_client.available:
            logger.warning("Reasoning stage is using heuristic fallback because GEMINI_API_KEY is missing.")
        trace = ModelExecutionTrace(
            stage="reasoning",
            preferred_model=self.model_name,
            actual_model="heuristic-fallback",
            fallback_model=self.fallback_model,
            fallback_used=True,
            notes=[
                "Structured Google model reasoning was unavailable.",
                "Heuristic synthesis generated the risk report.",
            ],
        )
        return report, trace

    def _heuristic_synthesis(
        self,
        extracted_label: IngredientExtraction,
        retrieved_evidence: list[ToxicologyFinding],
        user_profile: UserHealthProfile,
    ) -> RiskAssessment:
        enriched_findings = [
            finding.model_copy(update={"profile_flags": self._profile_flags(finding, user_profile)})
            for finding in retrieved_evidence
        ]

        overall_risk, status = self._compute_overall_risk(enriched_findings)
        personalized_considerations = self._build_personalized_considerations(
            enriched_findings, user_profile
        )
        scientific_basis = self._build_scientific_basis(enriched_findings)
        next_steps = self._build_next_steps(status)

        safer_alternatives = []
        if status == "HIGH_RISK":
            # TODO: Insert Gemma 4 function calling here.
            # The model should call a Market API tool only when the product is high risk.
            safer_alternatives = self.market_service.get_healthier_alternatives(
                extracted_label=extracted_label,
                user_profile=user_profile,
            )

        summary = self._build_summary(status, enriched_findings, personalized_considerations)

        return RiskAssessment(
            overall_risk=overall_risk,
            status=status,
            summary=summary,
            personalized_considerations=personalized_considerations,
            ingredient_assessments=enriched_findings,
            safer_alternatives=safer_alternatives,
            scientific_basis=scientific_basis,
            next_steps=next_steps,
        )

    def _build_reasoning_prompt(
        self,
        *,
        extracted_label: IngredientExtraction,
        retrieved_evidence: list[ToxicologyFinding],
        user_profile: UserHealthProfile,
    ) -> str:
        payload = {
            "extracted_label": extracted_label.model_dump(),
            "retrieved_evidence": [finding.model_dump() for finding in retrieved_evidence],
            "user_profile": user_profile.model_dump(),
        }
        return (
            "You are the reasoning stage of Gemma 4 Food-Safe AI. "
            "Use only the provided extracted ingredients, retrieved toxicology evidence, and user profile. "
            "Return valid JSON matching the RiskAssessment schema. "
            "Do not invent scientific claims. If evidence is weak, say so explicitly.\n\n"
            f"{json.dumps(payload, ensure_ascii=False)}"
        )

    def _normalize_report(self, payload: RiskAssessment | dict) -> RiskAssessment:
        if isinstance(payload, RiskAssessment):
            return payload
        return RiskAssessment.model_validate(payload)

    def _post_process_report(
        self,
        *,
        report: RiskAssessment,
        extracted_label: IngredientExtraction,
        user_profile: UserHealthProfile,
    ) -> RiskAssessment:
        if report.status == "HIGH_RISK" and not report.safer_alternatives:
            report = report.model_copy(
                update={
                    "safer_alternatives": self.market_service.get_healthier_alternatives(
                        extracted_label=extracted_label,
                        user_profile=user_profile,
                    )
                }
            )
        return report

    def _profile_flags(
        self, finding: ToxicologyFinding, user_profile: UserHealthProfile
    ) -> list[str]:
        flags: list[str] = []
        text = " ".join([finding.ingredient, finding.normalized_name, finding.summary, *finding.evidence]).lower()
        profile_terms = [
            *[item.lower() for item in user_profile.allergies],
            *[item.lower() for item in user_profile.conditions],
            *[item.lower() for item in user_profile.special],
        ]

        if any(term in text for term in profile_terms if term):
            flags.append("Ingredient overlaps with the user profile keywords.")

        if any(term in profile_terms for term in ["hamile", "pregnant", "pregnancy"]) and any(
            keyword in text for keyword in ["nitrite", "nitrosamine", "preservative"]
        ):
            flags.append("Processed preservative exposure deserves extra caution during pregnancy.")

        if any(term in profile_terms for term in ["çölyak", "celiac", "gluten"]) and any(
            keyword in text for keyword in ["gluten", "wheat", "barley", "malt"]
        ):
            flags.append("Potential gluten-related concern for celiac or gluten-sensitive users.")

        if any(term in profile_terms for term in ["tansiyon", "hypertension"]) and "sodium" in text:
            flags.append("Sodium-containing additives may be unsuitable for hypertension management.")

        if any(term in profile_terms for term in ["pku", "phenylketonuria"]) and any(
            keyword in text for keyword in ["aspartame", "phenylalanine"]
        ):
            flags.append("Phenylalanine exposure should be avoided in PKU.")

        return flags

    def _compute_overall_risk(
        self, findings: list[ToxicologyFinding]
    ) -> tuple[str, str]:
        if not findings:
            return "moderate", "CAUTION"

        risk_points = {"unknown": 1, "low": 0, "moderate": 2, "high": 3}
        total_score = sum(risk_points[finding.risk_level] for finding in findings)
        has_personalized_high_risk = any(
            finding.risk_level in {"moderate", "high"} and finding.profile_flags
            for finding in findings
        )

        if has_personalized_high_risk or total_score >= max(4, len(findings) * 2):
            return "high", "HIGH_RISK"
        if total_score >= 2 or any(finding.profile_flags for finding in findings):
            return "moderate", "CAUTION"
        return "low", "SAFE"

    def _build_personalized_considerations(
        self, findings: list[ToxicologyFinding], user_profile: UserHealthProfile
    ) -> list[str]:
        considerations = [flag for finding in findings for flag in finding.profile_flags]

        has_profile_context = bool(
            user_profile.allergies or user_profile.conditions or user_profile.special
        )

        if not considerations and has_profile_context:
            considerations.append(
                "No direct profile-specific conflict was matched by the fallback rules; confirm with the final Gemma reasoning step."
            )

        return list(dict.fromkeys(considerations))

    def _build_scientific_basis(self, findings: list[ToxicologyFinding]) -> list[str]:
        basis = []
        for finding in findings:
            for source in finding.sources:
                basis.append(f"{source.organization}: {source.title}")
        return list(dict.fromkeys(basis))

    def _build_next_steps(self, status: str) -> list[str]:
        if status == "HIGH_RISK":
            return [
                "Avoid recommending this product as-is.",
                "Use market alternatives or request a clinician review for vulnerable users.",
                "Log the matched toxicology evidence for auditability.",
            ]
        if status == "CAUTION":
            return [
                "Show the evidence snippets and let the user inspect the matched ingredients.",
                "Ask for a richer health profile to improve personalization.",
            ]
        return [
            "Product appears broadly acceptable under the current fallback rules.",
            "Still display evidence provenance so the user can verify the recommendation.",
        ]

    def _build_summary(
        self,
        status: str,
        findings: list[ToxicologyFinding],
        personalized_considerations: list[str],
    ) -> str:
        if not findings:
            return (
                "No ingredients were extracted yet, so the workflow should re-run the Vision stage with Gemma 4 multimodal output enabled."
            )

        high_risk_items = [finding.ingredient for finding in findings if finding.risk_level == "high"]
        personalized_note = (
            personalized_considerations[0] if personalized_considerations else "No direct profile-specific flag detected."
        )

        if status == "HIGH_RISK":
            return (
                f"High-risk outcome triggered by {', '.join(high_risk_items or [findings[0].ingredient])}. "
                f"Primary personalized concern: {personalized_note}"
            )
        if status == "CAUTION":
            return (
                f"Caution recommended because the retrieved evidence is incomplete or moderately risky. "
                f"Primary personalized concern: {personalized_note}"
            )
        return (
            "Current evidence suggests a low-risk profile for the detected ingredients. "
            f"Primary note: {personalized_note}"
        )
