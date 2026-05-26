import logging
from datetime import datetime, timezone
from typing import Optional
from uuid import UUID

from sqlalchemy.orm import Session

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

_OTP_TTL = 300          # 5 minutes
_OTP_PREFIX = "otp:"
_BLACKLIST_PREFIX = "blacklist:"


class AuthService:
    # ── Registration ─────────────────────────────────────────────────────────

    def register(
        self, db: Session, full_name: str, phone_number: str, password: str
    ) -> tuple[User, str]:
        if self.get_user_by_phone(db, phone_number):
            raise ConflictException(detail=f"Nomor {phone_number} sudah terdaftar.")
        user = User(
            full_name=full_name,
            phone_number=phone_number,
            password_hash=hash_password(password),
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        logger.info("User registered: %s (%s)", user.id, phone_number)
        plain_otp = self._store_otp(phone_number)
        return user, plain_otp

    # ── OTP (Redis) ───────────────────────────────────────────────────────────

    def _store_otp(self, phone_number: str) -> str:
        plain_otp = generate_otp()
        redis_client.setex(f"{_OTP_PREFIX}{phone_number}", _OTP_TTL, plain_otp)
        # Dev: OTP printed here. Replace with SMS/WhatsApp gateway in production.
        logger.info("DEV OTP for %s: %s", phone_number, plain_otp)
        return plain_otp

    def resend_otp(self, db: Session, phone_number: str) -> str:
        if not self.get_user_by_phone(db, phone_number):
            raise AuthException(detail="Nomor telepon tidak ditemukan.")
        return self._store_otp(phone_number)

    def verify_otp(self, db: Session, phone_number: str, otp_code: str) -> User:
        stored = redis_client.get(f"{_OTP_PREFIX}{phone_number}")
        if not stored:
            raise AuthException(
                detail="OTP sudah kedaluwarsa atau belum diminta. Silakan request OTP baru."
            )
        if stored != otp_code:
            raise AuthException(detail="OTP tidak valid.")

        user = self.get_user_by_phone(db, phone_number)
        if not user:
            raise AuthException(detail="Pengguna tidak ditemukan.")

        user.is_verified = True
        user.otp_code = None
        user.otp_expires_at = None
        db.commit()
        db.refresh(user)
        redis_client.delete(f"{_OTP_PREFIX}{phone_number}")
        logger.info("OTP verified for user: %s", user.id)
        return user

    # ── Login ─────────────────────────────────────────────────────────────────

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

    # ── Tokens ────────────────────────────────────────────────────────────────

    def create_tokens(self, user: User) -> dict:
        data = {"sub": str(user.id), "phone": user.phone_number, "role": user.role}
        refresh = create_refresh_token(data=data)
        # Store refresh token in Redis for rotation validation
        store_refresh_token(str(user.id), refresh)
        return {
            "access_token": create_access_token(data=data),
            "refresh_token": refresh,
            "token_type": "bearer",
        }

    def rotate_tokens(self, user: User, old_refresh_token: str) -> dict:
        """Validate the stored refresh token, then issue a rotated pair."""
        stored = get_stored_refresh_token(str(user.id))
        if stored != old_refresh_token:
            raise AuthException(
                detail="Token refresh tidak valid atau sudah digunakan. Silakan login kembali."
            )
        return self.create_tokens(user)

    def blacklist_token(self, token: str, expire_seconds: int) -> None:
        redis_client.setex(f"{_BLACKLIST_PREFIX}{token}", max(expire_seconds, 1), "1")

    def is_blacklisted(self, token: str) -> bool:
        return redis_client.exists(f"{_BLACKLIST_PREFIX}{token}") > 0

    def revoke_all_tokens(self, user_id: str) -> None:
        """Revoke the stored refresh token on logout."""
        revoke_refresh_token(user_id)

    # ── Queries ───────────────────────────────────────────────────────────────

    def get_user_by_phone(self, db: Session, phone_number: str) -> Optional[User]:
        return db.query(User).filter(User.phone_number == phone_number).first()

    def get_user_by_id(self, db: Session, user_id: UUID) -> Optional[User]:
        return db.query(User).filter(User.id == user_id).first()


auth_service = AuthService()
