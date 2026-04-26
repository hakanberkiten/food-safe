from fastapi import APIRouter, Depends, HTTPException
from typing import Optional, List
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.user import UserProfile, User
from app.api.auth import get_current_user_optional
from pydantic import BaseModel

router = APIRouter()

class ProfileUpdate(BaseModel):
    allergies: List[str]
    conditions: List[str]
    special: List[str]
    session_id: Optional[str] = None

@router.get("/")
async def get_profile(
    session_id: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional)
):
    if current_user:
        profile = db.query(UserProfile).filter(UserProfile.user_id == current_user.id).first()
    elif session_id:
        profile = db.query(UserProfile).filter(UserProfile.session_id == session_id).first()
    else:
        raise HTTPException(status_code=400, detail="User or session_id required")
    
    if not profile:
        return {"allergies": [], "conditions": [], "special": []}
        
    return profile

@router.post("/")
async def update_profile(
    profile_in: ProfileUpdate,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user_optional)
):
    if current_user:
        profile = db.query(UserProfile).filter(UserProfile.user_id == current_user.id).first()
        if not profile:
            profile = UserProfile(user_id=current_user.id)
            db.add(profile)
    elif profile_in.session_id:
        profile = db.query(UserProfile).filter(UserProfile.session_id == profile_in.session_id).first()
        if not profile:
            profile = UserProfile(session_id=profile_in.session_id)
            db.add(profile)
    else:
        raise HTTPException(status_code=400, detail="User or session_id required")

    profile.allergies = profile_in.allergies
    profile.conditions = profile_in.conditions
    profile.special = profile_in.special
    
    db.commit()
    db.refresh(profile)
    return profile
