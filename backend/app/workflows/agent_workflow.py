from __future__ import annotations

import logging
import re

from app.schemas.food_safe import UserHealthProfile, WorkflowOutput
from app.services.market import MarketRecommendationService
from app.services.rag import ToxicologyRAGService
from app.services.reasoning import FoodSafetyReasoner
from app.services.vision import VisionService

logger = logging.getLogger(__name__)

LOW_SIGNAL_INGREDIENTS = {
    "salt",
    "water",
    "onion powder",
    "garlic powder",
    "white pepper",
    "black pepper",
    "ginger powder",
    "chili powder",
    "caramel",
}


class FoodSafeAgentWorkflow:
    def __init__(
        self,
        vision_service: VisionService | None = None,
        rag_service: ToxicologyRAGService | None = None,
        reasoning_service: FoodSafetyReasoner | None = None,
    ) -> None:
        market_service = MarketRecommendationService()
        self.vision_service = vision_service or VisionService()
        self.rag_service = rag_service or ToxicologyRAGService()
        self.reasoning_service = reasoning_service or FoodSafetyReasoner(
            market_service=market_service
        )

    def _select_focus_ingredients(self, ingredients: list[str]) -> list[str]:
        return _select_relevant_ingredients(ingredients)

    async def run(
        self,
        image_bytes: bytes,
        user_profile: UserHealthProfile,
        mime_type: str = "image/jpeg",
    ) -> WorkflowOutput:
        logger.info("Workflow started. mime_type=%s image_bytes=%s", mime_type, len(image_bytes))
        logger.info("Workflow entering vision stage.")
        extracted_label, vision_trace = await self.vision_service.extract_label(
            image_bytes=image_bytes,
            mime_type=mime_type,
        )
        logger.info(
            "Workflow vision stage completed. ingredients=%s claims=%s fallback_used=%s actual_model=%s",
            len(extracted_label.ingredients),
            len(extracted_label.claims),
            vision_trace.fallback_used,
            vision_trace.actual_model,
        )
        logger.info("Workflow entering RAG stage.")
        focus_ingredients = self._select_focus_ingredients(extracted_label.ingredients)
        logger.info(
            "Workflow selected focus ingredients for RAG. original=%s focused=%s",
            len(extracted_label.ingredients),
            len(focus_ingredients),
        )
        retrieved_evidence = self.rag_service.retrieve(focus_ingredients)
        logger.info("Workflow RAG stage completed. findings=%s", len(retrieved_evidence))
        logger.info("Workflow entering reasoning stage.")
        risk_report, reasoning_trace = await self.reasoning_service.synthesize(
            extracted_label=extracted_label,
            retrieved_evidence=retrieved_evidence,
            user_profile=user_profile,
        )
        logger.info(
            "Workflow reasoning stage completed. status=%s fallback_used=%s actual_model=%s",
            risk_report.status,
            reasoning_trace.fallback_used,
            reasoning_trace.actual_model,
        )

        return WorkflowOutput(
            extracted_label=extracted_label,
            retrieved_evidence=retrieved_evidence,
            risk_report=risk_report,
            execution_metadata=[vision_trace, reasoning_trace],
        )


async def analyze_food_label(
    image_bytes: bytes,
    profile_data: dict,
    mime_type: str = "image/jpeg",
) -> WorkflowOutput:
    workflow = FoodSafeAgentWorkflow()
    profile = UserHealthProfile.model_validate(profile_data or {})
    return await workflow.run(
        image_bytes=image_bytes,
        user_profile=profile,
        mime_type=mime_type,
    )


    
    
    
    
def _normalize_ingredient_name(ingredient: str) -> str:
    lowered = ingredient.lower().strip()
    lowered = re.sub(r"\s+", " ", lowered)
    return lowered.strip(",.;:() ")


def _looks_high_signal(ingredient: str) -> bool:
    lowered = _normalize_ingredient_name(ingredient)
    keywords = [
        "e",
        "sodium",
        "potassium",
        "phosphate",
        "glutamate",
        "glycerol",
        "sorbitol",
        "carbonate",
        "emulsifier",
        "regulator",
        "thickener",
        "colour",
        "color",
        "flavour",
        "flavor",
        "extract",
        "protein",
        "gum",
    ]
    if any(char.isdigit() for char in lowered):
        return True
    if "(" in ingredient or ")" in ingredient:
        return True
    return any(keyword in lowered for keyword in keywords)


def _dedupe_ingredients(ingredients: list[str]) -> list[str]:
    seen: set[str] = set()
    deduped: list[str] = []
    for ingredient in ingredients:
        normalized = _normalize_ingredient_name(ingredient)
        if not normalized or normalized in seen:
            continue
        seen.add(normalized)
        deduped.append(ingredient.strip())
    return deduped


def _select_relevant_ingredients(ingredients: list[str], limit: int = 8) -> list[str]:
    deduped = _dedupe_ingredients(ingredients)
    prioritized = [
        ingredient
        for ingredient in deduped
        if _looks_high_signal(ingredient)
        and _normalize_ingredient_name(ingredient) not in LOW_SIGNAL_INGREDIENTS
    ]
    if prioritized:
        return prioritized[:limit]

    fallback = [
        ingredient
        for ingredient in deduped
        if _normalize_ingredient_name(ingredient) not in LOW_SIGNAL_INGREDIENTS
    ]
    return fallback[:limit]
