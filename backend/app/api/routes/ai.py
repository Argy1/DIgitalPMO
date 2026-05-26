import json
import logging
from typing import Any, List

from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.api.dependencies import get_current_patient, get_current_user, get_db, limiter
from app.core.exceptions import NotFoundException
from app.core.redis_client import redis_client
from app.models.patient import PatientProfile
from app.models.user import User
from app.services.ai_service import ai_service
from app.services.report_service import report_service
from app.services.risk_score_service import risk_score_service

router = APIRouter(prefix="/api/v1/ai", tags=["ai"])
logger = logging.getLogger(__name__)

_CHAT_TTL = 86400          # 24 hours
_SUMMARY_TTL = 86400       # 24 hours
_CHAT_MAX_TURNS = 50       # keep the last N messages


# ── Request models ────────────────────────────────────────────────────────────

class ChatRequest(BaseModel):
    message: str
    conversation_history: List[dict] = []
    patient_context: dict = {}


class SymptomAssessRequest(BaseModel):
    cough_scale: int
    breath_scale: int
    appetite_scale: int
    energy_scale: int
    has_fever: bool = False
    fever_temp: float = None
    has_night_sweats: bool = False
    weight_kg: float = None
    notes: str = None


class GenerateEducationRequest(BaseModel):
    trigger_type: str
    patient_data: dict = {}


# ── Redis chat history helpers ────────────────────────────────────────────────

def _chat_key(user_id) -> str:
    return f"chat_history:{user_id}"


def _load_chat_history(user_id) -> list:
    raw = redis_client.get(_chat_key(user_id))
    return json.loads(raw) if raw else []


def _append_chat_history(user_id, user_msg: str, assistant_msg: str) -> None:
    history = _load_chat_history(user_id)
    history.append({"role": "user", "content": user_msg})
    history.append({"role": "assistant", "content": assistant_msg})
    redis_client.setex(
        _chat_key(user_id), _CHAT_TTL, json.dumps(history[-_CHAT_MAX_TURNS:])
    )


# ── POST /chat (streaming) ────────────────────────────────────────────────────

@router.post("/chat")
@limiter.limit("30/minute")
def chat_with_ai(
    request: Request,
    body: ChatRequest,
    current_user: User = Depends(get_current_user),
):
    """Stream a chat response from the TB AI assistant."""
    system_prompt = ai_service.build_chat_system_prompt(
        current_user.full_name, body.patient_context
    )
    user_id = current_user.id

    def event_stream():
        chunks: list[str] = []
        for text in ai_service.chat_stream(
            body.message, body.conversation_history, system_prompt
        ):
            chunks.append(text)
            yield text
        full_response = "".join(chunks)
        try:
            _append_chat_history(user_id, body.message, full_response)
        except Exception as exc:  # noqa: BLE001 - persistence must not break the stream
            logger.error("Failed to persist chat history: %s", exc)

    logger.info("AI chat (stream) request from user %s", user_id)
    return StreamingResponse(event_stream(), media_type="text/plain; charset=utf-8")


@router.get("/chat-history")
def get_chat_history(current_user: User = Depends(get_current_user)) -> dict[str, Any]:
    """Return the session chat history (Redis, 24h TTL)."""
    history = _load_chat_history(current_user.id)
    return {"items": history, "total": len(history)}


# ── POST /assess-symptoms ─────────────────────────────────────────────────────

@router.post("/assess-symptoms")
def assess_symptoms(
    body: SymptomAssessRequest,
    current_user: User = Depends(get_current_user),
) -> dict[str, Any]:
    """Get an AI assessment for reported symptoms."""
    assessment = ai_service.assess_symptoms(body.model_dump())
    return {"assessment": assessment}


# ── POST /analyze-risk ────────────────────────────────────────────────────────

@router.post("/analyze-risk")
def analyze_risk(
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    """Calculate and store the dropout risk score (also run weekly by Celery)."""
    risk_score = risk_score_service.calculate(db, current_patient.id)
    return {
        "risk_level": risk_score.risk_level,
        "score": float(risk_score.score),
        "factors": risk_score.factors,
        "ai_recommendation": risk_score.ai_recommendation,
        "calculated_at": risk_score.calculated_at.isoformat(),
    }


# ── POST /generate-education ──────────────────────────────────────────────────

@router.post("/generate-education")
def generate_education(
    body: GenerateEducationRequest,
    current_user: User = Depends(get_current_user),
) -> dict[str, Any]:
    """Generate contextual TB education content based on a trigger."""
    return ai_service.generate_education_content(body.trigger_type, body.patient_data)


# ── GET /monthly-summary/{year}/{month} ───────────────────────────────────────

@router.get("/monthly-summary/{year}/{month}")
def monthly_summary(
    year: int,
    month: int,
    current_patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    """Generate (and cache for 24h) an AI summary for a given month's report."""
    if not (1 <= month <= 12):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Bulan harus antara 1 dan 12.",
        )

    cache_key = f"monthly_summary:{current_patient.id}:{year}-{month:02d}"
    cached = redis_client.get(cache_key)
    if cached:
        result = json.loads(cached)
        result["cached"] = True
        return result

    report_month = f"{year}-{month:02d}"
    try:
        report = report_service.get_report(db, current_patient.id, report_month)
    except NotFoundException:
        report = report_service.generate_report(db, current_patient.id, report_month)

    result = {
        "month": report_month,
        "ai_summary": report.ai_summary,
        "ai_recommendation": report.ai_recommendation,
        "adherence_percentage": report.adherence_percentage,
        "cached": False,
    }
    redis_client.setex(cache_key, _SUMMARY_TTL, json.dumps(result))
    return result
