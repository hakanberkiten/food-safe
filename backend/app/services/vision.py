from __future__ import annotations

import logging
from io import BytesIO
from typing import Any

from app.core.config import settings
from app.schemas.food_safe import IngredientExtraction, ModelExecutionTrace
from app.services.google_ai import GoogleAIJSONClient
from google.genai import types
from PIL import Image

logger = logging.getLogger(__name__)


class VisionService:
    def __init__(self, model_name: str | None = None) -> None:
        self.model_name = model_name or settings.VISION_MODEL or settings.GEMMA_VISION_MODEL
        self.fallback_model = settings.VISION_FALLBACK_MODEL
        self.ai_client = GoogleAIJSONClient()

    async def extract_label(
        self, image_bytes: bytes, mime_type: str = "image/jpeg"
    ) -> tuple[IngredientExtraction, ModelExecutionTrace]:
        if not image_bytes:
            raise ValueError("image_bytes cannot be empty")

        processed_bytes, processed_mime_type = self._prepare_image(image_bytes, mime_type)
        logger.info(
            "Vision extract_label started. preferred_model=%s fallback_model=%s mime_type=%s bytes=%s",
            self.model_name,
            self.fallback_model,
            processed_mime_type,
            len(processed_bytes),
        )
        prompt = self.build_prompt()
        contents = [
            prompt,
            types.Part.from_bytes(data=processed_bytes, mime_type=processed_mime_type),
        ]

        if self.ai_client.available:
            try:
                result = await self.ai_client.generate_json(
                    stage="vision",
                    preferred_model=self.model_name,
                    fallback_model=self.fallback_model,
                    contents=contents,
                    schema=IngredientExtraction,
                    temperature=0.0,
                )
                extraction = self._normalize_extraction(result.payload)
                logger.info(
                    "Vision model call completed. actual_model=%s fallback_used=%s ingredients=%s",
                    result.trace.actual_model,
                    result.trace.fallback_used,
                    len(extraction.ingredients),
                )
                return extraction, result.trace
            except Exception as error:
                logger.warning(
                    "Vision stage failed on Google models and switched to empty fallback output.",
                    exc_info=error,
                )
                trace = ModelExecutionTrace(
                    stage="vision",
                    preferred_model=self.model_name,
                    actual_model="heuristic-empty-output",
                    fallback_model=self.fallback_model,
                    fallback_used=True,
                    notes=[
                        f"Vision model failure: {error.__class__.__name__}",
                        "Empty extraction fallback activated.",
                    ],
                )
                return self._empty_extraction(), trace

        mock_response = self._empty_extraction()
        logger.warning("Vision stage is using fallback output because GEMINI_API_KEY is missing.")
        trace = ModelExecutionTrace(
            stage="vision",
            preferred_model=self.model_name,
            actual_model="heuristic-no-api-key",
            fallback_model=self.fallback_model,
            fallback_used=True,
            notes=["GEMINI_API_KEY is missing. Vision stage used empty fallback output."],
        )
        return mock_response, trace

    def build_prompt(self) -> str:
        return f"""
You are the Vision stage of the Gemma 4 Food-Safe AI system.
Read the product label image and return valid JSON only.

Target model: {self.model_name}

Required JSON schema:
{{
  "product_name": "string | null",
  "ingredients": ["E211", "maltodextrin", "aspartame"],
  "claims": ["sugar free", "gluten free"],
  "allergens": ["milk", "soy"],
  "cross_contamination_warnings": ["may contain nuts"],
  "detected_language": "tr",
  "raw_text": "optional OCR text"
}}
""".strip()

    def _empty_extraction(self) -> IngredientExtraction:
        return IngredientExtraction.model_validate(
            {
                "product_name": None,
                "ingredients": [],
                "claims": [],
                "allergens": [],
                "cross_contamination_warnings": [],
                "detected_language": None,
                "raw_text": None,
            }
        )

    def _normalize_extraction(self, payload: IngredientExtraction | dict[str, Any]) -> IngredientExtraction:
        if isinstance(payload, IngredientExtraction):
            return payload
        return IngredientExtraction.model_validate(payload)

    def _prepare_image(self, image_bytes: bytes, mime_type: str) -> tuple[bytes, str]:
        try:
            with Image.open(BytesIO(image_bytes)) as image:
                max_dim = 1600
                if max(image.size) <= max_dim and mime_type == "image/jpeg":
                    return image_bytes, mime_type

                image = image.convert("RGB")
                image.thumbnail((max_dim, max_dim))
                buffer = BytesIO()
                image.save(buffer, format="JPEG", quality=85, optimize=True)
                processed = buffer.getvalue()
                logger.info(
                    "Vision image preprocessed. original_bytes=%s processed_bytes=%s",
                    len(image_bytes),
                    len(processed),
                )
                return processed, "image/jpeg"
        except Exception as error:
            logger.warning("Vision image preprocessing failed; using original bytes.", exc_info=error)
            return image_bytes, mime_type
