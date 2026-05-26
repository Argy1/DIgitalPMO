import uuid
from datetime import datetime

from sqlalchemy import Column, DateTime, ForeignKey, Index, String
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship

from app.core.database import Base


class AuditLog(Base):
    __tablename__ = "audit_logs"
    __table_args__ = (
        Index("ix_audit_user_created", "user_id", "created_at"),
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    # Dot-namespaced action string, e.g. "medication.confirm", "auth.login"
    action = Column(String(100), nullable=False, index=True)
    entity_type = Column(String(50), nullable=True)
    entity_id = Column(String(100), nullable=True)
    ip_address = Column(String(45), nullable=True)
    # Browser/app info: {"platform": "android", "app_version": "1.0.0"}
    device_info = Column(JSONB, nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow, index=True)

    user = relationship("User", back_populates="audit_logs")

    def __repr__(self) -> str:
        return f"<AuditLog id={self.id} action={self.action}>"
