import logging
from pathlib import Path

from pydantic_settings import BaseSettings

BASE_DIR = Path(__file__).resolve().parents[2]
ENV_FILE = BASE_DIR / ".env"
logger = logging.getLogger(__name__)


class Settings(BaseSettings):
    GEMINI_API_KEY: str = ""
    VISION_MODEL: str = "gemma-4-31b-it"
    VISION_FALLBACK_MODEL: str = "gemini-2.5-flash"
    REASONING_MODEL: str = "gemma-4-31b-it"
    REASONING_FALLBACK_MODEL: str = "gemini-2.5-flash"
    GEMMA_VISION_MODEL: str = ""
    GEMMA_REASONING_MODEL: str = ""
    DATABASE_URL: str = f"sqlite:///{BASE_DIR / 'food_safe.db'}"
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
        env_file = ENV_FILE
        env_file_encoding = "utf-8"


if not ENV_FILE.exists():
    logger.warning(
        "Environment file not found at %s. Falling back to default settings where applicable.",
        ENV_FILE,
    )

settings = Settings()
