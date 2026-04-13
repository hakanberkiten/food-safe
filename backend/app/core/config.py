from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    GEMINI_API_KEY: str = ""
    GEMINI_MODEL: str = "gemma-4-31b-it"
    DATABASE_URL: str = "sqlite:///./food_safe.db"
    SECRET_KEY: str = "changeme-in-production"

    model_config = {
        "env_file": ".env",
        "extra": "ignore",
        "case_sensitive": False
    }

settings = Settings()