from datetime import date, datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class SymptomLogCreate(BaseModel):
    cough_scale: int = Field(..., ge=1, le=5)
    breath_scale: int = Field(..., ge=1, le=5)
    appetite_scale: int = Field(..., ge=1, le=5)
    energy_scale: int = Field(..., ge=1, le=5)
    has_fever: bool
    fever_temp: Optional[float] = None
    has_night_sweats: bool
    weight_kg: Optional[float] = None
    notes: Optional[str] = None


class SymptomLogResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    patient_id: UUID
    logged_at: date
    cough_scale: int
    breath_scale: int
    appetite_scale: int
    energy_scale: int
    has_fever: bool
    fever_temp: Optional[float] = None
    has_night_sweats: bool
    weight_kg: Optional[float] = None
    notes: Optional[str] = None
    ai_assessment: Optional[str] = None
    created_at: datetime
