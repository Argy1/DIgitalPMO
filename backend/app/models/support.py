import uuid
from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, Enum, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.core.database import Base


class SupportTicket(Base):
    __tablename__ = "support_tickets"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)

    category = Column(
        Enum("bug", "feature", "account", "other", name="support_category_enum"),
        nullable=False,
        default="other",
    )
    subject = Column(String(200), nullable=False)
    message = Column(Text, nullable=False)
    status = Column(
        Enum("open", "in_progress", "resolved", "closed", name="support_status_enum"),
        nullable=False,
        default="open",
    )
    admin_reply = Column(Text, nullable=True)
    ticket_number = Column(String(20), unique=True, nullable=True)

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    user = relationship("User", back_populates="support_tickets", lazy="select")
