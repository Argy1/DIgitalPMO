import uuid
from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Index, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship

from app.core.database import Base
from app.models.enums import notification_type_enum


class Notification(Base):
    __tablename__ = "notifications"
    __table_args__ = (
        Index("ix_notif_patient_sent", "patient_id", "is_sent"),
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    patient_id = Column(
        UUID(as_uuid=True),
        ForeignKey("patient_profiles.id", ondelete="CASCADE"),
        nullable=False,
    )
    type = Column(notification_type_enum, nullable=False)
    title = Column(String(200), nullable=False)
    body = Column(Text, nullable=False)
    # Extra payload forwarded to FCM data field
    data = Column(JSONB, nullable=True)
    is_sent = Column(Boolean, nullable=False, default=False)
    sent_at = Column(DateTime, nullable=True)
    is_read = Column(Boolean, nullable=False, default=False)
    read_at = Column(DateTime, nullable=True)
    # For scheduled notifications (reminders)
    scheduled_for = Column(DateTime, nullable=True, index=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)

    patient = relationship("PatientProfile", back_populates="notifications")

    def __repr__(self) -> str:
        return f"<Notification id={self.id} type={self.type} is_read={self.is_read}>"
