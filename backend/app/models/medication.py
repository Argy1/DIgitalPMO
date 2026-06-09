import uuid
from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Index, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship

from app.core.database import Base
from app.models.enums import (
    fdc_type_enum,
    medication_status_enum,
    medication_type_enum,
    treatment_phase_enum,
)


class MedicationSchedule(Base):
    __tablename__ = "medication_schedules"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    patient_id = Column(
        UUID(as_uuid=True),
        ForeignKey("patient_profiles.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    phase = Column(treatment_phase_enum, nullable=False)
    medication_type = Column(medication_type_enum, nullable=True)
    fdc_type = Column(fdc_type_enum, nullable=True)
    # Jumlah tablet per dosis (berdasarkan berat badan pasien)
    # 30-37kg=2, 38-54kg=3, 55-70kg=4, >70kg=5
    tablet_count = Column(Integer, nullable=True)
    # Frekuensi per minggu: 7=setiap hari (fase intensif), 3=3x seminggu (fase lanjutan FDC)
    frequency_per_week = Column(Integer, nullable=False, default=7)
    # Hari-hari dalam seminggu untuk jadwal (1=Senin ... 7=Minggu)
    # Contoh fase lanjutan FDC: [1, 3, 5] = Senin, Rabu, Jumat
    schedule_days = Column(JSONB, nullable=True)
    # e.g. ["R", "H", "Z", "E"]
    medications = Column(JSONB, nullable=False, default=list)
    # e.g. ["07:00", "19:00"]
    schedule_times = Column(JSONB, nullable=False, default=list)
    reminder_before = Column(Integer, nullable=False, default=30)  # minutes
    is_active = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
    )

    patient = relationship("PatientProfile", back_populates="medication_schedules")
    medication_logs = relationship("MedicationLog", back_populates="schedule")

    def __repr__(self) -> str:
        return f"<MedicationSchedule id={self.id} phase={self.phase}>"


class MedicationLog(Base):
    __tablename__ = "medication_logs"
    __table_args__ = (
        Index("ix_medlog_patient_scheduled", "patient_id", "scheduled_time"),
        Index("ix_medlog_status", "status"),
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    patient_id = Column(
        UUID(as_uuid=True),
        ForeignKey("patient_profiles.id", ondelete="CASCADE"),
        nullable=False,
    )
    schedule_id = Column(
        UUID(as_uuid=True),
        ForeignKey("medication_schedules.id", ondelete="SET NULL"),
        nullable=True,
    )
    scheduled_time = Column(DateTime, nullable=False)
    confirmed_at = Column(DateTime, nullable=True)
    status = Column(medication_status_enum, nullable=False, default="pending")
    photo_url = Column(String(500), nullable=True)
    is_photo_verified = Column(Boolean, nullable=True)
    # FK to ai_photo_verifications — defined here (no circular issue on this side)
    ai_verification_id = Column(
        UUID(as_uuid=True),
        ForeignKey("ai_photo_verifications.id", ondelete="SET NULL"),
        nullable=True,
    )
    streak_count = Column(Integer, nullable=False, default=0)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)

    patient = relationship("PatientProfile", back_populates="medication_logs")
    schedule = relationship("MedicationSchedule", back_populates="medication_logs")
    ai_verification = relationship(
        "AIPhotoVerification",
        foreign_keys=[ai_verification_id],
        uselist=False,
    )
    side_effect_logs = relationship("SideEffectLog", back_populates="medication_log")

    def __repr__(self) -> str:
        return f"<MedicationLog id={self.id} status={self.status}>"
