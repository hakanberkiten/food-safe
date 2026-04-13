import base64
import json
import httpx
from app.core.config import settings
from app.services.rag_service import search_ecodes, get_rag_context

# Base URL for Google AI Studio API
BASE_API_URL = "https://generativelanguage.googleapis.com/v1beta/models"

async def _call_gemini(payload: dict) -> dict:
    """Helper to make AI model API calls (e.g., Gemma 4)."""
    async with httpx.AsyncClient(timeout=60) as client:
        # Get model from settings (default: gemma-4)
        model = getattr(settings, "GEMINI_MODEL", "gemma-4")
        
        # Construct the URL dynamically
        url = f"{BASE_API_URL}/{model}:generateContent"
            
        api_key = settings.GEMINI_API_KEY
        
        response = await client.post(
            f"{url}?key={api_key}",
            json=payload
        )
        response.raise_for_status()
        return response.json()

async def analyze_label(image_bytes: bytes, profile: dict) -> dict:
    """
    Analyzes a food label image using a two-stage RAG process.
    Stage 1: Extract ingredients for RAG lookup.
    Stage 2: Perform final analysis using RAG context.
    """
    image_b64 = base64.b64encode(image_bytes).decode("utf-8")

    # --- STAGE 1: QUICK OCR FOR INGREDIENTS ---
    ocr_prompt = """
    Identify and list only the ingredients and E-codes from this food label image.
    Respond ONLY with a valid JSON object in this format:
    {"ingredients": ["item1", "item2", "E102", ...]}
    """
    
    ocr_payload = {
        "contents": [{
            "parts": [
                {
                    "inline_data": {
                        "mime_type": "image/jpeg",
                        "data": image_b64
                    }
                },
                {"text": ocr_prompt}
            ]
        }]
    }

    ingredients = []
    try:
        ocr_data = await _call_gemini(ocr_payload)
        ocr_text = ocr_data["candidates"][0]["content"]["parts"][0]["text"]
        # Clean potential markdown
        ocr_clean = ocr_text.strip().replace("```json", "").replace("```", "").strip()
        ingredients_resp = json.loads(ocr_clean)
        ingredients = ingredients_resp.get("ingredients", [])
    except Exception as e:
        print(f"OCR Stage failed: {e}")
        # We continue even if OCR fails, the second stage will try its best.

    # --- STAGE 2: RAG LOOKUP ---
    rag_context = get_rag_context(ingredients)
    
    # --- STAGE 3: COMPREHENSIVE ANALYSIS WITH RAG CONTEXT ---
    final_prompt = f"""
You are "Food-Safe AI", a global expert in toxicology, food chemistry, and public health.
Analyze the food label in this image accurately, leveraging the scientific context provided below.

USER HEALTH PROFILE:
- Allergies: {profile.get('allergies', [])}
- Chronic Diseases: {profile.get('conditions', [])}
- Special Status: {profile.get('special', [])}

SCIENTIFIC CONTEXT (RAG):
{rag_context}

### YOUR TASKS:
1. **Multilingual OCR**: Extract ALL text. Identify the language.
2. **Ingredient Analysis**: Use the SCIENTIFIC CONTEXT to explain risks for detected ingredients/E-codes.
3. **Safety Assessment**: Mark each risky item with a color-coded level based on the USER PROFILE and SCIENTIFIC CONTEXT.
4. **Consistency**: Ensure your analysis matches the scientific data provided in the context.

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
      "citation": "Scientific source (Reference the RAG data if available)"
    }}
  ],
  "simplified_ingredients": [
    {{
      "original": "Complex Name",
      "simplified": "Simple explanation"
    }}
  ],
  "cross_contamination_warnings": ["warnings"],
  "overall_safety": {{
    "status": "DANGEROUS|CAUTION|SAFE",
    "color": "red|yellow|green",
    "reasoning": "Detailed explanation using scientific context and user profile"
  }},
  "recommendation": "Final advice",
  "scientific_sources": ["list of sources from context"]
}}
"""

    final_payload = {
        "contents": [{
            "parts": [
                {
                    "inline_data": {
                        "mime_type": "image/jpeg",
                        "data": image_b64
                    }
                },
                {"text": final_prompt}
            ]
        }]
    }

    try:
        final_data = await _call_gemini(final_payload)
        raw_text = final_data["candidates"][0]["content"]["parts"][0]["text"]
        clean = raw_text.strip().replace("```json", "").replace("```", "").strip()
        result = json.loads(clean)
        
        # Post-process: explicitly add the RAG findings for UI highlights
        rag_findings = search_ecodes(ingredients)
        if rag_findings:
            result["rag_verified_sources"] = rag_findings
            
        return result
    except (KeyError, json.JSONDecodeError, IndexError) as e:
        return {
            "error": "Failed to parse final AI response",
            "details": str(e),
            "raw": final_data if 'final_data' in locals() else None
        }