from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.scan import ScanHistory

router = APIRouter()

@router.get("/{token}")
async def get_shared_scan(token: str, db: Session = Depends(get_db)):
    scan = db.query(ScanHistory).filter(ScanHistory.share_token == token).first()
    if not scan:
        raise HTTPException(status_code=404, detail="Shared scan not found or link expired")
    
    return {
        "product_name": scan.product_name,
        "danger_level": scan.danger_level,
        "analysis_result": scan.analysis_result,
        "created_at": scan.created_at
    }
