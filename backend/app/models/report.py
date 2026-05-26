import uuid
from datetime import datetime

from sqlalchemy import Column, Date, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship

from app.core.database import Base


class MonthlyReport(Base):
    __tablename__ = "monthly_reports"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    patient_id = Column(
        UUID(as_uuid=True),
        ForeignKey("patient_profiles.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    # First day of the reported month, e.g. 2025-03-01
    report_month = Column(Date, nullable=False)
    total_scheduled = Column(Integer, nullable=False, default=0)
    confirmed_doses = Column(Integer, nullable=False, default=0)
    missed_doses = Column(Integer, nullable=False, default=0)
    late_doses = Column(Integer, nullable=False, default=0)
    # 0–100 percentage
    adherence_percentage = Column(Float, nullable=False, default=0.0)
    avg_cough_scale = Column(Float, nullable=True)
    avg_appetite_scale = Column(Float, nullable=True)
    avg_energy_scale = Column(Float, nullable=True)
    # e.g. {"Mual": 5, "Nyeri sendi": 2}
    side_effects_summary = Column(JSONB, nullable=True)
    ai_summary = Column(Text, nullable=True)
    # List of recommendation strings
    ai_recommendation = Column(JSONB, nullable=True)
    pdf_url = Column(String(500), nullable=True)
    generated_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)

    patient = relationship("PatientProfile", back_populates="monthly_reports")

    def __repr__(self) -> str:
        return f"<MonthlyReport id={self.id} month={self.report_month}>"
