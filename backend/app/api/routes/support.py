import logging
from typing import Optional

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.api.dependencies import get_current_user, get_db
from app.models.user import User
from app.schemas.support import ContactSupportRequest, SupportTicketResponse
from app.services.support_service import support_service

router = APIRouter(prefix="/api/v1/support", tags=["support"])
logger = logging.getLogger(__name__)


@router.post(
    "/contact",
    response_model=SupportTicketResponse,
    status_code=status.HTTP_201_CREATED,
)
def contact_support(
    body: ContactSupportRequest,
    current_user: Optional[User] = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Submit a support ticket. Requires authentication."""
    ticket = support_service.create_ticket(
        db,
        user_id=str(current_user.id) if current_user else None,
        body=body,
    )
    return ticket


@router.get("/tickets", response_model=list[SupportTicketResponse])
def get_my_tickets(
    skip: int = 0,
    limit: int = 20,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get current user's support ticket history."""
    return support_service.list_user_tickets(
        db, str(current_user.id), skip=skip, limit=limit
    )
