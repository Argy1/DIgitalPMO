import logging
from collections import defaultdict
from datetime import date, datetime
from typing import Any

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query, Request, status
from sqlalchemy.orm import Session

from app.api.dependencies import get_current_patient, get_db, limiter
from app.models.medication import MedicationLog, MedicationSchedule
from app.models.patient import PatientProfile
from app.schemas.medication import (
    MedicationConfirmRequest,
    MedicationConfirmResponse,
    MedicationLogCreate,
    MedicationLogResponse,
    MedicationScheduleResponse,
    PhotoVerifyRequest,
    PhotoVerifyResponse,
)
from app.services.medication_service import medication_service
from app.services.storage_service import storage_service

router = APIRouter(prefix="/api/v1/medications", tags=["medications"])
logger = logging.getLogger(__name__)


def _serialize_log(log: MedicationLog) -> dict:
    return MedicationLogResponse.model_validate(log).model_dump(mode="json")


# ── GET /today ────────────────────────────────────────────────────────────────

@router.get("/today")
def get_today(
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    """Today's schedule + medication logs + current streak."""
    schedule = (
        db.query(MedicationSchedule)
        .filter(
            MedicationSchedule.patient_id == current_patient.id,
            MedicationSchedule.is_active == True,
        )
        .first()
    )

    today = date.today()
    today_start = datetime.combine(today, datetime.min.time())
    today_end = datetime.combine(today, datetime.max.time())
    logs = (
        db.query(MedicationLog)
        .filter(
            MedicationLog.patient_id == current_patient.id,
            MedicationLog.scheduled_time >= today_start,
            MedicationLog.scheduled_time <= today_end,
        )
        .order_by(MedicationLog.scheduled_time.asc())
        .all()
    )

    streak = medication_service.calculate_streak(db, current_patient.id)

    return {
        "schedule": (
            MedicationScheduleResponse.model_validate(schedule).model_dump(mode="json")
            if schedule else None
        ),
        "logs": [_serialize_log(log) for log in logs],
        "streak_count": streak,
    }


# ── POST /confirm ─────────────────────────────────────────────────────────────

@router.post(
    "/confirm",
    response_model=MedicationConfirmResponse,
    status_code=status.HTTP_201_CREATED,
)
@limiter.limit("10/hour")
def confirm_medication(
    request: Request,
    body: MedicationConfirmRequest,
    background_tasks: BackgroundTasks,
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    """
    Confirm today's dose with a photo.
    Uploads the photo to R2, creates the log, and kicks off AI verification
    asynchronously. Verification status is 'pending' on response.
    """
    # 3. Upload photo to Cloudflare R2
    upload = storage_service.upload_photo(body.photo_base64, current_patient.id)

    # 1 & 2. Validate schedule ownership + no duplicate confirmation (in service)
    log, verification = medication_service.confirm_with_photo(
        db,
        patient_id=current_patient.id,
        schedule_id=body.schedule_id,
        photo_url=upload["url"],
        device_id=body.device_id,
        photo_taken_at=body.photo_taken_at,
    )

    # 4. AI verification runs in the background
    background_tasks.add_task(
        medication_service.run_photo_verification,
        verification.id,
        body.photo_base64,
    )

    return MedicationConfirmResponse(
        log_id=log.id,
        verification_id=verification.id,
        verification_status="pending",
        streak_count=log.streak_count,
        message=(
            f"Obat berhasil dikonfirmasi! Streak Anda {log.streak_count} hari. "
            "Foto sedang diverifikasi."
        ),
    )


# ── POST /verify-photo ────────────────────────────────────────────────────────

@router.post("/verify-photo", response_model=PhotoVerifyResponse)
def verify_photo(
    body: PhotoVerifyRequest,
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    """Run (or re-run) AI verification for a medication photo synchronously."""
    verification = medication_service.apply_verification(
        db, body.verification_id, body.photo_base64
    )
    if verification.is_valid is True:
        message = "Foto valid — obat terverifikasi."
    elif verification.is_valid is False:
        message = verification.rejection_reason or "Foto ditolak."
    else:
        message = "Verifikasi otomatis gagal. Foto akan ditinjau manual."

    return PhotoVerifyResponse(
        is_valid=verification.is_valid,
        confidence=float(verification.confidence_score or 0.0),
        message=message,
    )


# ── GET /history ──────────────────────────────────────────────────────────────

@router.get("/history")
def get_history(
    month: str = Query(..., description="Bulan dalam format YYYY-MM, contoh: 2025-03"),
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    """Medication logs for a given month, grouped by date."""
    try:
        year_s, month_s = month.split("-")
        year, month_n = int(year_s), int(month_s)
        if not (1 <= month_n <= 12):
            raise ValueError
    except (ValueError, AttributeError):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Format bulan tidak valid. Gunakan 'YYYY-MM', contoh: '2025-03'.",
        )

    logs = medication_service.get_history_by_month(
        db, current_patient.id, year, month_n
    )

    grouped: dict[str, list] = defaultdict(list)
    for log in logs:
        day_key = log.scheduled_time.date().isoformat()
        grouped[day_key].append(_serialize_log(log))

    return {
        "month": month,
        "total": len(logs),
        "days": [
            {"date": day, "logs": grouped[day]}
            for day in sorted(grouped.keys(), reverse=True)
        ],
    }


# ── GET /schedule ─────────────────────────────────────────────────────────────

@router.get("/schedule", response_model=MedicationScheduleResponse)
def get_schedule(
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    """Get the active medication schedule."""
    schedule = (
        db.query(MedicationSchedule)
        .filter(
            MedicationSchedule.patient_id == current_patient.id,
            MedicationSchedule.is_active == True,
        )
        .first()
    )
    if not schedule:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Jadwal minum obat belum diatur.",
        )
    return schedule


# ── POST /skip ────────────────────────────────────────────────────────────────

@router.post("/skip", response_model=MedicationLogResponse)
def skip_medication(
    body: MedicationLogCreate,
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    """Log a skipped medication dose."""
    body.status = "skipped"
    return medication_service.skip_medication(db, current_patient.id, body)


# ── GET /streak ───────────────────────────────────────────────────────────────

@router.get("/streak")
def get_streak(
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    """Current consecutive-day medication streak."""
    streak = medication_service.calculate_streak(db, current_patient.id)
    return {
        "streak": streak,
        "message": f"Streak minum obat: {streak} hari berturut-turut.",
    }
