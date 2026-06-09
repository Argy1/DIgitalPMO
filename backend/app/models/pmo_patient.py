"""Model untuk relasi antara pegawai PMO dan pasien yang diawasinya."""
import uuid
from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.core.database import Base


class PMOPatient(Base):
    """
    Tabel junction antara user PMO dan patient_profiles.
    Satu pasien hanya bisa punya SATU PMO aktif (unique constraint).
    PMO bisa mengawasi banyak pasien.
    """
    __tablename__ = "pmo_patients"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # FK ke users (yang rolenya = 'pmo')
    pmo_user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    # FK ke patient_profiles
    patient_id = Column(
        UUID(as_uuid=True),
        ForeignKey("patient_profiles.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,  # SATU pasien hanya bisa punya SATU PMO aktif
        index=True,
    )

    # Metode linking: 'qr_code' atau 'phone_request'
    linked_via = Column(String(20), nullable=False, default="phone_request")

    is_active = Column(Boolean, nullable=False, default=True)
    linked_at = Column(DateTime, nullable=False, default=datetime.utcnow)

    # Relationships
    pmo_user = relationship("User", foreign_keys=[pmo_user_id])
    patient = relationship(
        "PatientProfile",
        foreign_keys=[patient_id],
        back_populates="pmo_link",
    )

    def __repr__(self):
        return f"<PMOPatient pmo={self.pmo_user_id} patient={self.patient_id}>"
