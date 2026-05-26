import uuid
from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.core.database import Base


class EducationLog(Base):
    """Tracks article delivery and read status per patient.

    content_category stored as VARCHAR to avoid ENUM migrations when
    categories change in the Flutter app.
    trigger_type stores which EducationTrigger caused delivery.
    """

    __tablename__ = "education_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    patient_id = Column(
        UUID(as_uuid=True),
        ForeignKey("patient_profiles.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    content_id = Column(String(100), nullable=False, index=True)
    content_category = Column(String(100), nullable=True)
    trigger_type = Column(String(100), nullable=True)
    delivered_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    is_read = Column(Boolean, nullable=False, default=False)
    read_at = Column(DateTime, nullable=True)

    patient = relationship("PatientProfile", back_populates="education_logs")

    def __repr__(self) -> str:
        return f"<EducationLog id={self.id} content_id={self.content_id} is_read={self.is_read}>"
