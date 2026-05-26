# Import every model so SQLAlchemy registers all mappers before create_tables()
# or alembic autogenerate runs.  Order matters: parent tables first.

from app.models.user import User  # noqa: F401
from app.models.patient import PatientProfile  # noqa: F401
from app.models.ai_photo_verification import AIPhotoVerification  # noqa: F401
from app.models.medication import MedicationSchedule, MedicationLog  # noqa: F401
from app.models.symptom import SymptomLog  # noqa: F401
from app.models.side_effect import SideEffectLog  # noqa: F401
from app.models.control import ControlSchedule  # noqa: F401
from app.models.education import EducationLog  # noqa: F401
from app.models.risk_score import DropoutRiskScore  # noqa: F401
from app.models.report import MonthlyReport  # noqa: F401
from app.models.notification import Notification  # noqa: F401
from app.models.audit_log import AuditLog  # noqa: F401

__all__ = [
    "User",
    "PatientProfile",
    "AIPhotoVerification",
    "MedicationSchedule",
    "MedicationLog",
    "SymptomLog",
    "SideEffectLog",
    "ControlSchedule",
    "EducationLog",
    "DropoutRiskScore",
    "MonthlyReport",
    "Notification",
    "AuditLog",
]
