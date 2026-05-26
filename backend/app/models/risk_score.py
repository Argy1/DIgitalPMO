import uuid
from datetime import datetime

from sqlalchemy import Column, DateTime, ForeignKey, Numeric, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship

from app.core.database import Base
from app.models.enums import risk_level_enum


class DropoutRiskScore(Base):
    __tablename__ = "dropout_risk_scores"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    patient_id = Column(
        UUID(as_uuid=True),
        ForeignKey("patient_profiles.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    calculated_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    # 0.0000 – 1.0000 composite score
    score = Column(Numeric(5, 4), nullable=False)
    risk_level = Column(risk_level_enum, nullable=False)
    # Human-readable contributing factors
    factors = Column(JSONB, nullable=False, default=list)
    ai_recommendation = Column(Text, nullable=True)
    action_taken = Column(String(200), nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)

    patient = relationship("PatientProfile", back_populates="dropout_risk_scores")

    def __repr__(self) -> str:
        return f"<DropoutRiskScore id={self.id} level={self.risk_level} score={self.score}>"
