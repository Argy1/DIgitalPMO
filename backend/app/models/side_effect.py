import uuid
from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship

from app.core.database import Base
from app.models.enums import side_effect_severity_enum


class SideEffectLog(Base):
    __tablename__ = "side_effect_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    patient_id = Column(
        UUID(as_uuid=True),
        ForeignKey("patient_profiles.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    medication_log_id = Column(
        UUID(as_uuid=True),
        ForeignKey("medication_logs.id", ondelete="SET NULL"),
        nullable=True,
    )
    logged_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    # e.g. ["Mual", "Nyeri sendi", "Urine merah"]
    side_effects = Column(JSONB, nullable=False, default=list)
    severity = Column(side_effect_severity_enum, nullable=False)
    ai_response = Column(Text, nullable=True)
    is_emergency = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)

    patient = relationship("PatientProfile", back_populates="side_effect_logs")
    medication_log = relationship("MedicationLog", back_populates="side_effect_logs")

    def __repr__(self) -> str:
        return f"<SideEffectLog id={self.id} severity={self.severity}>"
