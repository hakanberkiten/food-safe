from __future__ import annotations

import json
import logging
from pathlib import Path
from typing import Any

import chromadb

from app.core.config import settings
from app.schemas.food_safe import ScientificSource, ToxicologyFinding

logger = logging.getLogger(__name__)


class ToxicologyRAGService:
    def __init__(
        self,
        knowledge_base_path: str | Path | None = None,
        persist_directory: str | Path | None = None,
    ) -> None:
        backend_root = Path(__file__).resolve().parents[2]
        self.knowledge_base_path = self._resolve_path(
            backend_root=backend_root,
            raw_path=knowledge_base_path or settings.KNOWLEDGE_BASE_PATH,
        )
        self.persist_directory = self._resolve_path(
            backend_root=backend_root,
            raw_path=persist_directory or settings.CHROMA_PERSIST_DIRECTORY,
        )
        self.collection_name = settings.CHROMA_COLLECTION
        self.top_k = settings.CHROMA_TOP_K
        self.use_cloud = settings.CHROMA_USE_CLOUD
        self._collection = None

    def retrieve(self, ingredients: list[str]) -> list[ToxicologyFinding]:
        if not ingredients:
            return []

        knowledge = self._load_seed_knowledge()
        collection = self._get_collection()

        findings: list[ToxicologyFinding] = []
        for ingredient in ingredients:
            vector_finding = self._query_vector_store(ingredient, collection)
            if vector_finding:
                findings.append(vector_finding)
                continue

            record = self._match_ingredient(ingredient, knowledge)
            if record:
                findings.append(self._build_seed_finding(ingredient, record))
                continue

            findings.append(
                ToxicologyFinding(
                    ingredient=ingredient,
                    normalized_name=ingredient.lower().strip(),
                    summary="No curated toxicology record matched this ingredient yet.",
                    risk_level="unknown",
                    evidence=[
                        "Chroma query returned no matching reference chunks.",
                        "Fallback knowledge base also had no direct match for this ingredient.",
                    ],
                    sources=[],
                )
            )

        return findings

    def _load_seed_knowledge(self) -> list[dict[str, Any]]:
        if not self.knowledge_base_path.exists():
            return []

        with self.knowledge_base_path.open("r", encoding="utf-8") as file:
            return json.load(file)

    def _match_ingredient(
        self, ingredient: str, knowledge: list[dict[str, Any]]
    ) -> dict[str, Any] | None:
        normalized_ingredient = ingredient.lower().strip()
        for record in knowledge:
            code = str(record.get("code", "")).lower()
            name = str(record.get("name", "")).lower()
            if code and code in normalized_ingredient:
                return record
            if name and name in normalized_ingredient:
                return record
        return None

    def _build_seed_finding(self, ingredient: str, record: dict[str, Any]) -> ToxicologyFinding:
        source_name = record.get("source", "Scientific reference")
        description = record.get("description", "No description provided.")
        risks = record.get("risks", [])

        evidence = [description]
        evidence.extend(f"Potential risk: {risk}" for risk in risks)

        return ToxicologyFinding(
            ingredient=ingredient,
            normalized_name=str(record.get("name", ingredient)).lower(),
            summary=description,
            risk_level=self._infer_risk_level(risks),
            evidence=evidence,
            sources=[
                ScientificSource(
                    title=source_name,
                    organization=self._infer_organization(source_name),
                    citation=description,
                )
            ],
        )

    def _infer_risk_level(self, risks: list[str]) -> str:
        if not risks:
            return "low"
        if len(risks) >= 3:
            return "high"
        if len(risks) == 2:
            return "moderate"
        return "low"

    def _infer_organization(self, source_name: str) -> str:
        lowered = source_name.lower()
        if "fda" in lowered:
            return "FDA"
        if "who" in lowered or "iarc" in lowered or "ipcs" in lowered:
            return "WHO"
        return "Scientific literature"

    def _get_collection(self):
        if self._collection is not None:
            return self._collection

        try:
            if self.use_cloud and settings.CHROMA_API_KEY and settings.CHROMA_TENANT and settings.CHROMA_DATABASE:
                client = chromadb.CloudClient(
                    api_key=settings.CHROMA_API_KEY,
                    tenant=settings.CHROMA_TENANT,
                    database=settings.CHROMA_DATABASE,
                )
            else:
                self.persist_directory.mkdir(parents=True, exist_ok=True)
                client = chromadb.PersistentClient(path=str(self.persist_directory))

            self._collection = client.get_or_create_collection(name=self.collection_name)
            return self._collection
        except Exception as error:
            logger.warning(
                "Chroma collection initialization failed; RAG will use fallback knowledge only.",
                exc_info=error,
            )
            self._collection = False
            return None

    def _query_vector_store(self, ingredient: str, collection) -> ToxicologyFinding | None:
        if not collection:
            return None

        try:
            result = collection.query(
                query_texts=[f"food additive toxicology safety evidence for {ingredient}"],
                n_results=self.top_k,
                include=["documents", "metadatas", "distances"],
            )
        except Exception as error:
            logger.warning(
                "Chroma query failed for ingredient '%s'; using fallback knowledge.",
                ingredient,
                exc_info=error,
            )
            return None

        documents = (result.get("documents") or [[]])[0]
        metadatas = (result.get("metadatas") or [[]])[0]

        if not documents:
            return None

        evidence = []
        sources: list[ScientificSource] = []
        joined_text_parts: list[str] = []
        for index, document in enumerate(documents):
            metadata = metadatas[index] if index < len(metadatas) and metadatas[index] else {}
            source_file = metadata.get("source_file", "reference document")
            page_number = metadata.get("page_number")
            page_label = f"page {page_number}" if page_number is not None else "page unknown"
            excerpt = self._summarize_document(document)
            evidence.append(f"{source_file} ({page_label}): {excerpt}")
            joined_text_parts.append(document)
            sources.append(
                ScientificSource(
                    title=str(source_file),
                    organization=self._infer_organization(str(source_file)),
                    citation=excerpt,
                )
            )

        joined_text = " ".join(joined_text_parts)
        risk_level = self._infer_risk_from_text(joined_text)
        summary = self._summarize_document(documents[0])

        return ToxicologyFinding(
            ingredient=ingredient,
            normalized_name=ingredient.lower().strip(),
            summary=summary,
            risk_level=risk_level,
            evidence=evidence,
            sources=self._dedupe_sources(sources),
        )

    def _summarize_document(self, document: str, max_chars: int = 320) -> str:
        text = " ".join(document.split())
        if len(text) <= max_chars:
            return text
        return f"{text[: max_chars - 3]}..."

    def _infer_risk_from_text(self, text: str) -> str:
        lowered = text.lower()
        high_keywords = [
            "carcinogenic",
            "carcinogen",
            "genotoxic",
            "avoid",
            "contraindicated",
            "not recommended",
            "methemoglobinemia",
            "severe allergic",
        ]
        moderate_keywords = [
            "caution",
            "sensitivity",
            "allergic",
            "migraine",
            "hyperactivity",
            "adverse",
            "limit intake",
            "warning",
        ]
        if any(keyword in lowered for keyword in high_keywords):
            return "high"
        if any(keyword in lowered for keyword in moderate_keywords):
            return "moderate"
        return "low"

    def _dedupe_sources(self, sources: list[ScientificSource]) -> list[ScientificSource]:
        seen: set[tuple[str, str]] = set()
        deduped: list[ScientificSource] = []
        for source in sources:
            key = (source.title, source.citation)
            if key in seen:
                continue
            seen.add(key)
            deduped.append(source)
        return deduped

    def _resolve_path(self, backend_root: Path, raw_path: str | Path) -> Path:
        candidate = Path(raw_path)
        if candidate.is_absolute():
            return candidate
        return backend_root / candidate
