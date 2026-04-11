from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.scan import ScanHistory
from app.models.saved_product import SavedProduct
from app.models.user import User
from app.api.auth import get_current_user
from pydantic import BaseModel
from typing import List

router = APIRouter()

class SavedProductCreate(BaseModel):
    scan_id: int

@router.get("/scans")
async def get_scan_history(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    scans = db.query(ScanHistory).filter(ScanHistory.user_id == current_user.id).order_by(ScanHistory.created_at.desc()).all()
    return scans

@router.get("/saved-products")
async def get_saved_products(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    products = db.query(SavedProduct).filter(SavedProduct.user_id == current_user.id).all()
    return products

@router.post("/save-product")
async def save_product(
    data: SavedProductCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    scan = db.query(ScanHistory).filter(ScanHistory.id == data.scan_id, ScanHistory.user_id == current_user.id).first()
    if not scan:
        raise HTTPException(status_code=404, detail="Scan not found")
    
    # Check if already saved
    existing = db.query(SavedProduct).filter(
        SavedProduct.user_id == current_user.id, 
        SavedProduct.product_name == scan.product_name
    ).first()
    if existing:
        return {"message": "Product already in saved list"}

    saved = SavedProduct(
        user_id=current_user.id,
        product_name=scan.product_name,
        danger_level=scan.danger_level,
        analysis_result=scan.analysis_result
    )
    db.add(saved)
    db.commit()
    return {"message": "Product saved to safe list"}