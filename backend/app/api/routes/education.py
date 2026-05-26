import logging
from datetime import datetime

from fastapi import APIRouter, Depends, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.api.dependencies import get_current_patient, get_db
from app.models.education import EducationLog
from app.models.patient import PatientProfile

router = APIRouter(prefix="/api/v1/education", tags=["education"])
logger = logging.getLogger(__name__)

TOTAL_ARTICLES = 13


class ReadRequest(BaseModel):
    content_id: str
    content_category: str | None = None
    trigger_type: str | None = None


class FeedbackRequest(BaseModel):
    content_id: str
    is_helpful: bool


@router.post("/deliver", status_code=status.HTTP_200_OK)
def record_delivery(
    body: ReadRequest,
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    """Record that an article was delivered to the patient (idempotent)."""
    existing = (
        db.query(EducationLog)
        .filter(
            EducationLog.patient_id == current_patient.id,
            EducationLog.content_id == body.content_id,
        )
        .first()
    )
    if existing:
        return {"message": "Artikel sudah pernah dikirim.", "content_id": body.content_id}

    log = EducationLog(
        patient_id=current_patient.id,
        content_id=body.content_id,
        content_category=body.content_category,
        trigger_type=body.trigger_type,
        delivered_at=datetime.utcnow(),
    )
    db.add(log)
    db.commit()
    logger.info("Article %s delivered to patient %s", body.content_id, current_patient.id)
    return {"message": "Pengiriman artikel dicatat.", "content_id": body.content_id}


@router.post("/read", status_code=status.HTTP_200_OK)
def mark_article_read(
    body: ReadRequest,
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    """Mark an article as read. Creates a delivery+read log if one doesn't exist yet."""
    now = datetime.utcnow()
    existing = (
        db.query(EducationLog)
        .filter(
            EducationLog.patient_id == current_patient.id,
            EducationLog.content_id == body.content_id,
        )
        .first()
    )
    if existing:
        if not existing.is_read:
            existing.is_read = True
            existing.read_at = now
            db.commit()
        return {"message": "Artikel ditandai sudah dibaca.", "content_id": body.content_id}

    log = EducationLog(
        patient_id=current_patient.id,
        content_id=body.content_id,
        content_category=body.content_category,
        trigger_type=body.trigger_type,
        delivered_at=now,
        is_read=True,
        read_at=now,
    )
    db.add(log)
    db.commit()
    logger.info("Patient %s read article %s", current_patient.id, body.content_id)
    return {"message": "Artikel ditandai sudah dibaca.", "content_id": body.content_id}


@router.post("/feedback", status_code=status.HTTP_200_OK)
def submit_feedback(
    body: FeedbackRequest,
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    """Record article feedback (currently tracked client-side; endpoint kept for API parity)."""
    logger.info(
        "Patient %s submitted feedback for article %s: helpful=%s",
        current_patient.id, body.content_id, body.is_helpful,
    )
    return {
        "message": "Terima kasih atas feedback Anda!",
        "content_id": body.content_id,
        "is_helpful": body.is_helpful,
    }


@router.get("/read-ids")
def get_read_article_ids(
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    """Get list of content IDs already read by the patient."""
    logs = (
        db.query(EducationLog.content_id)
        .filter(
            EducationLog.patient_id == current_patient.id,
            EducationLog.is_read == True,
        )
        .all()
    )
    return {"content_ids": [r.content_id for r in logs]}


@router.get("/stats")
def get_education_stats(
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    """Get education reading statistics for the patient."""
    total_read = (
        db.query(EducationLog)
        .filter(
            EducationLog.patient_id == current_patient.id,
            EducationLog.is_read == True,
        )
        .count()
    )
    total_delivered = (
        db.query(EducationLog)
        .filter(EducationLog.patient_id == current_patient.id)
        .count()
    )
    return {
        "total_read": total_read,
        "total_delivered": total_delivered,
        "total_articles": TOTAL_ARTICLES,
        "completion_percentage": round((total_read / TOTAL_ARTICLES) * 100, 1),
    }
