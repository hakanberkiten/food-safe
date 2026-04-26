from __future__ import annotations

import argparse
import logging
import re
from pathlib import Path

try:
    import chromadb
except ImportError:
    chromadb = None
from pypdf import PdfReader

from app.core.config import settings

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
logger = logging.getLogger(__name__)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Ingest FDA/WHO PDF documents into Chroma for Food-Safe RAG."
    )
    parser.add_argument(
        "--reset",
        action="store_true",
        help="Delete the existing collection before re-ingesting.",
    )
    args = parser.parse_args()

    backend_root = Path(__file__).resolve().parent
    docs_dir = backend_root / "knowledge" / "reference_docs"
    pdf_files = sorted(docs_dir.glob("*.pdf"))

    if not pdf_files:
        raise SystemExit("No PDF files found in backend/knowledge/reference_docs")

    collection = get_collection(reset=args.reset)

    ids: list[str] = []
    documents: list[str] = []
    metadatas: list[dict] = []

    for pdf_path in pdf_files:
        logger.info("Processing %s", pdf_path.name)
        for page_number, page_text in extract_pdf_pages(pdf_path):
            for chunk_index, chunk in enumerate(chunk_text(page_text)):
                chunk_id = build_chunk_id(pdf_path.stem, page_number, chunk_index)
                ids.append(chunk_id)
                documents.append(chunk)
                metadatas.append(
                    {
                        "source_file": pdf_path.name,
                        "page_number": page_number,
                        "chunk_index": chunk_index,
                        "document_type": "pdf",
                    }
                )

    if not documents:
        raise SystemExit("PDF files were found but no text could be extracted.")

    logger.info("Uploading %s chunks to Chroma collection '%s'", len(documents), settings.CHROMA_COLLECTION)
    collection.upsert(ids=ids, documents=documents, metadatas=metadatas)
    logger.info("Ingestion complete.")


def get_collection(reset: bool = False):
    if settings.CHROMA_USE_CLOUD and settings.CHROMA_API_KEY and settings.CHROMA_TENANT and settings.CHROMA_DATABASE:
        client = chromadb.CloudClient(
            api_key=settings.CHROMA_API_KEY,
            tenant=settings.CHROMA_TENANT,
            database=settings.CHROMA_DATABASE,
        )
    else:
        persist_path = Path(__file__).resolve().parent / settings.CHROMA_PERSIST_DIRECTORY
        persist_path.mkdir(parents=True, exist_ok=True)
        client = chromadb.PersistentClient(path=str(persist_path))

    if reset:
        try:
            client.delete_collection(name=settings.CHROMA_COLLECTION)
            logger.info("Deleted existing collection '%s'", settings.CHROMA_COLLECTION)
        except Exception:
            logger.info("No existing collection to delete.")

    return client.get_or_create_collection(name=settings.CHROMA_COLLECTION)


def extract_pdf_pages(pdf_path: Path) -> list[tuple[int, str]]:
    reader = PdfReader(str(pdf_path))
    pages: list[tuple[int, str]] = []
    for index, page in enumerate(reader.pages, start=1):
        text = (page.extract_text() or "").strip()
        if text:
            pages.append((index, normalize_text(text)))
    return pages


def chunk_text(text: str, chunk_size: int = 1200, overlap: int = 200) -> list[str]:
    cleaned = normalize_text(text)
    if len(cleaned) <= chunk_size:
        return [cleaned]

    chunks: list[str] = []
    start = 0
    while start < len(cleaned):
        end = min(len(cleaned), start + chunk_size)
        chunks.append(cleaned[start:end].strip())
        if end == len(cleaned):
            break
        start = max(0, end - overlap)
    return [chunk for chunk in chunks if chunk]


def normalize_text(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def build_chunk_id(stem: str, page_number: int, chunk_index: int) -> str:
    safe_stem = re.sub(r"[^a-zA-Z0-9_-]+", "-", stem.lower()).strip("-")
    return f"{safe_stem}-p{page_number}-c{chunk_index}"


if __name__ == "__main__":
    main()
