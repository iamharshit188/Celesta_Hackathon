from pydantic_settings import BaseSettings
from typing import List
import os

class Settings(BaseSettings):
    # Server configuration
    HOST: str = "127.0.0.1"
    PORT: int = 8000
    DEBUG: bool = True
    
    # CORS settings
    ALLOWED_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:8080",
        "http://127.0.0.1:8080",
    ]
    
    # API Keys (set via environment variables)
    OPENAI_API_KEY: str = ""
    HUGGINGFACE_API_KEY: str = ""
    GOOGLE_SEARCH_API_KEY: str = ""
    GOOGLE_SEARCH_ENGINE_ID: str = ""
    GROQ_API_KEY: str = ""
    GEMINI_API_KEY: str = ""
    
    # Model configurations
    TEXT_MODEL_NAME: str = "unitary/toxic-bert"
    FAKE_NEWS_MODEL_NAME: str = "hamzab/roberta-fake-news-classification"
    
    # File upload limits
    MAX_FILE_SIZE: int = 50 * 1024 * 1024  # 50MB
    ALLOWED_VIDEO_FORMATS: str = ".mp4,.avi,.mov,.mkv"
    
    # Model cache directory
    MODEL_CACHE_DIR: str = "./models"
    
    # Logging
    LOG_LEVEL: str = "INFO"
    LOG_FILE: str = "app.log"
    
    # External services
    NEWS_API_KEY: str = ""
    PERPLEXITY_API_KEY: str = ""
    
    # Processing limits
    MAX_TEXT_LENGTH: int = 5000
    MAX_PROCESSING_TIME: int = 300  # 5 minutes
    
    # Confidence thresholds
    HIGH_CONFIDENCE_THRESHOLD: float = 0.8
    LOW_CONFIDENCE_THRESHOLD: float = 0.3

    @property
    def ALLOWED_VIDEO_FORMATS_LIST(self) -> List[str]:
        """Convert comma-separated string to list."""
        return [fmt.strip() for fmt in self.ALLOWED_VIDEO_FORMATS.split(",") if fmt.strip()]

    class Config:
        env_file = ".env"
        case_sensitive = True

# Create global settings instance
settings = Settings()

# Ensure model cache directory exists
os.makedirs(settings.MODEL_CACHE_DIR, exist_ok=True)
