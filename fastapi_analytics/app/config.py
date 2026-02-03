from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application configuration"""
    DATABASE_ANALYTICS_URL: str
    APP_NAME: str = "HypeHere Analytics API"
    VERSION: str = "1.0.0"
    DESCRIPTION: str = "Read-only analytics API for HypeHere mobile app"

    class Config:
        env_file = ".env"


settings = Settings()
