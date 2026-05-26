from datetime import datetime
from typing import Any, List, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class MedicationScheduleCreate(BaseModel):
    phase: str
    medications: List[dict]
    schedule_times: List[str]
    reminder_before: int = 30


class MedicationScheduleResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    patient_id: UUID
    phase: str
    medications: List[Any]
    schedule_times: List[Any]
    reminder_before: int
    is_active: bool
    created_at: datetime


class MedicationLogCreate(BaseModel):
    status: str  # "confirmed" | "skipped" | "late"
    photo_url: Optional[str] = None
    notes: Optional[str] = None
    scheduled_time: Optional[datetime] = None


class MedicationLogResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    patient_id: UUID
    scheduled_time: datetime
    confirmed_at: Optional[datetime] = None
    status: str
    streak_count: int
    photo_url: Optional[str] = None
    notes: Optional[str] = None
    created_at: datetime


class TodayStatusResponse(BaseModel):
    is_taken: bool
    confirmed_at: Optional[str] = None
    streak: int
    schedule_time: Optional[str] = None
    status: str = "pending"


class MedicationConfirmRequest(BaseModel):
    schedule_id: UUID
    photo_base64: str
    device_id: Optional[str] = None
    photo_taken_at: Optional[datetime] = None


class MedicationConfirmResponse(BaseModel):
    log_id: UUID
    verification_id: UUID
    verification_status: str  # "pending" | "valid" | "invalid"
    streak_count: int
    message: str


class PhotoVerifyRequest(BaseModel):
    verification_id: UUID
    photo_base64: str


class PhotoVerifyResponse(BaseModel):
    is_valid: Optional[bool] = None
    confidence: float
    message: str
