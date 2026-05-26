import uuid
from datetime import datetime

from sqlalchemy import Boolean, Column, Date, DateTime, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship

from app.core.database import Base
from app.models.enums import control_type_enum


class ControlSchedule(Base):
    __tablename__ = "control_schedules"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    patient_id = Column(
        UUID(as_uuid=True),
        ForeignKey("patient_profiles.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    scheduled_date = Column(Date, nullable=False)
    control_type = Column(control_type_enum, nullable=False)
    faskes_name = Column(String(200), nullable=True)
    notes = Column(Text, nullable=True)
    # e.g. {"h3": true, "h1": false, "h0": false}
    reminders_sent = Column(JSONB, nullable=False, default=dict)
    is_completed = Column(Boolean, nullable=False, default=False)
    completed_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
    )

    patient = relationship("PatientProfile", back_populates="control_schedules")

    def __repr__(self) -> str:
        return f"<ControlSchedule id={self.id} type={self.control_type} date={self.scheduled_date}>"
