from sqlalchemy import Column, Integer, String, DateTime, JSON, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base

class ScanHistory(Base):
    __tablename__ = "scan_history"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    session_id = Column(String, index=True, nullable=True)
    product_name = Column(String, nullable=True)
    ingredients_raw = Column(String)
    danger_level = Column(String)
    analysis_result = Column(JSON)
    share_token = Column(String, unique=True, index=True, nullable=True)
    created_at = Column(DateTime, default=func.now())

    user = relationship("User", back_populates="scans")