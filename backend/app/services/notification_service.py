import logging
from datetime import datetime
from typing import Optional
from uuid import UUID

from sqlalchemy.orm import Session

from app.models.notification import Notification

logger = logging.getLogger(__name__)

_firebase_initialized = False
_firebase_module_available = False

try:
    import firebase_admin
    from firebase_admin import credentials, messaging

    _firebase_module_available = True
except ImportError:
    logger.warning("firebase_admin not installed. Push notifications will be disabled.")


def _init_firebase(credentials_path: str) -> bool:
    global _firebase_initialized
    if _firebase_initialized:
        return True
    if not _firebase_module_available:
        return False
    try:
        import os

        if not os.path.exists(credentials_path):
            logger.warning(
                "Firebase credentials not found at %s. Push notifications disabled.",
                credentials_path,
            )
            return False
        cred = credentials.Certificate(credentials_path)
        firebase_admin.initialize_app(cred)
        _firebase_initialized = True
        logger.info("Firebase Admin SDK initialized.")
        return True
    except Exception as e:
        logger.error("Failed to initialize Firebase: %s", e)
        return False


_DAYS_ID = ["Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu", "Minggu"]
_MILESTONES = [7, 14, 30, 60, 90, 120, 150, 180]
_GREETINGS = {
    "morning": "Selamat pagi",
    "afternoon": "Selamat siang",
    "evening": "Selamat sore",
    "night": "Selamat malam",
}


class NotificationService:
    def __init__(self):
        from app.core.config import get_settings

        settings = get_settings()
        _init_firebase(settings.FIREBASE_CREDENTIALS_PATH)

    # ── Push ──────────────────────────────────────────────────────────────────

    def send_push(
        self,
        fcm_token: str,
        title: str,
        body: str,
        data: Optional[dict] = None,
    ) -> bool:
        if not _firebase_initialized or not _firebase_module_available:
            logger.info(
                "[PUSH STUB] title='%s' body='%s' token='%s...'",
                title,
                body,
                fcm_token[:20],
            )
            return False
        try:
            message = messaging.Message(
                notification=messaging.Notification(title=title, body=body),
                token=fcm_token,
                data={str(k): str(v) for k, v in (data or {}).items()},
            )
            response = messaging.send(message)
            logger.info("Push notification sent: %s", response)
            return True
        except Exception as e:
            logger.error("Failed to send push notification: %s", e)
            return False

    # ── Persist ───────────────────────────────────────────────────────────────

    def create_notification(
        self,
        db: Session,
        patient_id: UUID,
        notification_type: str,
        title: str,
        body: str,
        data: Optional[dict] = None,
    ) -> Notification:
        notification = Notification(
            patient_id=patient_id,
            type=notification_type,
            title=title,
            body=body,
            data=data,
            is_sent=False,
            sent_at=None,
        )
        db.add(notification)
        db.commit()
        db.refresh(notification)
        return notification

    def send_and_save(
        self,
        db: Session,
        patient_id: UUID,
        notification_type: str,
        title: str,
        body: str,
        data: Optional[dict] = None,
    ) -> Notification:
        notification = self.create_notification(
            db, patient_id, notification_type, title, body, data
        )
        # Fetch FCM token via patient → user relationship
        from app.models.patient import PatientProfile

        patient = db.query(PatientProfile).filter(PatientProfile.id == patient_id).first()
        push_sent = False
        if patient and patient.user and patient.user.fcm_token:
            push_sent = self.send_push(patient.user.fcm_token, title, body, data)

        if push_sent:
            notification.is_sent = True
            notification.sent_at = datetime.utcnow()
            db.commit()

        return notification

    # ── Reminder text generation ──────────────────────────────────────────────

    def generate_medication_reminder_text(
        self,
        patient_name: str,
        streak: int,
        time_of_day: str = "morning",
    ) -> dict:
        """Return {title, body} with day-of-week / streak / milestone variations."""
        day_name = _DAYS_ID[datetime.now().weekday()]
        greeting = _GREETINGS.get(time_of_day, "Halo")
        first_name = patient_name.split()[0] if patient_name else "Pasien"

        # Milestone message
        if streak in _MILESTONES:
            title = f"Milestone {streak} Hari! Luar Biasa!"
            body = (
                f"{greeting}, {first_name}! Anda telah minum obat {streak} hari berturut-turut. "
                "Tetap semangat dan teruskan perjuangan Anda!"
            )
            return {"title": title, "body": body}

        # Streak-based variation
        if streak >= 30:
            title = "Waktunya Minum Obat TB!"
            body = (
                f"{greeting}, {first_name}! Hari {day_name} ini jangan lupa minum obat TB Anda. "
                f"Streak Anda sudah {streak} hari — terus pertahankan!"
            )
        elif streak >= 7:
            title = "Saatnya Minum Obat TB"
            body = (
                f"{greeting}, {first_name}! Sudah {streak} hari konsisten minum obat. "
                "Lanjutkan kebiasaan baik ini demi kesembuhan Anda."
            )
        elif streak == 0:
            title = "Jangan Lewatkan Obat Hari Ini!"
            body = (
                f"{greeting}, {first_name}! Hari {day_name} adalah kesempatan baru untuk "
                "memulai streak minum obat. Minum obat sekarang ya!"
            )
        else:
            title = "Waktunya Minum Obat TB!"
            body = (
                f"{greeting}, {first_name}! Saatnya minum obat TB Anda hari ini ({day_name}). "
                "Konsistensi adalah kunci kesembuhan TB."
            )

        return {"title": title, "body": body}


notification_service = NotificationService()
