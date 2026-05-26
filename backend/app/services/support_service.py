import logging
import random
import string
from datetime import date

from sqlalchemy.orm import Session

from app.models.support import SupportTicket
from app.schemas.support import ContactSupportRequest

logger = logging.getLogger(__name__)


def _generate_ticket_number() -> str:
    """Generate a human-readable ticket number like PMO-20250519-A3X7."""
    today = date.today().strftime("%Y%m%d")
    suffix = "".join(random.choices(string.ascii_uppercase + string.digits, k=4))
    return f"PMO-{today}-{suffix}"


class SupportService:
    def create_ticket(
        self,
        db: Session,
        user_id: str | None,
        body: ContactSupportRequest,
    ) -> SupportTicket:
        ticket = SupportTicket(
            user_id=user_id,
            category=body.category,
            subject=body.subject.strip(),
            message=body.message.strip(),
            status="open",
            ticket_number=_generate_ticket_number(),
        )
        db.add(ticket)
        db.commit()
        db.refresh(ticket)
        logger.info(
            "Support ticket %s created by user %s (category=%s)",
            ticket.ticket_number,
            user_id,
            ticket.category,
        )
        return ticket

    def list_user_tickets(
        self,
        db: Session,
        user_id: str,
        skip: int = 0,
        limit: int = 20,
    ) -> list[SupportTicket]:
        return (
            db.query(SupportTicket)
            .filter(SupportTicket.user_id == user_id)
            .order_by(SupportTicket.created_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )


support_service = SupportService()
