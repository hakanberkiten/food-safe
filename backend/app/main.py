from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import profile, analyze, auth, history, shared
from app.core.database import engine, Base
from app.models import user, scan, saved_product # Ensure models are loaded for DDL

# Create tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Food-Safe API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/auth", tags=["Auth"])
app.include_router(profile.router, prefix="/api/profile", tags=["Profile"])
app.include_router(analyze.router, prefix="/api/analyze", tags=["Analyze"])
app.include_router(history.router, prefix="/api/history", tags=["History"])
app.include_router(shared.router, prefix="/api/shared", tags=["Sharing"])

@app.get("/")
async def root():
    return {"message": "Food-Safe API is running"}