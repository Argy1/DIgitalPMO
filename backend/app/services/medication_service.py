import logging
from calendar import monthrange
from datetime import date, datetime, timedelta
from typing import List, Optional
from uuid import UUID

from sqlalchemy.orm import Session

from app.core.database import SessionLocal
from app.core.exceptions import ConflictException, NotFoundException
from app.models.ai_photo_verification import AIPhotoVerification
from app.models.medication import MedicationLog, MedicationSchedule
from app.schemas.medication import MedicationLogCreate

logger = logging.getLogger(__name__)


class MedicationService:
    def get_today_status(self, db: Session, patient_id: UUID) -> dict:
        today = date.today()
        today_start = datetime.combine(today, datetime.min.time())
        today_end = datetime.combine(today, datetime.max.time())

        log: Optional[MedicationLog] = (
            db.query(MedicationLog)
            .filter(
                MedicationLog.patient_id == patient_id,
                MedicationLog.scheduled_time >= today_start,
                MedicationLog.scheduled_time <= today_end,
                MedicationLog.status == "confirmed",
            )
            .first()
        )

        schedule: Optional[MedicationSchedule] = (
            db.query(MedicationSchedule)
            .filter(
                MedicationSchedule.patient_id == patient_id,
                MedicationSchedule.is_active == True,
            )
            .first()
        )

        streak = self.calculate_streak(db, patient_id)
        first_schedule_time = (
            schedule.schedule_times[0] if schedule and schedule.schedule_times else None
        )

        return {
            "is_taken": log is not None,
            "confirmed_at": log.confirmed_at.isoformat() if log and log.confirmed_at else None,
            "streak": streak,
            "schedule_time": first_schedule_time,
            "status": log.status if log else "pending",
        }

    def confirm_medication(
        self, db: Session, patient_id: UUID, log_data: MedicationLogCreate
    ) -> MedicationLog:
        today = date.today()
        today_start = datetime.combine(today, datetime.min.time())
        today_end = datetime.combine(today, datetime.max.time())

        existing = (
            db.query(MedicationLog)
            .filter(
                MedicationLog.patient_id == patient_id,
                MedicationLog.scheduled_time >= today_start,
                MedicationLog.scheduled_time <= today_end,
                MedicationLog.status == "confirmed",
            )
            .first()
        )
        if existing:
            raise ConflictException(detail="Obat untuk hari ini sudah dikonfirmasi sebelumnya.")

        now = datetime.utcnow()
        streak = self.calculate_streak(db, patient_id) + 1

        log = MedicationLog(
            patient_id=patient_id,
            scheduled_time=log_data.scheduled_time or now,
            confirmed_at=now,
            status="confirmed",
            photo_url=log_data.photo_url,
            notes=log_data.notes,
            streak_count=streak,
        )
        db.add(log)
        db.commit()
        db.refresh(log)
        logger.info("Medication confirmed for patient %s, streak=%d", patient_id, streak)
        return log

    def skip_medication(
        self, db: Session, patient_id: UUID, log_data: MedicationLogCreate
    ) -> MedicationLog:
        now = datetime.utcnow()
        log = MedicationLog(
            patient_id=patient_id,
            scheduled_time=log_data.scheduled_time or now,
            status="skipped",
            notes=log_data.notes,
            streak_count=0,
        )
        db.add(log)
        db.commit()
        db.refresh(log)
        logger.info("Medication skipped for patient %s", patient_id)
        return log

    def calculate_streak(self, db: Session, patient_id: UUID) -> int:
        streak = 0
        check_date = date.today() - timedelta(days=1)

        for _ in range(365):
            day_start = datetime.combine(check_date, datetime.min.time())
            day_end = datetime.combine(check_date, datetime.max.time())
            confirmed = (
                db.query(MedicationLog)
                .filter(
                    MedicationLog.patient_id == patient_id,
                    MedicationLog.scheduled_time >= day_start,
                    MedicationLog.scheduled_time <= day_end,
                    MedicationLog.status == "confirmed",
                )
                .first()
            )
            if confirmed:
                streak += 1
                check_date -= timedelta(days=1)
            else:
                break

        return streak

    def calculate_adherence(
        self, db: Session, patient_id: UUID, days: int = 30
    ) -> float:
        end_dt = datetime.utcnow()
        start_dt = end_dt - timedelta(days=days)
        total = (
            db.query(MedicationLog)
            .filter(
                MedicationLog.patient_id == patient_id,
                MedicationLog.scheduled_time >= start_dt,
                MedicationLog.scheduled_time <= end_dt,
            )
            .count()
        )
        if total == 0:
            return 0.0
        confirmed = (
            db.query(MedicationLog)
            .filter(
                MedicationLog.patient_id == patient_id,
                MedicationLog.scheduled_time >= start_dt,
                MedicationLog.scheduled_time <= end_dt,
                MedicationLog.status == "confirmed",
            )
            .count()
        )
        return confirmed / total

    def get_history(
        self, db: Session, patient_id: UUID, days: int = 30
    ) -> List[MedicationLog]:
        start_dt = datetime.utcnow() - timedelta(days=days)
        return (
            db.query(MedicationLog)
            .filter(
                MedicationLog.patient_id == patient_id,
                MedicationLog.scheduled_time >= start_dt,
            )
            .order_by(MedicationLog.scheduled_time.desc())
            .all()
        )

    def get_history_by_month(
        self, db: Session, patient_id: UUID, year: int, month: int
    ) -> List[MedicationLog]:
        _, last_day = monthrange(year, month)
        start_dt = datetime(year, month, 1)
        end_dt = datetime(year, month, last_day, 23, 59, 59)
        return (
            db.query(MedicationLog)
            .filter(
                MedicationLog.patient_id == patient_id,
                MedicationLog.scheduled_time >= start_dt,
                MedicationLog.scheduled_time <= end_dt,
            )
            .order_by(MedicationLog.scheduled_time.desc())
            .all()
        )

    # ── Photo-verified confirmation flow ─────────────────────────────────────

    def confirm_with_photo(
        self,
        db: Session,
        patient_id: UUID,
        schedule_id: UUID,
        photo_url: str,
        device_id: Optional[str] = None,
        photo_taken_at: Optional[datetime] = None,
    ) -> tuple[MedicationLog, AIPhotoVerification]:
        """Create a confirmed medication log + pending AI verification record."""
        schedule = (
            db.query(MedicationSchedule)
            .filter(
                MedicationSchedule.id == schedule_id,
                MedicationSchedule.patient_id == patient_id,
            )
            .first()
        )
        if not schedule:
            raise NotFoundException(detail="Jadwal obat tidak ditemukan untuk pasien ini.")

        today = date.today()
        today_start = datetime.combine(today, datetime.min.time())
        today_end = datetime.combine(today, datetime.max.time())
        existing = (
            db.query(MedicationLog)
            .filter(
                MedicationLog.patient_id == patient_id,
                MedicationLog.scheduled_time >= today_start,
                MedicationLog.scheduled_time <= today_end,
                MedicationLog.status == "confirmed",
            )
            .first()
        )
        if existing:
            raise ConflictException(detail="Obat untuk hari ini sudah dikonfirmasi sebelumnya.")

        now = datetime.utcnow()
        streak = self.calculate_streak(db, patient_id) + 1

        verification = AIPhotoVerification(
            photo_url=photo_url,
            photo_taken_at=photo_taken_at,
            device_id=device_id,
            is_valid=None,  # pending
        )
        db.add(verification)
        db.flush()

        log = MedicationLog(
            patient_id=patient_id,
            schedule_id=schedule_id,
            scheduled_time=now,
            confirmed_at=now,
            status="confirmed",
            photo_url=photo_url,
            ai_verification_id=verification.id,
            streak_count=streak,
        )
        db.add(log)
        db.flush()

        verification.medication_log_id = log.id
        db.commit()
        db.refresh(log)
        db.refresh(verification)
        logger.info(
            "Medication confirmed w/ photo for patient %s, log=%s, streak=%d",
            patient_id, log.id, streak,
        )
        return log, verification

    def apply_verification(
        self, db: Session, verification_id: UUID, photo_base64: str
    ) -> AIPhotoVerification:
        """Run AI photo verification and persist the result (uses given session)."""
        from app.services.ai_service import ai_service

        verification = (
            db.query(AIPhotoVerification)
            .filter(AIPhotoVerification.id == verification_id)
            .first()
        )
        if not verification:
            raise NotFoundException(detail="Data verifikasi foto tidak ditemukan.")

        result = ai_service.verify_medication_photo(photo_base64)
        verification.is_valid = result["is_valid"]
        verification.confidence_score = result["confidence"]
        verification.ai_response_raw = result["raw"]
        verification.rejection_reason = result["rejection_reason"]
        verification.processing_time = result["processing_time_ms"]
        verification.ai_model = result["model"]

        if verification.medication_log_id:
            log = (
                db.query(MedicationLog)
                .filter(MedicationLog.id == verification.medication_log_id)
                .first()
            )
            if log:
                log.is_photo_verified = result["is_valid"]

        db.commit()
        db.refresh(verification)
        logger.info(
            "Verification %s done: is_valid=%s confidence=%s",
            verification_id, result["is_valid"], result["confidence"],
        )
        return verification

    def run_photo_verification(self, verification_id: UUID, photo_base64: str) -> None:
        """Background-task entry point — opens its own DB session."""
        db = SessionLocal()
        try:
            self.apply_verification(db, verification_id, photo_base64)
        except Exception as exc:  # noqa: BLE001 - background task must not crash silently
            logger.error("Background photo verification failed: %s", exc)
        finally:
            db.close()


medication_service = MedicationService()
