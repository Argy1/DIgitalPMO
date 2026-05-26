import logging
from typing import Any, List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.dependencies import get_current_patient, get_db
from app.core.exceptions import NotFoundException
from app.models.patient import PatientProfile
from app.schemas.report import MonthlyReportResponse, PdfGenerateResponse, ReportGenerateRequest
from app.services.report_service import report_service
from app.services.storage_service import storage_service

router = APIRouter(prefix="/api/v1/reports", tags=["reports"])
logger = logging.getLogger(__name__)

_PDF_PRESIGN_TTL = 604800  # 7 days (SigV4 max)


def _validate_year_month(year: int, month: int) -> None:
    if not (1 <= month <= 12):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Bulan harus antara 1 dan 12.",
        )
    if year < 2020 or year > 2100:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Tahun tidak valid.",
        )


# ── GET /monthly/{year}/{month} ───────────────────────────────────────────────

@router.get("/monthly/{year}/{month}", response_model=MonthlyReportResponse)
def get_or_generate_monthly_report(
    year: int,
    month: int,
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> Any:
    """Return the monthly report; generate it on the fly if not yet created."""
    _validate_year_month(year, month)
    report_month = f"{year}-{month:02d}"
    try:
        report = report_service.get_report(db, current_patient.id, report_month)
    except NotFoundException:
        report = report_service.generate_report(db, current_patient.id, report_month)
    return report


# ── POST /generate-pdf/{year}/{month} ────────────────────────────────────────

@router.post("/generate-pdf/{year}/{month}", response_model=PdfGenerateResponse)
def generate_pdf(
    year: int,
    month: int,
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> Any:
    """
    Generate a PDF report for the given month, upload to R2, update
    monthly_reports.pdf_url, and return a time-limited signed download URL.
    """
    _validate_year_month(year, month)
    report_month = f"{year}-{month:02d}"

    patient_name = (
        current_patient.user.full_name if current_patient.user else "Pasien"
    )

    try:
        signed_url = report_service.generate_pdf(
            db, current_patient.id, report_month, patient_name
        )
    except RuntimeError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        )

    return PdfGenerateResponse(
        signed_url=signed_url,
        expires_in_seconds=_PDF_PRESIGN_TTL,
        report_month=report_month,
    )


# ── GET / (list last 6 months) ────────────────────────────────────────────────

@router.get("/", response_model=List[MonthlyReportResponse])
def list_reports(
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    """List the 6 most recent monthly reports."""
    return report_service.list_reports(db, current_patient.id, limit=6)


# ── POST /generate (explicit month string) ────────────────────────────────────

@router.post("/generate", response_model=MonthlyReportResponse, status_code=status.HTTP_201_CREATED)
def generate_report(
    body: ReportGenerateRequest,
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    """Force-regenerate a monthly report by month string (YYYY-MM)."""
    report = report_service.generate_report(db, current_patient.id, body.report_month)
    logger.info("Report generated for patient %s, month=%s", current_patient.id, body.report_month)
    return report


# ── GET /{report_month} (string format fallback) ──────────────────────────────

@router.get("/{report_month}", response_model=MonthlyReportResponse)
def get_report_by_month_string(
    report_month: str,
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    """Get a report by month string (YYYY-MM)."""
    return report_service.get_report(db, current_patient.id, report_month)
