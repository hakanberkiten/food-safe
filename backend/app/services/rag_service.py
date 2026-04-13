import os
import chromadb
from chromadb.utils import embedding_functions
from typing import List, Dict

CHROMA_PATH = "chroma_db"
COLLECTION_NAME = "food_safety_knowledge"

# Initialize Chroma client and collection
# Using lazy initialization to avoid issues during startup if DB is empty
_collection = None

def get_collection():
    global _collection
    if _collection is None:
        client = chromadb.PersistentClient(path=CHROMA_PATH)
        embedding_func = embedding_functions.SentenceTransformerEmbeddingFunction(
            model_name="all-MiniLM-L6-v2"
        )
        _collection = client.get_or_create_collection(
            name=COLLECTION_NAME,
            embedding_function=embedding_func
        )
    return _collection

def search_ecodes(ingredients: List[str], n_results: int = 3) -> List[Dict]:
    """
    Search for relevant scientific data in ChromaDB for the detected ingredients.
    """
    collection = get_collection()
    findings = []
    
    # Search for each ingredient/e-code
    for ing in ingredients:
        if not ing: continue
        
        results = collection.query(
            query_texts=[ing],
            n_results=n_results
        )
        
        # Format results
        for i in range(len(results['documents'][0])):
            findings.append({
                "content": results['documents'][0][i],
                "metadata": results['metadatas'][0][i],
                "distance": results['distances'][0][i]
            })
            
    # Deduplicate and sort by relevance (distance)
    # Lower distance means higher similarity
    unique_findings = {f['content']: f for f in findings}.values()
    sorted_findings = sorted(unique_findings, key=lambda x: x['distance'])
    
    # Return top results across all ingredients
    return list(sorted_findings)[:10]

def get_rag_context(ingredients: List[str]) -> str:
    """
    Formats the ChromaDB findings into a context string for the LLM.
    """
    findings = search_ecodes(ingredients)
    if not findings:
        return "No specific scientific data found in our local knowledge base for these substances."
    
    context = "SCIENTIFIC DATA RETRIEVED FROM LOCAL KNOWLEDGE BASE:\n"
    for f in findings:
        context += f"- {f['content']} [Source: {f['metadata'].get('source', 'Unknown')}]\n"
    
    return context
