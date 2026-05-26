import uuid
from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.core.database import Base
from app.models.enums import user_role_enum


class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    full_name = Column(String(100), nullable=False)
    phone_number = Column(String(20), unique=True, nullable=False, index=True)
    email = Column(String(255), unique=True, nullable=True, index=True)
    password_hash = Column(String(255), nullable=True)
    role = Column(user_role_enum, nullable=False, default="patient")
    is_verified = Column(Boolean, nullable=False, default=False)
    verified_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    fcm_token = Column(String(500), nullable=True)
    is_active = Column(Boolean, nullable=False, default=True)
    # OTP fields — not in public API spec but required by auth flow
    otp_code = Column(String(6), nullable=True)
    otp_expires_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
    )

    # Self-referential: who verified this user
    verifier = relationship(
        "User",
        foreign_keys=[verified_by],
        remote_side="User.id",
        uselist=False,
    )

    # One-to-one with PatientProfile
    patient_profile = relationship(
        "PatientProfile",
        foreign_keys="PatientProfile.user_id",
        back_populates="user",
        uselist=False,
    )

    audit_logs = relationship("AuditLog", back_populates="user")
    support_tickets = relationship("SupportTicket", back_populates="user")

    def __repr__(self) -> str:
        return f"<User id={self.id} phone={self.phone_number} role={self.role}>"
