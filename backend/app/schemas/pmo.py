from datetime import datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel


class PMOLinkRequest(BaseModel):
    patient_phone: str


class PMOQRLinkRequest(BaseModel):
    qr_token: str


class PMOLinkRequestCreated(BaseModel):
    link_request_id: str
    message: str
    expires_in_hours: int = 24


class PMOLinkResponse(BaseModel):
    pmo_patient_id: UUID
    linked_via: str
    linked_at: datetime
    patient_id: UUID
    patient_name: str
    message: str


class PMOPatientSummary(BaseModel):
    patient_id: UUID
    patient_name: str
    patient_phone: str
    tb_type_display: str
    current_phase: str
    treatment_day: int
    today_medication_status: str  # confirmed | pending | missed | no_schedule
    adherence_last_30_days: float
    current_streak: int
    risk_level: str
    last_confirmed_at: Optional[datetime] = None


class PMODashboard(BaseModel):
    total_patients: int
    missed_today: int
    patients: List[PMOPatientSummary]


class PMOQRToken(BaseModel):
    qr_token: str
    expires_at: datetime
