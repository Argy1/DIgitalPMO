import logging
from datetime import date, timedelta
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.dependencies import get_current_patient, get_current_user, get_db
from app.models.control import ControlSchedule
from app.models.medication import MedicationSchedule
from app.models.patient import PatientProfile
from app.models.risk_score import DropoutRiskScore
from app.models.user import User
from app.schemas.patient import (
    HospitalizedUpdate,
    PatientProfileCreate,
    PatientProfileResponse,
    PatientProfileUpdate,
)
from app.schemas.user import UserResponse
from app.services.medication_service import medication_service

router = APIRouter(prefix="/api/v1/patients", tags=["patients"])
logger = logging.getLogger(__name__)

# TB treatment durations in days
_PHASE_INTENSIVE_DAYS = 56   # first 8 weeks
_TREATMENT_TOTAL_DAYS = 180  # default fallback bila durasi tidak diisi dokter
_TREATMENT_TOTAL_DAYS_RO = 730  # default fallback TB RO (~24 bulan)

# Full drug names for custom medication combinations
_DRUG_NAMES = {
    "R": "Rifampicin",
    "H": "Isoniazid",
    "Z": "Pyrazinamide",
    "E": "Ethambutol",
}


def _calculate_tablet_count(weight_kg: float) -> int:
    """FDC tablet count berdasarkan berat badan (rekomendasi WHO)."""
    if weight_kg < 38:
        return 2
    if weight_kg < 55:
        return 3
    if weight_kg <= 70:
        return 4
    return 5

# Control schedule offsets (days from treatment_start_date)
_CONTROL_DAYS = [
    (60,  "kontrol_1"),
    (150, "kontrol_2"),
    (180, "kontrol_3"),
]

# Standard medication regimens per phase
_REGIMEN = {
    "intensive": {
        "medications": [
            {"code": "R", "name": "Rifampicin"},
            {"code": "H", "name": "Isoniazid"},
            {"code": "Z", "name": "Pyrazinamide"},
            {"code": "E", "name": "Ethambutol"},
        ],
        "schedule_times": ["07:00"],
    },
    "continuation": {
        "medications": [
            {"code": "R", "name": "Rifampicin"},
            {"code": "H", "name": "Isoniazid"},
        ],
        "schedule_times": ["07:00"],
    },
}


def _calculate_phase(treatment_start_date: date) -> str:
    days_elapsed = (date.today() - treatment_start_date).days
    return "intensive" if days_elapsed < _PHASE_INTENSIVE_DAYS else "continuation"


def _treatment_total_days(tb_category: str, duration_days: int | None) -> int:
    """Durasi diisi manual oleh dokter; fallback ke default per kategori."""
    if duration_days and duration_days > 0:
        return duration_days
    return _TREATMENT_TOTAL_DAYS_RO if tb_category == "RO" else _TREATMENT_TOTAL_DAYS


def _treatment_end_date(treatment_start_date: date, total_days: int) -> date:
    return treatment_start_date + timedelta(days=total_days)


# ── GET /me ───────────────────────────────────────────────────────────────────

@router.get("/me")
def get_me(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    """Return current user with their patient profile (if exists)."""
    profile = (
        db.query(PatientProfile)
        .filter(PatientProfile.user_id == current_user.id)
        .first()
    )
    return {
        "user": UserResponse.model_validate(current_user).model_dump(),
        "patient_profile": (
            PatientProfileResponse.model_validate(profile).model_dump()
            if profile else None
        ),
    }


# ── POST /setup-profile ───────────────────────────────────────────────────────

@router.post("/setup-profile", status_code=status.HTTP_201_CREATED)
def setup_profile(
    body: PatientProfileCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    """
    First-time patient profile setup.
    Auto-calculates phase, treatment_end_date, creates medication schedule
    and 3 control schedules (day 60 / 150 / 180).
    """
    existing = (
        db.query(PatientProfile)
        .filter(PatientProfile.user_id == current_user.id)
        .first()
    )
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Profil pasien sudah ada.",
        )

    current_phase = _calculate_phase(body.treatment_start_date)
    total_days = _treatment_total_days(body.tb_category, body.treatment_duration_days)
    end_date = _treatment_end_date(body.treatment_start_date, total_days)

    profile = PatientProfile(
        user_id=current_user.id,
        date_of_birth=body.date_of_birth,
        gender=body.gender,
        faskes_name=body.faskes_name,
        doctor_name=body.doctor_name,
        tb_category=body.tb_category,
        tb_so_type=body.tb_so_type if body.tb_category == "SO" else None,
        tb_ro_type=body.tb_ro_type if body.tb_category == "RO" else None,
        treatment_start_date=body.treatment_start_date,
        current_phase=current_phase,
        treatment_duration_days=total_days,
        treatment_end_date=end_date,
        medication_type=body.medication_type,
        fdc_type=body.fdc_type,
        custom_medications=body.custom_medications,
        weight_kg=body.weight_kg,
        address=body.address,
        is_pregnant=body.is_pregnant or False,
        data_confirmed_by_patient=True,
    )
    db.add(profile)
    db.flush()  # get profile.id before creating related records

    # Medication schedule — phase regimen, extended with FDC/Kombinasi metadata
    regimen = _REGIMEN[current_phase]

    if body.medication_type == "FDC":
        # FDC: tablet count by weight; frequency depends on phase
        tablet_count = (
            _calculate_tablet_count(body.weight_kg) if body.weight_kg else None
        )
        if current_phase == "intensive":
            freq_per_week = 7
            sched_days = [1, 2, 3, 4, 5, 6, 7]
        else:
            freq_per_week = 3
            sched_days = [1, 3, 5]  # Mon, Wed, Fri
        schedule_meds = regimen["medications"]
    elif body.medication_type == "Kombinasi" and body.custom_medications:
        tablet_count = None
        freq_per_week = 7
        sched_days = [1, 2, 3, 4, 5, 6, 7]
        schedule_meds = [
            {"code": code, "name": _DRUG_NAMES.get(code, code)}
            for code in body.custom_medications
        ]
    else:
        tablet_count = None
        freq_per_week = 7
        sched_days = [1, 2, 3, 4, 5, 6, 7]
        schedule_meds = regimen["medications"]

    schedule = MedicationSchedule(
        patient_id=profile.id,
        phase=current_phase,
        medications=schedule_meds,
        schedule_times=regimen["schedule_times"],
        medication_type=body.medication_type,
        fdc_type=body.fdc_type,
        tablet_count=tablet_count,
        frequency_per_week=freq_per_week,
        schedule_days=sched_days,
        reminder_before=30,
        is_active=True,
    )
    db.add(schedule)
    db.flush()

    # Control schedules — day 60, 150, 180
    controls = []
    for day_offset, control_type in _CONTROL_DAYS:
        ctrl = ControlSchedule(
            patient_id=profile.id,
            scheduled_date=body.treatment_start_date + timedelta(days=day_offset),
            control_type=control_type,
            faskes_name=body.faskes_name,
        )
        db.add(ctrl)
        controls.append(ctrl)
    db.flush()

    # Mark user as patient role
    current_user.role = "patient"
    db.commit()

    db.refresh(profile)
    db.refresh(schedule)
    for ctrl in controls:
        db.refresh(ctrl)

    logger.info("Patient profile setup complete for user %s", current_user.id)

    return {
        "profile": PatientProfileResponse.model_validate(profile).model_dump(),
        "schedule": {
            "id": str(schedule.id),
            "phase": schedule.phase,
            "medications": schedule.medications,
            "schedule_times": schedule.schedule_times,
            "reminder_before": schedule.reminder_before,
        },
        "controls": [
            {
                "id": str(ctrl.id),
                "control_type": ctrl.control_type,
                "scheduled_date": ctrl.scheduled_date.isoformat(),
                "faskes_name": ctrl.faskes_name,
            }
            for ctrl in controls
        ],
    }


# ── PUT /me ───────────────────────────────────────────────────────────────────

@router.put("/me", response_model=PatientProfileResponse)
def update_me(
    body: PatientProfileUpdate,
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    """Update allowed patient profile fields."""
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(current_patient, field, value)
    db.commit()
    db.refresh(current_patient)
    return current_patient


# ── PUT /me/hospitalized ──────────────────────────────────────────────────────

@router.put("/me/hospitalized", response_model=PatientProfileResponse)
def update_hospitalized(
    body: HospitalizedUpdate,
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    """Toggle rawat-inap (hospitalized) mode."""
    current_patient.is_hospitalized = body.is_hospitalized
    db.commit()
    db.refresh(current_patient)
    logger.info(
        "Patient %s hospitalized=%s", current_patient.id, body.is_hospitalized
    )
    return current_patient


# ── GET /dashboard ────────────────────────────────────────────────────────────

@router.get("/dashboard")
def get_dashboard(
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    """Return patient dashboard summary."""
    today = date.today()
    days_in_treatment = (today - current_patient.treatment_start_date).days
    total_days = _treatment_total_days(
        current_patient.tb_category, current_patient.treatment_duration_days
    )
    completion_pct = min((days_in_treatment / total_days) * 100, 100.0)

    today_status = medication_service.get_today_status(db, current_patient.id)

    latest_risk = (
        db.query(DropoutRiskScore)
        .filter(DropoutRiskScore.patient_id == current_patient.id)
        .order_by(DropoutRiskScore.calculated_at.desc())
        .first()
    )

    return {
        "patient": {
            "id": str(current_patient.id),
            "full_name": current_patient.user.full_name,
            "faskes_name": current_patient.faskes_name,
            "doctor_name": current_patient.doctor_name,
            "tb_category": current_patient.tb_category,
            "tb_so_type": current_patient.tb_so_type,
            "tb_ro_type": current_patient.tb_ro_type,
            "current_phase": current_patient.current_phase,
            "treatment_start_date": current_patient.treatment_start_date.isoformat(),
            "treatment_end_date": (
                current_patient.treatment_end_date.isoformat()
                if current_patient.treatment_end_date else None
            ),
        },
        "today_medication": today_status,
        "days_in_treatment": days_in_treatment,
        "completion_percentage": round(completion_pct, 1),
        "current_risk_level": latest_risk.risk_level if latest_risk else "low",
        "risk_score": float(latest_risk.score) if latest_risk else None,
    }
