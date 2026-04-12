from app.schemas.food_safe import UserHealthProfile
from app.workflows.agent_workflow import FoodSafeAgentWorkflow

workflow = FoodSafeAgentWorkflow()


async def analyze_label(image_bytes: bytes, profile: dict) -> dict:
    user_profile = UserHealthProfile.model_validate(profile or {})
    result = await workflow.run(
        image_bytes=image_bytes,
        user_profile=user_profile,
        mime_type="image/jpeg",
    )
    return result.model_dump()
