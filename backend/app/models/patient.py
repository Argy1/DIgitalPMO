import uuid
from datetime import datetime

from sqlalchemy import Boolean, Column, Date, DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship

from app.core.database import Base
from app.core.security import EncryptedString
from app.models.enums import (
    fdc_type_enum,
    gender_enum,
    medication_type_enum,
    tb_category_enum,
    tb_ro_type_enum,
    tb_so_type_enum,
    treatment_phase_enum,
)


class PatientProfile(Base):
    __tablename__ = "patient_profiles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True,
    )
    date_of_birth = Column(Date, nullable=False)
    gender = Column(gender_enum, nullable=False)
    address = Column(EncryptedString, nullable=True)
    faskes_name = Column(String(200), nullable=False)
    doctor_name = Column(String(100), nullable=False)

    # Klasifikasi TB baru
    tb_category = Column(tb_category_enum, nullable=False, default="SO")
    tb_so_type = Column(tb_so_type_enum, nullable=True)   # diisi jika SO
    tb_ro_type = Column(tb_ro_type_enum, nullable=True)   # diisi jika RO

    treatment_start_date = Column(Date, nullable=False)
    current_phase = Column(treatment_phase_enum, nullable=False, default="intensive")
    phase_updated_at = Column(DateTime, nullable=True)

    # Durasi pengobatan - diisi MANUAL oleh dokter (bukan auto-calculate)
    treatment_duration_days = Column(Integer, nullable=True)  # misal: 180, 270, dll
    treatment_end_date = Column(Date, nullable=True)  # auto-calc dari start+duration

    # Jenis obat
    medication_type = Column(medication_type_enum, nullable=True)  # FDC atau Kombinasi
    fdc_type = Column(fdc_type_enum, nullable=True)  # jika FDC: FDC atau Kombipak
    # Jika Kombinasi/Khusus: daftar obat yang dipilih dokter
    custom_medications = Column(JSONB, nullable=True)  # ["R", "H", "Z", "E"] subset
    weight_kg = Column(Float, nullable=True)
    is_treatment_complete = Column(Boolean, nullable=False, default=False)
    is_hospitalized = Column(Boolean, nullable=False, default=False)
    is_pregnant = Column(Boolean, nullable=False, default=False)
    data_confirmed_by_patient = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
    )

    user = relationship("User", foreign_keys=[user_id], back_populates="patient_profile")
    medication_schedules = relationship("MedicationSchedule", back_populates="patient")
    medication_logs = relationship("MedicationLog", back_populates="patient")
    symptom_logs = relationship("SymptomLog", back_populates="patient")
    side_effect_logs = relationship("SideEffectLog", back_populates="patient")
    control_schedules = relationship("ControlSchedule", back_populates="patient")
    education_logs = relationship("EducationLog", back_populates="patient")
    dropout_risk_scores = relationship("DropoutRiskScore", back_populates="patient")
    monthly_reports = relationship("MonthlyReport", back_populates="patient")
    notifications = relationship("Notification", back_populates="patient")
    pmo_link = relationship(
        "PMOPatient",
        foreign_keys="PMOPatient.patient_id",
        uselist=False,
        cascade="all, delete-orphan",
    )

    def __repr__(self) -> str:
        return f"<PatientProfile id={self.id} user_id={self.user_id}>"
