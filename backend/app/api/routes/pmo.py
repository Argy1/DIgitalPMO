import json
import logging
import uuid as _uuid_mod
from datetime import date, datetime, timedelta, timezone
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from jose import JWTError
from jose import jwt as jose_jwt
from sqlalchemy.orm import Session

from app.api.dependencies import get_current_patient, get_current_user, get_db
from app.core.config import get_settings
from app.core.redis_client import redis_client
from app.models.medication import MedicationLog, MedicationSchedule
from app.models.notification import Notification
from app.models.patient import PatientProfile
from app.models.pmo_patient import PMOPatient
from app.models.risk_score import DropoutRiskScore
from app.models.user import User
from app.schemas.pmo import (
    PMODashboard,
    PMOLinkRequest,
    PMOLinkRequestCreated,
    PMOLinkResponse,
    PMOPatientSummary,
    PMOQRLinkRequest,
    PMOQRToken,
)
from app.services.medication_service import medication_service

router = APIRouter(prefix="/api/v1/pmo", tags=["pmo"])
logger = logging.getLogger(__name__)

_LINK_REQ_PREFIX = "pmo_link_req:"
_LINK_REQ_TTL = 86400  # 24 hours


def _require_pmo(current_user: User = Depends(get_current_user)) -> User:
    if current_user.role != "pmo":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Hanya PMO yang dapat mengakses resource ini.",
        )
    return current_user


def _tb_type_display(profile: PatientProfile) -> str:
    if profile.tb_category == "SO":
        return f"SO - {profile.tb_so_type or 'TB Paru'}"
    return f"RO - {profile.tb_ro_type or ''}"


def _today_med_status(
    db: Session, patient_id, last_confirmed_at: datetime | None
) -> str:
    today = date.today()
    today_start = datetime.combine(today, datetime.min.time())
    today_end = datetime.combine(today, datetime.max.time())

    active_schedule = (
        db.query(MedicationSchedule)
        .filter(
            MedicationSchedule.patient_id == patient_id,
            MedicationSchedule.is_active == True,
        )
        .first()
    )
    if not active_schedule:
        return "no_schedule"

    today_confirmed = (
        db.query(MedicationLog)
        .filter(
            MedicationLog.patient_id == patient_id,
            MedicationLog.scheduled_time >= today_start,
            MedicationLog.scheduled_time <= today_end,
            MedicationLog.status == "confirmed",
        )
        .first()
    )
    if today_confirmed:
        return "confirmed"

    if last_confirmed_at is None:
        return "missed"
    days_since = (datetime.utcnow() - last_confirmed_at).days
    return "missed" if days_since >= 2 else "pending"


def _adherence_last_30(db: Session, patient_id) -> float:
    cutoff = datetime.utcnow() - timedelta(days=30)
    logs = (
        db.query(MedicationLog)
        .filter(
            MedicationLog.patient_id == patient_id,
            MedicationLog.scheduled_time >= cutoff,
            MedicationLog.status.in_(["confirmed", "skipped", "late"]),
        )
        .all()
    )
    if not logs:
        return 0.0
    confirmed = sum(1 for log in logs if log.status == "confirmed")
    return round(confirmed / len(logs) * 100, 1)


def _build_patient_summary(db: Session, link: PMOPatient) -> PMOPatientSummary:
    patient = link.patient
    user = patient.user

    last_log = (
        db.query(MedicationLog)
        .filter(
            MedicationLog.patient_id == patient.id,
            MedicationLog.status == "confirmed",
        )
        .order_by(MedicationLog.scheduled_time.desc())
        .first()
    )
    last_confirmed_at = last_log.scheduled_time if last_log else None

    latest_risk = (
        db.query(DropoutRiskScore)
        .filter(DropoutRiskScore.patient_id == patient.id)
        .order_by(DropoutRiskScore.calculated_at.desc())
        .first()
    )

    return PMOPatientSummary(
        patient_id=patient.id,
        patient_name=user.full_name,
        patient_phone=user.phone_number or "",
        tb_type_display=_tb_type_display(patient),
        current_phase=patient.current_phase,
        treatment_day=(date.today() - patient.treatment_start_date).days + 1,
        today_medication_status=_today_med_status(db, patient.id, last_confirmed_at),
        adherence_last_30_days=_adherence_last_30(db, patient.id),
        current_streak=medication_service.calculate_streak(db, patient.id),
        risk_level=latest_risk.risk_level if latest_risk else "low",
        last_confirmed_at=last_confirmed_at,
    )


_STATUS_ORDER = {"missed": 0, "no_schedule": 1, "pending": 2, "confirmed": 3}


# ── GET /dashboard ────────────────────────────────────────────────────────────

@router.get("/dashboard", response_model=PMODashboard)
def get_pmo_dashboard(
    pmo_user: User = Depends(_require_pmo),
    db: Session = Depends(get_db),
):
    """Dashboard PMO: daftar semua pasien yang diawasi beserta status harian."""
    links = (
        db.query(PMOPatient)
        .filter(PMOPatient.pmo_user_id == pmo_user.id, PMOPatient.is_active == True)
        .all()
    )

    summaries = [_build_patient_summary(db, link) for link in links]
    summaries.sort(key=lambda s: _STATUS_ORDER.get(s.today_medication_status, 2))

    missed_today = sum(
        1 for s in summaries if s.today_medication_status == "missed"
    )

    return PMODashboard(
        total_patients=len(summaries),
        missed_today=missed_today,
        patients=summaries,
    )


# ── GET /patients/{patient_id} ────────────────────────────────────────────────

@router.get("/patients/{patient_id}")
def get_pmo_patient_detail(
    patient_id: str,
    pmo_user: User = Depends(_require_pmo),
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    """Detail pasien: profil + 7 hari log minum obat + skor risiko terkini."""
    link = (
        db.query(PMOPatient)
        .filter(
            PMOPatient.pmo_user_id == pmo_user.id,
            PMOPatient.patient_id == patient_id,
            PMOPatient.is_active == True,
        )
        .first()
    )
    if not link:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pasien tidak ditemukan atau tidak terhubung dengan akun PMO ini.",
        )

    patient = link.patient
    user = patient.user
    seven_days_ago = datetime.utcnow() - timedelta(days=7)

    med_logs = (
        db.query(MedicationLog)
        .filter(
            MedicationLog.patient_id == patient.id,
            MedicationLog.scheduled_time >= seven_days_ago,
        )
        .order_by(MedicationLog.scheduled_time.desc())
        .all()
    )

    latest_risk = (
        db.query(DropoutRiskScore)
        .filter(DropoutRiskScore.patient_id == patient.id)
        .order_by(DropoutRiskScore.calculated_at.desc())
        .first()
    )

    return {
        "patient": {
            "id": str(patient.id),
            "full_name": user.full_name,
            "phone_number": user.phone_number,
            "date_of_birth": patient.date_of_birth.isoformat(),
            "gender": patient.gender,
            "address": patient.address,
            "faskes_name": patient.faskes_name,
            "doctor_name": patient.doctor_name,
            "tb_category": patient.tb_category,
            "tb_so_type": patient.tb_so_type,
            "tb_ro_type": patient.tb_ro_type,
            "current_phase": patient.current_phase,
            "treatment_start_date": patient.treatment_start_date.isoformat(),
            "treatment_end_date": (
                patient.treatment_end_date.isoformat()
                if patient.treatment_end_date else None
            ),
            "medication_type": patient.medication_type,
            "weight_kg": patient.weight_kg,
            "is_pregnant": patient.is_pregnant,
            "is_hospitalized": patient.is_hospitalized,
        },
        "medication_logs_7d": [
            {
                "id": str(log.id),
                "scheduled_time": log.scheduled_time.isoformat(),
                "confirmed_at": (
                    log.confirmed_at.isoformat() if log.confirmed_at else None
                ),
                "status": log.status,
                "streak_count": log.streak_count,
            }
            for log in med_logs
        ],
        "adherence_30d": _adherence_last_30(db, patient.id),
        "current_streak": medication_service.calculate_streak(db, patient.id),
        "risk": {
            "level": latest_risk.risk_level if latest_risk else "low",
            "score": float(latest_risk.score) if latest_risk else None,
            "calculated_at": (
                latest_risk.calculated_at.isoformat() if latest_risk else None
            ),
        },
        "linked_via": link.linked_via,
        "linked_at": link.linked_at.isoformat(),
    }


# ── POST /link/request ────────────────────────────────────────────────────────

@router.post(
    "/link/request",
    response_model=PMOLinkRequestCreated,
    status_code=status.HTTP_201_CREATED,
)
def request_patient_link(
    body: PMOLinkRequest,
    pmo_user: User = Depends(_require_pmo),
    db: Session = Depends(get_db),
):
    """PMO meminta izin untuk mengawasi pasien berdasarkan nomor HP."""
    target_user = (
        db.query(User)
        .filter(User.phone_number == body.patient_phone, User.role == "patient")
        .first()
    )
    if not target_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pasien dengan nomor HP tersebut tidak ditemukan.",
        )

    patient = (
        db.query(PatientProfile)
        .filter(PatientProfile.user_id == target_user.id)
        .first()
    )
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pasien belum melengkapi profil.",
        )

    existing_link = (
        db.query(PMOPatient)
        .filter(PMOPatient.patient_id == patient.id, PMOPatient.is_active == True)
        .first()
    )
    if existing_link:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Pasien sudah terhubung dengan PMO lain.",
        )

    request_id = str(_uuid_mod.uuid4())
    redis_client.setex(
        f"{_LINK_REQ_PREFIX}{request_id}",
        _LINK_REQ_TTL,
        json.dumps({
            "pmo_user_id": str(pmo_user.id),
            "patient_id": str(patient.id),
            "pmo_name": pmo_user.full_name,
            "created_at": datetime.utcnow().isoformat(),
        }),
    )

    notif = Notification(
        patient_id=patient.id,
        type="system",
        title="Permintaan Pengawasan PMO",
        body=f"PMO {pmo_user.full_name} ingin mengawasi pengobatan Anda.",
        data={"link_request_id": request_id, "pmo_name": pmo_user.full_name},
    )
    db.add(notif)
    db.commit()

    logger.info("PMO link request %s: PMO %s → patient %s", request_id, pmo_user.id, patient.id)
    return PMOLinkRequestCreated(
        link_request_id=request_id,
        message="Permintaan pengawasan berhasil dikirim ke pasien.",
    )


# ── POST /link/approve/{link_request_id} ─────────────────────────────────────

@router.post("/link/approve/{link_request_id}", response_model=PMOLinkResponse)
def approve_patient_link(
    link_request_id: str,
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    """Pasien menyetujui permintaan pengawasan dari PMO."""
    raw = redis_client.get(f"{_LINK_REQ_PREFIX}{link_request_id}")
    if not raw:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Permintaan tidak ditemukan atau sudah kedaluwarsa.",
        )

    data = json.loads(raw)
    if data["patient_id"] != str(current_patient.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Permintaan ini bukan untuk akun Anda.",
        )

    existing = (
        db.query(PMOPatient)
        .filter(PMOPatient.patient_id == current_patient.id, PMOPatient.is_active == True)
        .first()
    )
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Anda sudah terhubung dengan seorang PMO.",
        )

    link = PMOPatient(
        pmo_user_id=data["pmo_user_id"],
        patient_id=current_patient.id,
        linked_via="phone_request",
    )
    db.add(link)
    redis_client.delete(f"{_LINK_REQ_PREFIX}{link_request_id}")
    db.commit()
    db.refresh(link)

    pmo_user = db.query(User).filter(User.id == data["pmo_user_id"]).first()
    logger.info("PMO link approved: %s → patient %s", data["pmo_user_id"], current_patient.id)
    return PMOLinkResponse(
        pmo_patient_id=link.id,
        linked_via=link.linked_via,
        linked_at=link.linked_at,
        patient_id=link.patient_id,
        patient_name=current_patient.user.full_name,
        message=f"Berhasil terhubung dengan PMO {pmo_user.full_name if pmo_user else ''}.",
    )


# ── DELETE /link/reject/{link_request_id} ────────────────────────────────────

@router.delete("/link/reject/{link_request_id}")
def reject_patient_link(
    link_request_id: str,
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> dict[str, str]:
    """Pasien menolak permintaan pengawasan dari PMO."""
    raw = redis_client.get(f"{_LINK_REQ_PREFIX}{link_request_id}")
    if not raw:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Permintaan tidak ditemukan atau sudah kedaluwarsa.",
        )

    data = json.loads(raw)
    if data["patient_id"] != str(current_patient.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Permintaan ini bukan untuk akun Anda.",
        )

    redis_client.delete(f"{_LINK_REQ_PREFIX}{link_request_id}")
    logger.info("PMO link rejected: request %s by patient %s", link_request_id, current_patient.id)
    return {"message": "Permintaan pengawasan berhasil ditolak."}


# ── POST /link/qr ─────────────────────────────────────────────────────────────

@router.post("/link/qr", response_model=PMOLinkResponse)
def link_via_qr(
    body: PMOQRLinkRequest,
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    """Pasien scan QR code PMO untuk terhubung secara instan."""
    settings = get_settings()
    try:
        payload = jose_jwt.decode(
            body.qr_token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Token QR tidak valid atau sudah kedaluwarsa.",
        )

    if payload.get("type") != "qr_link":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Bukan token QR yang valid.",
        )

    pmo_user_id = payload.get("sub")
    pmo_user = (
        db.query(User)
        .filter(User.id == pmo_user_id, User.role == "pmo")
        .first()
    )
    if not pmo_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Akun PMO tidak ditemukan.",
        )

    existing = (
        db.query(PMOPatient)
        .filter(PMOPatient.patient_id == current_patient.id, PMOPatient.is_active == True)
        .first()
    )
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Anda sudah terhubung dengan seorang PMO.",
        )

    link = PMOPatient(
        pmo_user_id=pmo_user_id,
        patient_id=current_patient.id,
        linked_via="qr_code",
    )
    db.add(link)
    db.commit()
    db.refresh(link)

    logger.info("PMO QR link: %s → patient %s", pmo_user_id, current_patient.id)
    return PMOLinkResponse(
        pmo_patient_id=link.id,
        linked_via=link.linked_via,
        linked_at=link.linked_at,
        patient_id=link.patient_id,
        patient_name=current_patient.user.full_name,
        message=f"Berhasil terhubung dengan PMO {pmo_user.full_name}.",
    )


# ── GET /my-pmo ───────────────────────────────────────────────────────────────

@router.get("/my-pmo")
def get_my_pmo(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    """Pasien mendapatkan info PMO yang saat ini mengawasi mereka."""
    if current_user.role != "patient":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Hanya pasien yang dapat mengakses resource ini.",
        )
    patient = (
        db.query(PatientProfile)
        .filter(PatientProfile.user_id == current_user.id)
        .first()
    )
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profil pasien tidak ditemukan.",
        )
    link = (
        db.query(PMOPatient)
        .filter(PMOPatient.patient_id == patient.id, PMOPatient.is_active == True)
        .first()
    )
    if not link:
        return {"linked": False}

    pmo_user = db.query(User).filter(User.id == link.pmo_user_id).first()
    return {
        "linked": True,
        "pmo_name": pmo_user.full_name if pmo_user else "PMO",
        "pmo_phone": pmo_user.phone_number if pmo_user else None,
        "linked_via": link.linked_via,
        "linked_at": link.linked_at.isoformat(),
        "patient_id": str(patient.id),
    }


# ── GET /generate-qr ──────────────────────────────────────────────────────────

@router.get("/generate-qr", response_model=PMOQRToken)
def generate_qr_token(
    pmo_user: User = Depends(_require_pmo),
):
    """Generate JWT QR code yang bisa di-scan pasien untuk auto-link."""
    settings = get_settings()
    expire = datetime.now(timezone.utc) + timedelta(hours=24)
    token = jose_jwt.encode(
        {"sub": str(pmo_user.id), "type": "qr_link", "exp": expire},
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM,
    )
    return PMOQRToken(qr_token=token, expires_at=expire)


# ── DELETE /unlink/{patient_id} ───────────────────────────────────────────────

@router.delete("/unlink/{patient_id}")
def unlink_patient(
    patient_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict[str, str]:
    """PMO atau pasien memutus hubungan pengawasan."""
    if current_user.role == "pmo":
        link = (
            db.query(PMOPatient)
            .filter(
                PMOPatient.pmo_user_id == current_user.id,
                PMOPatient.patient_id == patient_id,
                PMOPatient.is_active == True,
            )
            .first()
        )
    elif current_user.role == "patient":
        patient_profile = (
            db.query(PatientProfile)
            .filter(PatientProfile.user_id == current_user.id)
            .first()
        )
        if not patient_profile or str(patient_profile.id) != patient_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Anda hanya bisa memutus hubungan dengan PMO Anda sendiri.",
            )
        link = (
            db.query(PMOPatient)
            .filter(
                PMOPatient.patient_id == patient_id,
                PMOPatient.is_active == True,
            )
            .first()
        )
    else:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Hanya PMO atau pasien yang dapat memutus hubungan.",
        )

    if not link:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hubungan PMO-pasien tidak ditemukan.",
        )

    link.is_active = False
    db.commit()
    logger.info("PMO link deactivated: %s", link.id)
    return {"message": "Hubungan PMO-pasien berhasil diputus."}
