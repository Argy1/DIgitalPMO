from datetime import datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class SideEffectLogCreate(BaseModel):
    side_effects: List[str] = Field(..., min_length=1)
    severity: str
    ai_response: Optional[str] = None
    is_emergency: bool = False


class SideEffectLogResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    patient_id: UUID
    medication_log_id: Optional[UUID] = None
    logged_at: datetime
    side_effects: List[str]
    severity: str
    ai_response: Optional[str] = None
    is_emergency: bool
    created_at: datetime
