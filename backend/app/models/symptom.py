import uuid
from datetime import datetime

from sqlalchemy import (
    Boolean, Column, Date, DateTime, Float, ForeignKey,
    Index, Integer, SmallInteger, Text, UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.core.database import Base


class SymptomLog(Base):
    __tablename__ = "symptom_logs"
    __table_args__ = (
        UniqueConstraint("patient_id", "logged_date", name="uq_symptom_patient_date"),
        Index("ix_symptom_patient_date", "patient_id", "logged_date"),
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    patient_id = Column(
        UUID(as_uuid=True),
        ForeignKey("patient_profiles.id", ondelete="CASCADE"),
        nullable=False,
    )
    logged_date = Column(Date, nullable=False)
    # Scales 1–5 (SmallInteger saves space; CHECK constraints enforced at app level)
    cough_scale = Column(SmallInteger, nullable=False, default=1)
    fever = Column(Boolean, nullable=False, default=False)
    fever_temperature = Column(Float, nullable=True)
    shortness_of_breath = Column(SmallInteger, nullable=False, default=1)
    night_sweats = Column(Boolean, nullable=False, default=False)
    appetite_scale = Column(SmallInteger, nullable=False, default=1)
    energy_scale = Column(SmallInteger, nullable=False, default=1)
    weight_kg = Column(Float, nullable=True)
    additional_notes = Column(Text, nullable=True)
    ai_assessment = Column(Text, nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)

    patient = relationship("PatientProfile", back_populates="symptom_logs")

    def __repr__(self) -> str:
        return f"<SymptomLog id={self.id} date={self.logged_date}>"
