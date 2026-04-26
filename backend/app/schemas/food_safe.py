from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field


class UserHealthProfile(BaseModel):
    allergies: list[str] = Field(default_factory=list)
    conditions: list[str] = Field(default_factory=list)
    special: list[str] = Field(default_factory=list)


class IngredientExtraction(BaseModel):
    product_name: str | None = None
    ingredients: list[str] = Field(default_factory=list)
    claims: list[str] = Field(default_factory=list)
    allergens: list[str] = Field(default_factory=list)
    cross_contamination_warnings: list[str] = Field(default_factory=list)
    detected_language: str | None = None
    raw_text: str | None = None


class ScientificSource(BaseModel):
    title: str
    organization: str
    citation: str
    url: str | None = None


class ToxicologyFinding(BaseModel):
    ingredient: str
    normalized_name: str
    summary: str
    risk_level: Literal["low", "moderate", "high", "unknown"] = "unknown"
    profile_flags: list[str] = Field(default_factory=list)
    evidence: list[str] = Field(default_factory=list)
    sources: list[ScientificSource] = Field(default_factory=list)


class AlternativeProduct(BaseModel):
    name: str
    reason: str
    tags: list[str] = Field(default_factory=list)


class ModelExecutionTrace(BaseModel):
    stage: str
    provider: str = "google-genai"
    preferred_model: str
    actual_model: str
    fallback_model: str | None = None
    fallback_used: bool = False
    success: bool = True
    notes: list[str] = Field(default_factory=list)


class RiskAssessment(BaseModel):
    overall_risk: Literal["low", "moderate", "high"] = "low"
    status: Literal["SAFE", "CAUTION", "HIGH_RISK"] = "SAFE"
    summary: str
    personalized_considerations: list[str] = Field(default_factory=list)
    ingredient_assessments: list[ToxicologyFinding] = Field(default_factory=list)
    safer_alternatives: list[AlternativeProduct] = Field(default_factory=list)
    scientific_basis: list[str] = Field(default_factory=list)
    next_steps: list[str] = Field(default_factory=list)


class WorkflowOutput(BaseModel):
    extracted_label: IngredientExtraction
    retrieved_evidence: list[ToxicologyFinding] = Field(default_factory=list)
    risk_report: RiskAssessment
    execution_metadata: list[ModelExecutionTrace] = Field(default_factory=list)
