from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql://user:pass@localhost/digitalpmo"

    def get_database_url(self) -> str:
        return self.DATABASE_URL.replace("postgres://", "postgresql://", 1)
    REDIS_URL: str = "redis://localhost:6379"
    SECRET_KEY: str = "your-secret-key-min-32-chars-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440  # 24 jam
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    ANTHROPIC_API_KEY: str = ""
    FIREBASE_CREDENTIALS_PATH: str = "firebase.json"
    R2_ENDPOINT_URL: str = ""
    R2_ACCESS_KEY_ID: str = ""
    R2_SECRET_ACCESS_KEY: str = ""
    R2_BUCKET_NAME: str = "digitalpmo"
    ENVIRONMENT: str = "development"
    # Fernet key for field-level encryption. Generate with:
    #   python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
    ENCRYPTION_KEY: str = ""
    SKIP_OTP: bool = True

    model_config = SettingsConfigDict(env_file=".env", case_sensitive=True)


@lru_cache()
def get_settings() -> Settings:
    return Settings()
