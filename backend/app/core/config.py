from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    # Database
    DATABASE_URL: str
    REDIS_URL: str = "redis://localhost:6379"
    
    # JWT
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Telegram - Multiple Bots
    TELEGRAM_REPORT_BOT_TOKEN: str = ""
    TELEGRAM_REPORT_CHAT_ID: str = ""
    TELEGRAM_SUPPORT_BOT_TOKEN: str = ""
    TELEGRAM_SUPPORT_CHAT_ID: str = ""
    TELEGRAM_STORAGE_BOT_TOKEN: str = ""
    TELEGRAM_STORAGE_CHAT_ID: str = ""
    
    # App
    DEBUG: bool = False
    CORS_ORIGINS: List[str] = ["*"]
    MAX_UPLOAD_SIZE: int = 10485760  # 10MB
    ALLOWED_IMAGE_TYPES: List[str] = ["image/jpeg", "image/png", "image/webp"]
    
    # Geolocation
    MAX_DISTANCE_KM: float = 50.0
    DEFAULT_LATITUDE: float = 28.6139
    DEFAULT_LONGITUDE: float = 77.2090
    
    # Rate Limiting
    RATE_LIMIT_PER_MINUTE: int = 60
    SWIPE_LIMIT_PER_DAY: int = 100
    
    # Email (Optional)
    SMTP_HOST: str = ""
    SMTP_PORT: int = 587
    SMTP_USER: str = ""
    SMTP_PASSWORD: str = ""
    
    # Push Notifications (Optional)
    FCM_SERVER_KEY: str = ""

    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()