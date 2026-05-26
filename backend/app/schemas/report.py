from datetime import date, datetime
from typing import Any, List, Optional, Union
from uuid import UUID

from pydantic import BaseModel, ConfigDict, field_validator


class ReportGenerateRequest(BaseModel):
    report_month: str  # e.g. "2025-03"


class MonthlyReportResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    patient_id: UUID
    report_month: Any  # Date stored as date obj; serialised as str via validator
    adherence_percentage: float
    total_scheduled: int
    confirmed_doses: int
    missed_doses: int
    late_doses: int
    avg_cough_scale: Optional[float] = None
    avg_appetite_scale: Optional[float] = None
    avg_energy_scale: Optional[float] = None
    side_effects_summary: Optional[dict] = None
    ai_summary: Optional[str] = None
    ai_recommendation: Optional[Union[List[str], str]] = None
    pdf_url: Optional[str] = None
    generated_at: Optional[datetime] = None
    created_at: datetime

    @field_validator("report_month", mode="before")
    @classmethod
    def coerce_report_month(cls, v):
        if isinstance(v, date):
            return v.strftime("%Y-%m")
        return v


class PdfGenerateResponse(BaseModel):
    signed_url: str
    expires_in_seconds: int
    report_month: str
