import base64
import json
import httpx
from app.core.config import settings
from app.services.rag_service import search_ecodes, get_rag_context

BASE_API_URL = "https://generativelanguage.googleapis.com/v1beta/models"

async def _call_gemini(payload: dict) -> str:
    """Call Google AI Studio generateContent API, return text response."""
    async with httpx.AsyncClient(timeout=120) as client:
        url = f"{BASE_API_URL}/{settings.GEMINI_MODEL}:generateContent"
        response = await client.post(
            f"{url}?key={settings.GEMINI_API_KEY}",
            json=payload,
        )
        response.raise_for_status()
        return response.json()["candidates"][0]["content"]["parts"][0]["text"]

def _build_payload(image_b64: str, text: str) -> dict:
    return {
        "contents": [{
            "parts": [
                {"inline_data": {"mime_type": "image/jpeg", "data": image_b64}},
                {"text": text},
            ]
        }]
    }

async def analyze_label(image_bytes: bytes, profile: dict) -> dict:
    image_b64 = base64.b64encode(image_bytes).decode("utf-8")

    # --- STAGE 1: OCR ---
    ocr_prompt = (
        "Identify and list only the ingredients and E-codes from this food label image. "
        'Respond ONLY with a valid JSON object: {"ingredients": ["item1", "E102", ...]}'
    )
    ingredients = []
    try:
        ocr_text = await _call_gemini(_build_payload(image_b64, ocr_prompt))
        ocr_clean = ocr_text.strip().replace("```json", "").replace("```", "").strip()
        ingredients = json.loads(ocr_clean).get("ingredients", [])
    except Exception as e:
        print(f"OCR Stage failed: {e}")

    # --- STAGE 2: RAG LOOKUP ---
    rag_context = get_rag_context(ingredients)

    # --- STAGE 3: FULL ANALYSIS ---
    final_prompt = f"""You are "Food-Safe AI", a global expert in toxicology, food chemistry, and public health.
Analyze the food label in this image accurately, leveraging the scientific context provided below.

USER HEALTH PROFILE:
- Allergies: {profile.get('allergies', [])}
- Chronic Diseases: {profile.get('conditions', [])}
- Special Status: {profile.get('special', [])}

SCIENTIFIC CONTEXT (RAG):
{rag_context}

RESPOND ONLY IN VALID JSON:
{{
  "product_name": "string",
  "detected_language": "string",
  "ingredients": ["list"],
  "ecodes": [
    {{
      "code": "E123",
      "name": "Name",
      "function": "Function",
      "simple_explanation": "Simple description",
      "risk_level": "🔴|🟡|🟢",
      "citation": "Scientific source"
    }}
  ],
  "simplified_ingredients": [
    {{"original": "Complex Name", "simplified": "Simple explanation"}}
  ],
  "cross_contamination_warnings": ["warnings"],
  "overall_safety": {{
    "status": "DANGEROUS|CAUTION|SAFE",
    "color": "red|yellow|green",
    "reasoning": "Explanation"
  }},
  "recommendation": "Final advice",
  "scientific_sources": ["list"]
}}"""

    try:
        raw_text = await _call_gemini(_build_payload(image_b64, final_prompt))
        clean = raw_text.strip().replace("```json", "").replace("```", "").strip()
        result = json.loads(clean)

        rag_findings = search_ecodes(ingredients)
        if rag_findings:
            result["rag_verified_sources"] = rag_findings

        return result
    except (KeyError, json.JSONDecodeError, IndexError) as e:
        return {
            "error": "Failed to parse final AI response",
            "details": str(e),
        }