from sqlalchemy import Column, Integer, String, JSON, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    full_name = Column(String, nullable=True)
    
    profile = relationship("UserProfile", back_populates="user", uselist=False)
    scans = relationship("ScanHistory", back_populates="user")
    saved_products = relationship("SavedProduct", back_populates="user")

class UserProfile(Base):
    __tablename__ = "user_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    session_id = Column(String, unique=True, index=True, nullable=True)
    allergies = Column(JSON, default=[])
    conditions = Column(JSON, default=[])
    special = Column(JSON, default=[])
    
    user = relationship("User", back_populates="profile")