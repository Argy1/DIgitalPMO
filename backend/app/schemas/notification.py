from datetime import datetime
from typing import Any, Dict, List, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class NotificationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    patient_id: UUID
    type: str
    title: str
    body: str
    data: Optional[Dict[str, Any]] = None
    is_sent: bool
    sent_at: Optional[datetime] = None
    is_read: bool
    read_at: Optional[datetime] = None
    scheduled_for: Optional[datetime] = None
    created_at: datetime


class RegisterTokenRequest(BaseModel):
    fcm_token: str


class FCMTokenUpdate(BaseModel):
    fcm_token: str


class MarkReadRequest(BaseModel):
    notification_ids: List[str]
