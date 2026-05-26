import logging
from datetime import datetime
from typing import Any, List, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.api.dependencies import get_current_user, get_db
from app.models.notification import Notification
from app.models.patient import PatientProfile
from app.models.user import User
from app.schemas.notification import (
    NotificationResponse,
    RegisterTokenRequest,
)

router = APIRouter(prefix="/api/v1/notifications", tags=["notifications"])
logger = logging.getLogger(__name__)


def _get_patient(current_user: User, db: Session) -> Optional[PatientProfile]:
    return (
        db.query(PatientProfile)
        .filter(PatientProfile.user_id == current_user.id)
        .first()
    )


# ── POST /register-token ──────────────────────────────────────────────────────

@router.post("/register-token")
def register_fcm_token(
    body: RegisterTokenRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    """Register or update Firebase Cloud Messaging token for push notifications."""
    current_user.fcm_token = body.fcm_token
    db.commit()
    logger.info("FCM token registered for user %s", current_user.id)
    return {"message": "FCM token berhasil didaftarkan."}


# ── GET /history ──────────────────────────────────────────────────────────────

@router.get("/history", response_model=List[NotificationResponse])
def get_notification_history(
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=20, ge=1, le=100),
    type: Optional[str] = Query(default=None, description="Filter by type: medication, control, ai"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> List[NotificationResponse]:
    """List notification history with pagination and optional type filter."""
    patient = _get_patient(current_user, db)
    if not patient:
        return []

    query = db.query(Notification).filter(Notification.patient_id == patient.id)
    if type:
        query = query.filter(Notification.type == type)

    offset = (page - 1) * limit
    notifications = (
        query.order_by(Notification.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )
    return notifications


# ── PUT /{notification_id}/read ───────────────────────────────────────────────

@router.put("/{notification_id}/read")
def mark_notification_read(
    notification_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    """Mark a single notification as read."""
    patient = _get_patient(current_user, db)
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profil pasien tidak ditemukan.",
        )

    notification = (
        db.query(Notification)
        .filter(
            Notification.id == notification_id,
            Notification.patient_id == patient.id,
        )
        .first()
    )
    if not notification:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notifikasi tidak ditemukan.",
        )

    if not notification.is_read:
        notification.is_read = True
        notification.read_at = datetime.utcnow()
        db.commit()

    return {"message": "Notifikasi ditandai sudah dibaca."}


# ── DELETE /read-all ──────────────────────────────────────────────────────────

@router.delete("/read-all")
def mark_all_read(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    """Mark all unread notifications as read."""
    patient = _get_patient(current_user, db)
    if not patient:
        return {"message": "Tidak ada notifikasi yang diubah.", "count": 0}

    now = datetime.utcnow()
    unread = (
        db.query(Notification)
        .filter(
            Notification.patient_id == patient.id,
            Notification.is_read == False,
        )
        .all()
    )
    count = len(unread)
    for notif in unread:
        notif.is_read = True
        notif.read_at = now
    db.commit()
    return {"message": f"Semua {count} notifikasi ditandai sudah dibaca.", "count": count}


# ── GET /unread-count ─────────────────────────────────────────────────────────

@router.get("/unread-count")
def get_unread_count(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    """Return count of unread notifications."""
    patient = _get_patient(current_user, db)
    if not patient:
        return {"count": 0}

    count = (
        db.query(Notification)
        .filter(
            Notification.patient_id == patient.id,
            Notification.is_read == False,
        )
        .count()
    )
    return {"count": count}
