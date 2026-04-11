from fastapi import APIRouter, UploadFile, File, Depends, HTTPException
from typing import Optional
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.scan import ScanHistory
from app.models.user import UserProfile, User
from app.services.gemma_service import analyze_label
from app.api.auth import get_current_user
import uuid
import secrets

router = APIRouter()

@router.post("/")
async def analyze(
    file: UploadFile = File(...),
    session_id: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user)
):
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
    result = await analyze_label(image_bytes, profile_data)

    # Save to history
    share_token = secrets.token_urlsafe(16)
    scan = ScanHistory(
        user_id=current_user.id if current_user else None,
        session_id=session_id if not current_user else None,
        product_name=result.get("product_name"),
        ingredients_raw=", ".join(result.get("ingredients", [])),
        danger_level=result.get("overall_safety", {}).get("status", "unknown"),
        analysis_result=result,
        share_token=share_token
    )
    db.add(scan)
    db.commit()
    db.refresh(scan)

    return {
        "scan_id": scan.id,
        "share_token": share_token,
        "result": result
    }