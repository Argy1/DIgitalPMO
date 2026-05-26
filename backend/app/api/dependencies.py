from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from slowapi import Limiter
from slowapi.util import get_remote_address
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import decode_token
from app.models.patient import PatientProfile
from app.models.user import User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")
# Global default: 100 req/min. Individual routes can override with @limiter.limit().
limiter = Limiter(key_func=get_remote_address, default_limits=["100/minute"])


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> User:
    # Lazy import to avoid circular dependency
    from app.services.auth_service import auth_service

    if auth_service.is_blacklisted(token):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token sudah dinonaktifkan. Silakan login kembali.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    payload = decode_token(token)
    user_id: str = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token tidak valid.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Pengguna tidak ditemukan.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Akun pengguna tidak aktif.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user


def get_current_patient(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> PatientProfile:
    profile = (
        db.query(PatientProfile)
        .filter(PatientProfile.user_id == current_user.id)
        .first()
    )
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profil pasien belum dibuat. Silakan lengkapi profil Anda terlebih dahulu.",
        )
    return profile


def require_admin(current_user: User = Depends(get_current_user)) -> User:
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Hanya admin yang dapat mengakses resource ini.",
        )
    return current_user


def require_pmo_or_admin(current_user: User = Depends(get_current_user)) -> User:
    if current_user.role not in ("pmo", "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Akses ditolak. Diperlukan role PMO atau admin.",
        )
    return current_user
