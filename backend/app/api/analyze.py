import logging

from fastapi import APIRouter, UploadFile, File, Depends, HTTPException
from typing import Optional
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.scan import ScanHistory
from app.models.user import UserProfile, User
from app.api.auth import get_current_user_optional
from app.schemas.food_safe import UserHealthProfile
from app.workflows.agent_workflow import FoodSafeAgentWorkflow
import secrets

logger = logging.getLogger(__name__)

router = APIRouter()
workflow = FoodSafeAgentWorkflow()


def _build_compact_result(workflow_result) -> dict:
    extracted = workflow_result.extracted_label
    report = workflow_result.risk_report

    risky_items = [
        {
            "ingredient": item.ingredient,
            "risk_level": item.risk_level,
            "summary": item.summary,
        }
        for item in report.ingredient_assessments
        if item.risk_level in {"moderate", "high"}
    ][:5]

    return {
        "product_name": extracted.product_name,
        "detected_language": extracted.detected_language,
        "ingredient_count": len(extracted.ingredients),
        "ingredients_preview": extracted.ingredients[:12],
        "allergens": extracted.allergens,
        "claims": extracted.claims,
        "overall_risk": report.overall_risk,
        "status": report.status,
        "summary": report.summary,
        "personalized_considerations": report.personalized_considerations,
        "top_risk_ingredients": risky_items,
        "safer_alternatives": [item.model_dump() for item in report.safer_alternatives],
        "scientific_basis": report.scientific_basis[:5],
        "execution_metadata": [item.model_dump() for item in workflow_result.execution_metadata],
    }

@router.post("/")
async def analyze(
    file: UploadFile = File(...),
    session_id: Optional[str] = None,
    verbose: bool = False,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional)
):
    logger.info("Analyze request received. filename=%s content_type=%s", file.filename, file.content_type)
    if file.content_type not in ["image/jpeg", "image/png", "image/webp"]:
        raise HTTPException(status_code=400, detail="Only JPEG/PNG/WEBP accepted")

    # Determine profile context
    profile_data = {"allergies": [], "conditions": [], "special": []}
    
    if current_user:
        profile_db = db.query(UserProfile).filter(UserProfile.user_id == current_user.id).first()
        if profile_db:
            profile_data = {
                "allergies": profile_db.allergies,
                "conditions": profile_db.conditions,
                "special": profile_db.special
            }
    elif session_id:
        profile_db = db.query(UserProfile).filter(UserProfile.session_id == session_id).first()
        if profile_db:
            profile_data = {
                "allergies": profile_db.allergies,
                "conditions": profile_db.conditions,
                "special": profile_db.special
            }

    image_bytes = await file.read()
    logger.info("Analyze request file read complete. bytes=%s", len(image_bytes))
    workflow_result = await workflow.run(
        image_bytes=image_bytes,
        user_profile=UserHealthProfile.model_validate(profile_data),
        mime_type=file.content_type,
    )
    logger.info(
        "Analyze workflow completed. ingredients=%s evidence=%s status=%s",
        len(workflow_result.extracted_label.ingredients),
        len(workflow_result.retrieved_evidence),
        workflow_result.risk_report.status,
    )
    result = workflow_result.model_dump() if verbose else _build_compact_result(workflow_result)

    # Save to history
    share_token = secrets.token_urlsafe(16)
    scan = ScanHistory(
        user_id=current_user.id if current_user else None,
        session_id=session_id if not current_user else None,
        product_name=workflow_result.extracted_label.product_name,
        ingredients_raw=", ".join(workflow_result.extracted_label.ingredients),
        danger_level=workflow_result.risk_report.status,
        analysis_result=result,
        share_token=share_token
    )
    db.add(scan)
    db.commit()
    db.refresh(scan)
    logger.info("Analyze result saved. scan_id=%s share_token=%s", scan.id, share_token)

    return {
        "scan_id": scan.id,
        "share_token": share_token,
        "result": result,
        "verbose": verbose,
    }
