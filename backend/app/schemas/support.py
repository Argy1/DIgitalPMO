from datetime import datetime
from typing import Literal, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, field_validator


SupportCategory = Literal["bug", "feature", "account", "other"]
SupportStatus = Literal["open", "in_progress", "resolved", "closed"]

_CATEGORY_LABELS = {
    "bug": "Laporan Bug",
    "feature": "Saran Fitur",
    "account": "Masalah Akun",
    "other": "Lainnya",
}


class ContactSupportRequest(BaseModel):
    category: SupportCategory
    subject: str
    message: str

    @field_validator("subject")
    @classmethod
    def _check_subject(cls, v: str) -> str:
        v = v.strip()
        if len(v) < 5:
            raise ValueError("Subjek minimal 5 karakter.")
        if len(v) > 200:
            raise ValueError("Subjek maksimal 200 karakter.")
        return v

    @field_validator("message")
    @classmethod
    def _check_message(cls, v: str) -> str:
        v = v.strip()
        if len(v) < 20:
            raise ValueError("Pesan minimal 20 karakter.")
        if len(v) > 2000:
            raise ValueError("Pesan maksimal 2000 karakter.")
        return v


class SupportTicketResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    ticket_number: Optional[str]
    category: str
    subject: str
    message: str
    status: str
    admin_reply: Optional[str]
    created_at: datetime

    @property
    def category_label(self) -> str:
        return _CATEGORY_LABELS.get(self.category, self.category)
