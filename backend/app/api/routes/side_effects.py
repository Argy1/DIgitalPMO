from datetime import datetime, timedelta
from typing import List

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.api.dependencies import get_current_patient, get_db
from app.models.patient import PatientProfile
from app.models.side_effect import SideEffectLog
from app.schemas.side_effect import SideEffectLogCreate, SideEffectLogResponse

router = APIRouter(prefix="/api/v1/side-effects", tags=["side-effects"])

_VALID_SEVERITIES = {"ringan", "sedang", "berat"}


@router.post(
    "/log",
    response_model=SideEffectLogResponse,
    status_code=status.HTTP_201_CREATED,
)
def log_side_effect(
    body: SideEffectLogCreate,
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    """Log medication side effects reported by the current patient."""
    if body.severity not in _VALID_SEVERITIES:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Severity harus salah satu dari: ringan, sedang, berat.",
        )

    log = SideEffectLog(
        patient_id=current_patient.id,
        side_effects=body.side_effects,
        severity=body.severity,
        ai_response=body.ai_response,
        is_emergency=body.is_emergency,
    )
    db.add(log)
    db.commit()
    db.refresh(log)
    return log


@router.get("/history", response_model=List[SideEffectLogResponse])
def get_side_effect_history(
    days: int = Query(default=30, ge=1, le=365),
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    """Return side-effect logs from the last N days."""
    start = datetime.utcnow() - timedelta(days=days)
    return (
        db.query(SideEffectLog)
        .filter(
            SideEffectLog.patient_id == current_patient.id,
            SideEffectLog.logged_at >= start,
        )
        .order_by(SideEffectLog.logged_at.desc())
        .all()
    )
