import logging
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.api.dependencies import get_current_user, get_db, limiter
from app.core.config import get_settings
from app.core.security import decode_token
from app.models.audit_log import AuditLog
from app.models.user import User
from app.schemas.auth import (
    ChangePasswordRequest,
    LoginRequest,
    OTPVerify,
    RefreshRequest,
    RegisterRequest,
    RegisterResponse,
    TokenResponse,
    UpdateUserRequest,
)
from app.schemas.common import MessageResponse
from app.schemas.user import UserResponse
from app.core.security import hash_password, verify_password
from app.services.auth_service import auth_service

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])
logger = logging.getLogger(__name__)


def _mask_phone(phone: str) -> str:
    if len(phone) <= 6:
        return "*" * len(phone)
    return phone[:3] + "*" * (len(phone) - 6) + phone[-3:]


def _audit(
    db: Session,
    action: str,
    user_id=None,
    entity_id=None,
    ip: str = None,
) -> None:
    db.add(
        AuditLog(
            user_id=user_id,
            action=action,
            entity_type="user",
            entity_id=str(entity_id) if entity_id else None,
            ip_address=ip,
        )
    )


def _client_ip(request: Request) -> str:
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else None


# ── Register ──────────────────────────────────────────────────────────────────

@router.post(
    "/register",
    response_model=RegisterResponse,
    status_code=status.HTTP_201_CREATED,
)
@limiter.limit("5/minute")
def register(
    request: Request,
    body: RegisterRequest,
    db: Session = Depends(get_db),
):
    """Register new user account and send OTP for verification."""
    user, _otp = auth_service.register(
        db, body.name, body.phone, body.password, body.role
    )
    _audit(db, "auth.register", user_id=user.id, entity_id=user.id, ip=_client_ip(request))
    db.commit()
    skip = get_settings().SKIP_OTP
    return RegisterResponse(
        message="Registrasi berhasil." if skip else "Registrasi berhasil. Kode OTP telah dikirim ke nomor Anda.",
        phone_masked=_mask_phone(body.phone),
        dev_otp=_otp,
        skip_otp=skip,
        role=user.role,
    )


# ── Verify OTP ────────────────────────────────────────────────────────────────

@router.post("/verify-otp", response_model=TokenResponse)
@limiter.limit("10/minute")
def verify_otp(
    request: Request,
    body: OTPVerify,
    db: Session = Depends(get_db),
):
    """Verify OTP and return auth tokens."""
    user = auth_service.verify_otp(db, body.phone, body.otp)
    tokens = auth_service.create_tokens(user)
    _audit(db, "auth.verify_otp", user_id=user.id, entity_id=user.id, ip=_client_ip(request))
    db.commit()
    return TokenResponse(**tokens, user=UserResponse.model_validate(user))


# ── Login ─────────────────────────────────────────────────────────────────────

@router.post("/login", response_model=TokenResponse)
@limiter.limit("5/minute")
def login(
    request: Request,
    body: LoginRequest,
    db: Session = Depends(get_db),
):
    """Login with phone number and password."""
    user = auth_service.authenticate_user(db, body.phone, body.password, body.fcm_token)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Nomor telepon atau password salah.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not user.is_verified:
        if not get_settings().SKIP_OTP:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Akun belum diverifikasi. Silakan verifikasi OTP terlebih dahulu.",
            )
        user.is_verified = True
        db.commit()
    tokens = auth_service.create_tokens(user)
    _audit(db, "auth.login", user_id=user.id, entity_id=user.id, ip=_client_ip(request))
    db.commit()
    return TokenResponse(**tokens, user=UserResponse.model_validate(user))


# ── Refresh Token ─────────────────────────────────────────────────────────────

@router.post("/refresh-token", response_model=TokenResponse)
def refresh_token(
    body: RefreshRequest,
    db: Session = Depends(get_db),
):
    """Issue a new token pair from a valid refresh token."""
    payload = decode_token(body.refresh_token)
    if payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token refresh tidak valid.",
        )
    if auth_service.is_blacklisted(body.refresh_token):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token sudah dinonaktifkan. Silakan login kembali.",
        )
    user = db.query(User).filter(User.id == payload.get("sub")).first()
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Pengguna tidak ditemukan atau tidak aktif.",
        )
    # Blacklist old refresh token and issue rotated pair
    exp = payload.get("exp", 0)
    ttl = max(int(exp - datetime.now(timezone.utc).timestamp()), 1)
    auth_service.blacklist_token(body.refresh_token, ttl)
    tokens = auth_service.rotate_tokens(user, body.refresh_token)
    return TokenResponse(**tokens, user=UserResponse.model_validate(user))


# ── Logout ────────────────────────────────────────────────────────────────────

@router.post("/logout", response_model=MessageResponse)
def logout(
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Blacklist the current access token and clear FCM token."""
    auth_header = request.headers.get("Authorization", "")
    token = auth_header.removeprefix("Bearer ").strip()
    if token:
        try:
            payload = decode_token(token)
            exp = payload.get("exp", 0)
            ttl = max(int(exp - datetime.now(timezone.utc).timestamp()), 1)
            auth_service.blacklist_token(token, ttl)
        except Exception:
            pass  # already invalid — proceed

    current_user.fcm_token = None
    auth_service.revoke_all_tokens(str(current_user.id))
    _audit(db, "auth.logout", user_id=current_user.id, entity_id=current_user.id, ip=_client_ip(request))
    db.commit()
    logger.info("User %s logged out.", current_user.id)
    return MessageResponse(message="Berhasil logout.")


# ── Me ────────────────────────────────────────────────────────────────────────

@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    """Get current authenticated user info."""
    return current_user


# ── Update user ───────────────────────────────────────────────────────────────

@router.patch("/me", response_model=UserResponse)
def update_me(
    body: UpdateUserRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update basic user fields: full_name, email."""
    updates = body.model_dump(exclude_unset=True)
    for field, value in updates.items():
        setattr(current_user, field, value)
    db.commit()
    db.refresh(current_user)
    logger.info("User %s updated profile fields: %s", current_user.id, list(updates.keys()))
    return current_user


# ── Change password ───────────────────────────────────────────────────────────

@router.post("/change-password", response_model=MessageResponse)
@limiter.limit("5/minute")
def change_password(
    request: Request,
    body: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Change the currently authenticated user's password."""
    if not verify_password(body.current_password, current_user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password saat ini tidak sesuai.",
        )
    current_user.password_hash = hash_password(body.new_password)
    _audit(
        db,
        "auth.change_password",
        user_id=current_user.id,
        entity_id=current_user.id,
        ip=_client_ip(request),
    )
    db.commit()
    logger.info("User %s changed password successfully.", current_user.id)
    return MessageResponse(message="Password berhasil diubah.")
