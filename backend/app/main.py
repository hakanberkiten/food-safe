from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import profile, analyze, auth, history, shared
from app.core.database import init_db

app = FastAPI(
    title="Gemma 4 Food-Safe AI API",
    version="2.0.0",
    description="Vision-to-Query workflow for multimodal ingredient extraction, toxicology RAG, and personalized food safety reasoning.",
)

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


@app.on_event("startup")
def startup():
    init_db()

@app.get("/")
async def root():
    return {"message": "Gemma 4 Food-Safe AI API is running"}
