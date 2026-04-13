from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    GEMINI_API_KEY: str = ""
    GEMINI_MODEL: str = "gemma-4"
    DATABASE_URL: str = "sqlite:///./food_safe.db"
    SECRET_KEY: str = "changeme-in-production"

    class Config:
        env_file = ".env"

settings = Settings()