import logging
from datetime import datetime, timedelta
from typing import Optional
from uuid import UUID

from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.exceptions import AuthException, ConflictException
from app.core.redis_client import redis_client
from app.core.security import (
    create_access_token,
    create_refresh_token,
    generate_otp,
    get_stored_refresh_token,
    hash_password,
    revoke_refresh_token,
    store_refresh_token,
    verify_password,
)
from app.models.user import User

logger = logging.getLogger(__name__)

_OTP_TTL = 300
_OTP_PREFIX = "otp:"
_BLACKLIST_PREFIX = "blacklist:"


class AuthService:
    def register(
        self, db: Session, full_name: str, phone_number: str, password: str
    ) -> tuple[User, str | None]:
        existing_user = self.get_user_by_phone(db, phone_number)
        if existing_user and existing_user.is_verified:
            raise ConflictException(detail=f"Nomor {phone_number} sudah terdaftar.")

        if existing_user:
            user = existing_user
            user.full_name = full_name
            user.password_hash = hash_password(password)
            logger.info("Restarting incomplete registration for %s", phone_number)
        else:
            user = User(
                full_name=full_name,
                phone_number=phone_number,
                password_hash=hash_password(password),
            )
            db.add(user)

        if get_settings().SKIP_OTP:
            user.is_verified = True
            db.commit()
            db.refresh(user)
            logger.info("User registered (OTP skipped): %s (%s)", user.id, phone_number)
            return user, None

        plain_otp = self._assign_otp(user)
        db.commit()
        db.refresh(user)
        logger.info("User registered: %s (%s)", user.id, phone_number)
        self._cache_otp(phone_number, plain_otp)
        return user, plain_otp

    # OTP remains usable without Redis because PostgreSQL is the durable store.
    def _assign_otp(self, user: User) -> str:
        plain_otp = generate_otp()
        user.otp_code = plain_otp
        user.otp_expires_at = datetime.utcnow() + timedelta(seconds=_OTP_TTL)
        return plain_otp

    def _cache_otp(self, phone_number: str, plain_otp: str) -> None:
        try:
            redis_client.setex(f"{_OTP_PREFIX}{phone_number}", _OTP_TTL, plain_otp)
        except Exception as exc:
            logger.warning("Redis unavailable while caching OTP: %s", exc)
        # Replace this development response/log flow with an SMS gateway in production.
        logger.info("DEV OTP for %s: %s", phone_number, plain_otp)

    def resend_otp(self, db: Session, phone_number: str) -> str:
        user = self.get_user_by_phone(db, phone_number)
        if not user:
            raise AuthException(detail="Nomor telepon tidak ditemukan.")
        plain_otp = self._assign_otp(user)
        db.commit()
        self._cache_otp(phone_number, plain_otp)
        return plain_otp

    def verify_otp(self, db: Session, phone_number: str, otp_code: str) -> User:
        user = self.get_user_by_phone(db, phone_number)
        if not user:
            raise AuthException(detail="Pengguna tidak ditemukan.")

        try:
            stored = redis_client.get(f"{_OTP_PREFIX}{phone_number}")
        except Exception as exc:
            logger.warning("Redis unavailable while reading OTP: %s", exc)
            stored = None

        if (
            not stored
            and user.otp_code
            and user.otp_expires_at
            and user.otp_expires_at > datetime.utcnow()
        ):
            stored = user.otp_code

        if not stored:
            raise AuthException(
                detail="OTP sudah kedaluwarsa atau belum diminta. Silakan request OTP baru."
            )
        if stored != otp_code:
            raise AuthException(detail="OTP tidak valid.")

        user.is_verified = True
        user.otp_code = None
        user.otp_expires_at = None
        db.commit()
        db.refresh(user)
        try:
            redis_client.delete(f"{_OTP_PREFIX}{phone_number}")
        except Exception as exc:
            logger.warning("Redis unavailable while clearing OTP: %s", exc)
        logger.info("OTP verified for user: %s", user.id)
        return user

    def authenticate_user(
        self,
        db: Session,
        phone_number: str,
        password: str,
        fcm_token: Optional[str] = None,
    ) -> Optional[User]:
        user = self.get_user_by_phone(db, phone_number)
        if not user or not user.is_active:
            return None
        if not user.password_hash or not verify_password(password, user.password_hash):
            return None
        if fcm_token and user.fcm_token != fcm_token:
            user.fcm_token = fcm_token
            db.commit()
        return user

    def create_tokens(self, user: User) -> dict:
        data = {"sub": str(user.id), "phone": user.phone_number, "role": user.role}
        refresh = create_refresh_token(data=data)
        try:
            store_refresh_token(str(user.id), refresh)
        except Exception as exc:
            logger.warning("Redis unavailable while storing refresh token: %s", exc)
        return {
            "access_token": create_access_token(data=data),
            "refresh_token": refresh,
            "token_type": "bearer",
        }

    def rotate_tokens(self, user: User, old_refresh_token: str) -> dict:
        """Validate a refresh token using Redis when it is available."""
        try:
            stored = get_stored_refresh_token(str(user.id))
        except Exception as exc:
            logger.warning("Redis unavailable during token rotation: %s", exc)
            stored = old_refresh_token
        if stored != old_refresh_token:
            raise AuthException(
                detail="Token refresh tidak valid atau sudah digunakan. Silakan login kembali."
            )
        return self.create_tokens(user)

    def blacklist_token(self, token: str, expire_seconds: int) -> None:
        try:
            redis_client.setex(f"{_BLACKLIST_PREFIX}{token}", max(expire_seconds, 1), "1")
        except Exception as exc:
            logger.warning("Redis unavailable while blacklisting token: %s", exc)

    def is_blacklisted(self, token: str) -> bool:
        try:
            return redis_client.exists(f"{_BLACKLIST_PREFIX}{token}") > 0
        except Exception as exc:
            logger.warning("Redis unavailable while reading blacklist: %s", exc)
            return False

    def revoke_all_tokens(self, user_id: str) -> None:
        """Revoke the stored refresh token on logout when Redis is available."""
        try:
            revoke_refresh_token(user_id)
        except Exception as exc:
            logger.warning("Redis unavailable while revoking refresh token: %s", exc)

    def get_user_by_phone(self, db: Session, phone_number: str) -> Optional[User]:
        return db.query(User).filter(User.phone_number == phone_number).first()

    def get_user_by_id(self, db: Session, user_id: UUID) -> Optional[User]:
        return db.query(User).filter(User.id == user_id).first()


auth_service = AuthService()
