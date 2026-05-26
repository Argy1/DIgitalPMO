import uuid
from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, Float, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship

from app.core.database import Base


class AIPhotoVerification(Base):
    """AI verification result for a medication photo.

    The FK back to medication_logs uses use_alter=True to break the circular
    dependency: medication_logs.ai_verification_id → ai_photo_verifications,
    and ai_photo_verifications.medication_log_id → medication_logs.
    SQLAlchemy emits the latter as an ALTER TABLE after both tables exist.
    """

    __tablename__ = "ai_photo_verifications"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    medication_log_id = Column(
        UUID(as_uuid=True),
        ForeignKey(
            "medication_logs.id",
            use_alter=True,
            name="fk_ai_photo_verif_medication_log",
            ondelete="SET NULL",
        ),
        nullable=True,
        index=True,
    )
    photo_url = Column(String(500), nullable=False)
    photo_taken_at = Column(DateTime, nullable=True)
    device_id = Column(String(200), nullable=True)
    ai_model = Column(String(100), nullable=True)
    ai_response_raw = Column(JSONB, nullable=True)
    is_valid = Column(Boolean, nullable=True)
    confidence_score = Column(Float, nullable=True)
    rejection_reason = Column(Text, nullable=True)
    processing_time = Column(Float, nullable=True)  # milliseconds
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)

    medication_log = relationship(
        "MedicationLog",
        foreign_keys=[medication_log_id],
        uselist=False,
    )

    def __repr__(self) -> str:
        return f"<AIPhotoVerification id={self.id} is_valid={self.is_valid}>"
