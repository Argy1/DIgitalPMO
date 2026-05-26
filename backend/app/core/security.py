import logging
import random
import string
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import HTTPException, status
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy import Text
from sqlalchemy.types import TypeDecorator

from app.core.config import get_settings

settings = get_settings()
logger = logging.getLogger(__name__)

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# ── Fernet field-level encryption ─────────────────────────────────────────────

_fernet_instance = None


def _get_fernet():
    global _fernet_instance
    if _fernet_instance is not None:
        return _fernet_instance
    key = get_settings().ENCRYPTION_KEY
    if not key:
        return None
    try:
        from cryptography.fernet import Fernet
        _fernet_instance = Fernet(key.encode() if isinstance(key, str) else key)
        return _fernet_instance
    except Exception as exc:
        logger.error("Invalid ENCRYPTION_KEY — field encryption disabled: %s", exc)
        return None


class EncryptedString(TypeDecorator):
    """
    SQLAlchemy TypeDecorator that transparently encrypts/decrypts a text column
    using Fernet symmetric encryption. Degrades gracefully to plaintext when
    ENCRYPTION_KEY is not configured (dev mode).
    """
    impl = Text
    cache_ok = True

    def process_bind_param(self, value, dialect):
        if value is None:
            return None
        fernet = _get_fernet()
        if fernet is None:
            return value
        return fernet.encrypt(value.encode()).decode()

    def process_result_value(self, value, dialect):
        if value is None:
            return None
        fernet = _get_fernet()
        if fernet is None:
            return value
        try:
            return fernet.decrypt(value.encode()).decode()
        except Exception:
            # Pre-encryption era plaintext value — return as-is
            return value


# ── Password hashing ──────────────────────────────────────────────────────────

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


# ── JWT ────────────────────────────────────────────────────────────────────────

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + (
        expires_delta or timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    to_encode.update({"exp": expire, "type": "access"})
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def create_refresh_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire, "type": "refresh"})
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def decode_token(token: str) -> dict:
    try:
        return jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token tidak valid atau sudah kedaluwarsa",
            headers={"WWW-Authenticate": "Bearer"},
        )


# ── Refresh token rotation (Redis) ────────────────────────────────────────────

_RT_PREFIX = "rt:"
_RT_TTL = int(timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS).total_seconds())


def store_refresh_token(user_id: str, token: str) -> None:
    from app.core.redis_client import redis_client
    redis_client.setex(f"{_RT_PREFIX}{user_id}", _RT_TTL, token)


def get_stored_refresh_token(user_id: str) -> Optional[str]:
    from app.core.redis_client import redis_client
    return redis_client.get(f"{_RT_PREFIX}{user_id}")


def revoke_refresh_token(user_id: str) -> None:
    from app.core.redis_client import redis_client
    redis_client.delete(f"{_RT_PREFIX}{user_id}")


# ── OTP ────────────────────────────────────────────────────────────────────────

def generate_otp() -> str:
    return "".join(random.choices(string.digits, k=6))
