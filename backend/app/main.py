import logging
import time
from contextlib import asynccontextmanager
from typing import Optional

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from starlette.concurrency import run_in_threadpool

from app.api.dependencies import limiter
from app.api.routes import auth, patients, medications, symptoms, side_effects, ai, reports, education, notifications, support
from app.core.config import get_settings
from app.core.scheduler import start_scheduler, stop_scheduler

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)
settings = get_settings()

# Paths excluded from DB audit logging (noisy / unauthenticated)
_AUDIT_SKIP_PREFIXES = ("/health", "/docs", "/redoc", "/openapi.json")


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting DigitalPMO API...")
    try:
        import app.models  # noqa: F401
        from app.core.database import create_tables
        create_tables()
        logger.info("DB tables ready.")
    except Exception as e:
        logger.error("Failed to create DB tables on startup: %s", e)
        logger.warning("Continuing without DB table creation (may already exist).")

    start_scheduler()
    yield

    stop_scheduler()
    logger.info("Shutting down DigitalPMO API.")


app = FastAPI(
    title="DigitalPMO API",
    description="Backend API untuk aplikasi kepatuhan pengobatan TB - DigitalPMO",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# ── Rate limiter ──────────────────────────────────────────────────────────────
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)

# ── CORS ──────────────────────────────────────────────────────────────────────
_DEV_ORIGINS = [
    "http://localhost",
    "http://localhost:3000",
    "http://localhost:8080",
    "http://127.0.0.1:3000",
]
_PROD_ORIGINS = [
    "https://digitalpmo.app",
    "https://www.digitalpmo.app",
    # Flutter/Capacitor mobile origins
    "capacitor://localhost",
    "ionic://localhost",
    "http://localhost",          # Flutter web dev
]

allowed_origins = (
    ["*"] if settings.ENVIRONMENT == "development" else _PROD_ORIGINS + _DEV_ORIGINS
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)


# ── Request timing ────────────────────────────────────────────────────────────
@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start = time.time()
    response = await call_next(request)
    response.headers["X-Process-Time"] = f"{time.time() - start:.4f}"
    return response


# ── Audit logging middleware ──────────────────────────────────────────────────

def _anonymize_ip(ip: Optional[str]) -> Optional[str]:
    """Zero the last octet of IPv4; last 2 groups of IPv6."""
    if not ip:
        return None
    if ":" in ip:
        parts = ip.split(":")
        return ":".join(parts[:-2] + ["0", "0"])
    parts = ip.split(".")
    if len(parts) == 4:
        return ".".join(parts[:-1] + ["0"])
    return ip


def _extract_bearer(request: Request) -> Optional[str]:
    auth_header = request.headers.get("Authorization", "")
    if auth_header.startswith("Bearer "):
        return auth_header[7:]
    return None


def _write_audit_log(
    action: str,
    user_id: Optional[str],
    ip: Optional[str],
    status_code: int,
    method: str,
    path: str,
    user_agent: str,
) -> None:
    """Sync function run in thread pool to persist an audit log entry."""
    try:
        from app.core.database import SessionLocal
        from app.models.audit_log import AuditLog

        db = SessionLocal()
        try:
            db.add(
                AuditLog(
                    user_id=user_id,
                    action=action,
                    entity_type="http_request",
                    entity_id=str(status_code),
                    ip_address=ip,
                    device_info={
                        "method": method,
                        "path": path,
                        "status_code": status_code,
                        "user_agent": user_agent[:200],
                    },
                )
            )
            db.commit()
        finally:
            db.close()
    except Exception as exc:
        logger.error("Audit log write failed: %s", exc)


@app.middleware("http")
async def audit_log_middleware(request: Request, call_next):
    start = time.time()
    response = await call_next(request)
    elapsed = time.time() - start

    path = request.url.path
    method = request.method
    status_code = response.status_code

    logger.info(
        "[AUDIT] %s %s status=%d time=%.4fs ua=%s",
        method, path, status_code, elapsed,
        request.headers.get("user-agent", "")[:80],
    )

    # Skip DB write for noisy / public endpoints
    if any(path.startswith(p) for p in _AUDIT_SKIP_PREFIXES):
        return response

    # Best-effort user ID extraction
    user_id: Optional[str] = None
    token = _extract_bearer(request)
    if token:
        try:
            from app.core.security import decode_token
            payload = decode_token(token)
            user_id = payload.get("sub")
        except Exception:
            pass

    raw_ip = request.headers.get("X-Forwarded-For", "").split(",")[0].strip()
    if not raw_ip and request.client:
        raw_ip = request.client.host
    anon_ip = _anonymize_ip(raw_ip or None)

    await run_in_threadpool(
        _write_audit_log,
        f"{method} {path}",
        user_id,
        anon_ip,
        status_code,
        method,
        path,
        request.headers.get("user-agent", ""),
    )
    return response


# ── Routers ───────────────────────────────────────────────────────────────────
app.include_router(auth.router)
app.include_router(patients.router)
app.include_router(medications.router)
app.include_router(symptoms.router)
app.include_router(side_effects.router)
app.include_router(ai.router)
app.include_router(reports.router)
app.include_router(education.router)
app.include_router(notifications.router)
app.include_router(support.router)


# ── Health check ──────────────────────────────────────────────────────────────
@app.get("/health", tags=["system"])
def health_check():
    try:
        from app.core.database import SessionLocal
        db = SessionLocal()
        db.execute(__import__("sqlalchemy").text("SELECT 1"))
        db.close()
        db_status = "connected"
    except Exception as e:
        logger.error("DB health check failed: %s", e)
        db_status = "disconnected"

    return {
        "status": "ok",
        "db": db_status,
        "version": "1.0.0",
        "environment": settings.ENVIRONMENT,
    }


# ── Error handlers ────────────────────────────────────────────────────────────
@app.exception_handler(404)
async def not_found_handler(request: Request, exc):
    return JSONResponse(status_code=404, content={"detail": "Not found"})


@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    logger.error(
        "Unhandled exception on %s %s: %s",
        request.method, request.url.path, exc, exc_info=True,
    )
    return JSONResponse(status_code=500, content={"detail": "Internal server error"})
