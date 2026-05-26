import logging
from datetime import date, datetime, timedelta
from typing import List

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.api.dependencies import get_current_patient, get_db
from app.models.patient import PatientProfile
from app.models.symptom import SymptomLog
from app.schemas.symptom import SymptomLogCreate, SymptomLogResponse
from app.services.ai_service import ai_service

router = APIRouter(prefix="/api/v1/symptoms", tags=["symptoms"])
logger = logging.getLogger(__name__)


def _serialize_symptom_log(log: SymptomLog) -> dict:
    return {
        "id": log.id,
        "patient_id": log.patient_id,
        "logged_at": log.logged_date,
        "cough_scale": log.cough_scale,
        "breath_scale": log.shortness_of_breath,
        "appetite_scale": log.appetite_scale,
        "energy_scale": log.energy_scale,
        "has_fever": log.fever,
        "fever_temp": log.fever_temperature,
        "has_night_sweats": log.night_sweats,
        "weight_kg": log.weight_kg,
        "notes": log.additional_notes,
        "ai_assessment": log.ai_assessment,
        "created_at": log.created_at,
    }


@router.post("/log", response_model=SymptomLogResponse, status_code=status.HTTP_201_CREATED)
def log_symptoms(
    body: SymptomLogCreate,
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    """Log today's symptoms. Only one log per day is allowed."""
    today = date.today()
    existing = (
        db.query(SymptomLog)
        .filter(
            SymptomLog.patient_id == current_patient.id,
            SymptomLog.logged_date == today,
        )
        .first()
    )
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Gejala untuk hari ini sudah dicatat.",
        )

    symptom_log = SymptomLog(
        patient_id=current_patient.id,
        logged_date=today,
        cough_scale=body.cough_scale,
        shortness_of_breath=body.breath_scale,
        appetite_scale=body.appetite_scale,
        energy_scale=body.energy_scale,
        fever=body.has_fever,
        fever_temperature=body.fever_temp,
        night_sweats=body.has_night_sweats,
        weight_kg=body.weight_kg,
        additional_notes=body.notes,
    )
    db.add(symptom_log)
    db.commit()
    db.refresh(symptom_log)

    # Run AI assessment
    try:
        symptom_data = body.model_dump()
        ai_assessment = ai_service.assess_symptoms(symptom_data)
        symptom_log.ai_assessment = ai_assessment
        db.commit()
        db.refresh(symptom_log)
    except Exception as e:
        logger.error(f"AI assessment failed for symptom log {symptom_log.id}: {e}")

    return _serialize_symptom_log(symptom_log)


@router.get("/today", response_model=SymptomLogResponse)
def get_today_symptoms(
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    """Get today's symptom log."""
    today = date.today()
    log = (
        db.query(SymptomLog)
        .filter(
            SymptomLog.patient_id == current_patient.id,
            SymptomLog.logged_date == today,
        )
        .first()
    )
    if not log:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Belum ada catatan gejala untuk hari ini.",
        )
    return _serialize_symptom_log(log)


@router.get("/history", response_model=List[SymptomLogResponse])
def get_symptom_history(
    days: int = Query(default=30, ge=1, le=365),
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    """Get symptom history for last N days."""
    start_date = date.today() - timedelta(days=days)
    logs = (
        db.query(SymptomLog)
        .filter(
            SymptomLog.patient_id == current_patient.id,
            SymptomLog.logged_date >= start_date,
        )
        .order_by(SymptomLog.logged_date.desc())
        .all()
    )
    return [_serialize_symptom_log(log) for log in logs]


@router.get("/trend")
def get_symptom_trend(
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    """Return average symptom scores per week for last 4 weeks."""
    today = date.today()
    weeks_data = []

    for week_num in range(4):
        end = today - timedelta(days=week_num * 7)
        start = end - timedelta(days=7)

        logs = (
            db.query(SymptomLog)
            .filter(
                SymptomLog.patient_id == current_patient.id,
                SymptomLog.logged_date > start,
                SymptomLog.logged_date <= end,
            )
            .all()
        )

        if logs:
            count = len(logs)
            avg_cough = sum(l.cough_scale for l in logs) / count
            avg_breath = sum(l.shortness_of_breath for l in logs) / count
            avg_appetite = sum(l.appetite_scale for l in logs) / count
            avg_energy = sum(l.energy_scale for l in logs) / count
        else:
            avg_cough = avg_breath = avg_appetite = avg_energy = 0.0

        weeks_data.append(
            {
                "week": week_num + 1,
                "period": f"{start.isoformat()} - {end.isoformat()}",
                "avg_cough": round(avg_cough, 2),
                "avg_breath": round(avg_breath, 2),
                "avg_appetite": round(avg_appetite, 2),
                "avg_energy": round(avg_energy, 2),
                "log_count": len(logs),
            }
        )

    # Return most recent week first
    return {"weeks": weeks_data}
