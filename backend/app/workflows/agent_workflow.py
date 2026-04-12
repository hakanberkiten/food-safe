from __future__ import annotations

from app.schemas.food_safe import UserHealthProfile, WorkflowOutput
from app.services.market import MarketRecommendationService
from app.services.rag import ToxicologyRAGService
from app.services.reasoning import FoodSafetyReasoner
from app.services.vision import VisionService


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

    async def run(
        self,
        image_bytes: bytes,
        user_profile: UserHealthProfile,
        mime_type: str = "image/jpeg",
    ) -> WorkflowOutput:
        extracted_label, vision_trace = await self.vision_service.extract_label(
            image_bytes=image_bytes,
            mime_type=mime_type,
        )
        retrieved_evidence = self.rag_service.retrieve(extracted_label.ingredients)
        risk_report, reasoning_trace = await self.reasoning_service.synthesize(
            extracted_label=extracted_label,
            retrieved_evidence=retrieved_evidence,
            user_profile=user_profile,
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
