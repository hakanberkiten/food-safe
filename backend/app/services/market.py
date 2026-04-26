from __future__ import annotations

from app.schemas.food_safe import AlternativeProduct, IngredientExtraction, UserHealthProfile


class MarketRecommendationService:
    def get_healthier_alternatives(
        self,
        extracted_label: IngredientExtraction,
        user_profile: UserHealthProfile,
        limit: int = 3,
    ) -> list[AlternativeProduct]:
        # TODO: Replace this mock implementation with a real Market API function call.
        # Example function signature:
        # `search_safer_products(avoid=["E250", "added sugar"], profile=user_profile.model_dump())`
        profile_tags = user_profile.allergies + user_profile.conditions + user_profile.special
        base_tags = [tag.lower() for tag in profile_tags]

        suggestions = [
            AlternativeProduct(
                name="Plain yogurt with no additives",
                reason="Short ingredient list and generally lower additive load.",
                tags=["minimal ingredients", *base_tags],
            ),
            AlternativeProduct(
                name="Unsweetened oat bar",
                reason="Targets the same snack use-case with fewer processed additives.",
                tags=["fiber", "no artificial color", *base_tags],
            ),
            AlternativeProduct(
                name="Fresh fruit and nut mix",
                reason="Whole-food option that avoids most preservative and coloring risks.",
                tags=["whole food", "low processing", *base_tags],
            ),
        ]
        return suggestions[:limit]
