from app.services.rag import ToxicologyRAGService

rag_service = ToxicologyRAGService()


def search_toxicology_evidence(ingredients: list[str]) -> list[dict]:
    return [finding.model_dump() for finding in rag_service.retrieve(ingredients)]


def get_rag_context(ingredients: list[str]) -> str:
    findings = rag_service.retrieve(ingredients)
    if not findings:
        return "No specific literature source found for these ingredients."

    lines = ["Relevant scientific data found:"]
    for finding in findings:
        source_names = ", ".join(source.title for source in finding.sources) or "No source yet"
        lines.append(
            f"- {finding.ingredient}: {finding.summary} Risk: {finding.risk_level}. Source: {source_names}"
        )
    return "\n".join(lines)
