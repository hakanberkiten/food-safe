from __future__ import annotations

import json
import logging
from dataclasses import dataclass
from typing import Any, TypeVar

from google import genai
from google.genai import types

from app.core.config import settings
from app.schemas.food_safe import ModelExecutionTrace

logger = logging.getLogger(__name__)

SchemaType = TypeVar("SchemaType")


@dataclass
class ModelRunResult:
    payload: Any
    trace: ModelExecutionTrace


class GoogleAIJSONClient:
    def __init__(self, api_key: str | None = None) -> None:
        self.api_key = api_key or settings.GEMINI_API_KEY
        self._client = genai.Client(api_key=self.api_key) if self.api_key else None

    @property
    def available(self) -> bool:
        return self._client is not None

    async def generate_json(
        self,
        *,
        stage: str,
        preferred_model: str,
        fallback_model: str | None,
        contents: Any,
        schema: type[SchemaType],
        temperature: float = 0.1,
    ) -> ModelRunResult:
        if not self._client:
            raise RuntimeError("GEMINI_API_KEY is not configured.")

        try:
            payload = await self._call_model(
                model_name=preferred_model,
                contents=contents,
                schema=schema,
                temperature=temperature,
            )
            return ModelRunResult(
                payload=payload,
                trace=ModelExecutionTrace(
                    stage=stage,
                    preferred_model=preferred_model,
                    actual_model=preferred_model,
                ),
            )
        except Exception as preferred_error:
            if not fallback_model:
                raise

            logger.warning(
                "Preferred model failed at stage '%s'. Falling back from %s to %s.",
                stage,
                preferred_model,
                fallback_model,
                exc_info=preferred_error,
            )

            payload = await self._call_model(
                model_name=fallback_model,
                contents=contents,
                schema=schema,
                temperature=temperature,
            )
            return ModelRunResult(
                payload=payload,
                trace=ModelExecutionTrace(
                    stage=stage,
                    preferred_model=preferred_model,
                    actual_model=fallback_model,
                    fallback_model=fallback_model,
                    fallback_used=True,
                    notes=[
                        f"Preferred model error: {preferred_error.__class__.__name__}",
                        "Gemini fallback path activated.",
                    ],
                ),
            )

    async def _call_model(
        self,
        *,
        model_name: str,
        contents: Any,
        schema: type[SchemaType],
        temperature: float,
    ) -> SchemaType:
        response = await self._client.aio.models.generate_content(
            model=model_name,
            contents=contents,
            config=types.GenerateContentConfig(
                temperature=temperature,
                response_mime_type="application/json",
                response_schema=schema,
            ),
        )

        if getattr(response, "parsed", None) is not None:
            return response.parsed

        raw_text = getattr(response, "text", None)
        if not raw_text:
            raise ValueError(f"Model {model_name} returned no parseable JSON payload.")

        cleaned = raw_text.strip().replace("```json", "").replace("```", "").strip()
        parsed = json.loads(cleaned)

        if hasattr(schema, "model_validate"):
            return schema.model_validate(parsed)
        return parsed
