from app.services.rag_service import get_rag_context
# ... existing imports ...

async def analyze_label(image_bytes: bytes, profile: dict) -> dict:
    image_b64 = base64.b64encode(image_bytes).decode("utf-8")

    # Initial quick scan for ingredients to feed RAG (simulated)
    # In a real app, we might do OCR first, then RAG, then final analysis.
    # For now, we'll let the LLM be the first pass and then handle citations.
    
    rag_context = "" # We'll populate this if possible, or use a multi-step approach.
    
    prompt = f"""
You are "Food-Safe AI", a global expert in toxicology, food chemistry, and public health.
Analyze the food label in this image accurately.

USER HEALTH PROFILE:
- Allergies: {profile.get('allergies', [])}
- Chronic Diseases: {profile.get('conditions', [])}
- Special Status: {profile.get('special', [])}

### YOUR TASKS:
1. **Multilingual OCR**: Extract ALL text from the label. Identify the language. Support Japanese, Arabic, Chinese, Turkish, etc.
2. **Ingredient Identification**: List all ingredients in a clean format. Use English as primary but include original names if translated.
3. **E-Code Detection**: Catch all E-codes (e.g., E102, E621). Explain what they are in simple terms.
4. **Chemical Simplification**: Translate complex chemical names into "Layperson's Language".
5. **Cross-Contamination**: Detect warnings like "may contain", "produced in a facility that also processes...".
6. **Safety Assessment**: Mark each risky item with a color-coded level:
   - 🔴 DANGEROUS: Do not consume (direct conflict with profile).
   - 🟡 CAUTION: Consult a doctor (uncertain or secondary risk).
   - 🟢 SAFE: Generally safe for this user.
7. **Scientific Citations (RAG)**: provide references to FDA, WHO, or scientific literature where applicable.

RESPOND ONLY IN VALID JSON:
{{
  "product_name": "string",
  "detected_language": "string",
  "ingredients": ["list"],
  "ecodes": [
    {{
      "code": "E621",
      "name": "MSG",
      "function": "Flavor enhancer",
      "simple_explanation": "Simplified description",
      "risk_level": "🔴|🟡|🟢",
      "citation": "Source info (FDA/WHO)"
    }}
  ],
  "simplified_ingredients": [
    {{
      "original": "Phenylalanine",
      "simplified": "Amino acid (dangerous for PKU)"
    }}
  ],
  "cross_contamination_warnings": ["warnings"],
  "overall_safety": {{
    "status": "DANGEROUS|CAUTION|SAFE",
    "color": "red|yellow|green",
    "reasoning": "Direct explanation of why this status was chosen"
  }},
  "recommendation": "Final user advice",
  "scientific_sources": ["list of sources"]
}}
"""

    payload = {
        "contents": [
            {
                "parts": [
                    {
                        "inline_data": {
                            "mime_type": "image/jpeg",
                            "data": image_b64
                        }
                    },
                    {"text": prompt}
                ]
            }
        ]
    }

    async with httpx.AsyncClient(timeout=60) as client:
        response = await client.post(
            f"{settings.GEMINI_API_URL if hasattr(settings, 'GEMINI_API_URL') else GEMMA_API_URL}?key={settings.GEMINI_API_KEY}",
            json=payload
        )
        response.raise_for_status()
        data = response.json()

    try:
        raw_text = data["candidates"][0]["content"]["parts"][0]["text"]
        clean = raw_text.strip().replace("```json", "").replace("```", "").strip()
        result = json.loads(clean)
        
        # Post-process with RAG for database citations
        rag_info = search_ecodes(result.get("ingredients", []))
        if rag_info:
            result["rag_verified_sources"] = rag_info
            
        return result
    except (KeyError, json.JSONDecodeError, IndexError) as e:
        # Fallback/Debug
        return {"error": "Failed to parse AI response", "raw": data}