import json
import os
from pathlib import Path
from typing import List, Dict

KNOWLEDGE_BASE_PATH = Path("knowledge/ecodes.json")

def search_ecodes(ingredients: List[str]) -> List[Dict]:
    """
    Simulates a RAG search by finding relevant E-code information for detected ingredients.
    """
    if not KNOWLEDGE_BASE_PATH.exists():
        return []
    
    with open(KNOWLEDGE_BASE_PATH, "r") as f:
        knowledge = json.load(f)
        
    findings = []
    # Simplified search: look for E-code mentions in the ingredient list
    for entry in knowledge:
        code = entry["code"]
        for ing in ingredients:
            if code.lower() in ing.lower() or entry["name"].lower() in ing.lower():
                findings.append(entry)
                break
                
    return findings

def get_rag_context(ingredients: List[str]) -> str:
    """
    Formats the RAG findings into a context string for the LLM.
    """
    findings = search_ecodes(ingredients)
    if not findings:
        return "No specific literature source found for these ingredients."
    
    context = "Relevant Scientific Data Found:\n"
    for f in findings:
        context += f"- {f['name']} ({f['code']}): {f['description']} Risks: {', '.join(f['risks'])}. Source: {f['source']}\n"
    
    return context
