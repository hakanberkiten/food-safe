import os
import pandas as pd
import chromadb
from chromadb.utils import embedding_functions

# Configuration
KNOWLEDGE_DIR = "knowledge"
CHROMA_PATH = "chroma_db"
COLLECTION_NAME = "food_safety_knowledge"
BATCH_SIZE = 100  # Process in batches for speed

def ingest_data():
    # Initialize ChromaDB
    client = chromadb.PersistentClient(path=CHROMA_PATH)
    
    # Use a lightweight local embedding model
    embedding_func = embedding_functions.SentenceTransformerEmbeddingFunction(
        model_name="all-MiniLM-L6-v2"
    )
    
    collection = client.get_or_create_collection(
        name=COLLECTION_NAME,
        embedding_function=embedding_func
    )

    def process_file(file_path, source_name, skip_rows=0):
        if not os.path.exists(file_path):
            print(f"File not found: {file_path}")
            return

        print(f"Processing {source_name}: {file_path}")
        
        # Try different encodings
        try:
            df = pd.read_csv(file_path, skiprows=skip_rows, encoding='utf-8')
        except UnicodeDecodeError:
            df = pd.read_csv(file_path, skiprows=skip_rows, encoding='latin-1')

        ids, docs, metadatas = [], [], []
        total = len(df)
        
        for idx, row in df.iterrows():
            if source_name == "FDA":
                name = str(row.get('Substance', '')).strip()
                extra = f"Effect: {str(row.get('Used for (Technical Effect)', ''))}. Other Names: {str(row.get('Other Names', ''))}"
            else:
                name = str(row.get('jecfa_name', '')).strip()
                extra = f"Class: {str(row.get('functional_class', ''))}. Synonyms: {str(row.get('synonyms', ''))}"

            if not name or name.lower() == 'nan':
                continue

            content = f"{source_name} Entry: {name}. {extra}."
            
            ids.append(f"{source_name.lower()}_{idx}")
            docs.append(content)
            metadatas.append({"source": source_name, "item_name": name})

            # Batch upload
            if len(ids) >= BATCH_SIZE:
                collection.add(ids=ids, documents=docs, metadatas=metadatas)
                ids, docs, metadatas = [], [], []
                print(f"Progress: {idx}/{total} rows indexed...", end='\r')

        # Upload remaining
        if ids:
            collection.add(ids=ids, documents=docs, metadatas=metadatas)
        
        print(f"\nCompleted {source_name} indexing.")

    # Execute ingestion
    process_file(os.path.join(KNOWLEDGE_DIR, "Food Substances.csv"), "FDA", skip_rows=4)
    process_file(os.path.join(KNOWLEDGE_DIR, "JECFA Insights.csv"), "JECFA")

    print("\nAll data ingestion complete!")

if __name__ == "__main__":
    if not os.path.exists(CHROMA_PATH):
        os.makedirs(CHROMA_PATH)
    ingest_data()
