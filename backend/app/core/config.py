from pathlib import Path

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    GEMINI_API_KEY: str = ""
    VISION_MODEL: str = "gemma-4-31b-it"
    VISION_FALLBACK_MODEL: str = "gemini-2.5-flash"
    REASONING_MODEL: str = "gemma-4-31b-it"
    REASONING_FALLBACK_MODEL: str = "gemini-2.5-flash"
    GEMMA_VISION_MODEL: str = ""
    GEMMA_REASONING_MODEL: str = ""
    DATABASE_URL: str = (
        "postgresql://postgres.[USER]:[PASSWORD]"
        "@aws-0-[REGION].pooler.supabase.com:6543/postgres"
    )
    SECRET_KEY: str = "changeme-in-production"
    KNOWLEDGE_BASE_PATH: str = "knowledge/ecodes.json"
    CHROMA_USE_CLOUD: bool = False
    CHROMA_API_KEY: str = ""
    CHROMA_TENANT: str = ""
    CHROMA_DATABASE: str = ""
    CHROMA_COLLECTION: str = "food-safe-toxicology"
    CHROMA_TOP_K: int = 3
    CHROMA_PERSIST_DIRECTORY: str = "knowledge/chroma"
    MARKET_API_BASE_URL: str = ""

    class Config:
        env_file = Path(__file__).resolve().parents[2] / ".env"
        env_file_encoding = "utf-8"

settings = Settings()
