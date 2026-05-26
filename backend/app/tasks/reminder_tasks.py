import logging
from datetime import date, datetime, timedelta

from app.tasks.celery_config import celery_app

logger = logging.getLogger(__name__)

_CONTROL_TYPE_LABEL = {
    "kontrol_1": "ke-1",
    "kontrol_2": "ke-2",
    "kontrol_3": "ke-3",
}


# ── Per-patient push tasks ─────────────────────────────────────────────────────

@celery_app.task(name="app.tasks.reminder_tasks.send_medication_reminder", bind=True, max_retries=3)
def send_medication_reminder(self, patient_id: str):
    """Send medication reminder push notification to a single patient."""
    try:
        from app.core.database import SessionLocal
        from app.models.medication import MedicationSchedule
        from app.models.patient import PatientProfile
        from app.services.notification_service import notification_service

        db = SessionLocal()
        try:
            patient = db.query(PatientProfile).filter(PatientProfile.id == patient_id).first()
            if not patient or not patient.user:
                logger.warning("Patient %s not found for medication reminder.", patient_id)
                return

            schedule = (
                db.query(MedicationSchedule)
                .filter(
                    MedicationSchedule.patient_id == patient_id,
                    MedicationSchedule.is_active == True,
                )
                .first()
            )
            streak = 0
            if schedule:
                from app.services.medication_service import medication_service
                streak = medication_service.calculate_streak(db, patient.id)

            text = notification_service.generate_medication_reminder_text(
                patient_name=patient.user.full_name or "",
                streak=streak,
                time_of_day="morning",
            )
            notification_service.send_and_save(
                db=db,
                patient_id=patient.id,
                notification_type="medication",
                title=text["title"],
                body=text["body"],
                data={"type": "medication_reminder", "patient_id": patient_id},
            )
            logger.info("Medication reminder sent to patient %s", patient_id)
        finally:
            db.close()
    except Exception as exc:
        logger.error("Failed to send medication reminder to %s: %s", patient_id, exc)
        raise self.retry(exc=exc, countdown=60)


@celery_app.task(name="app.tasks.reminder_tasks.send_followup_reminder", bind=True, max_retries=2)
def send_followup_reminder(self, patient_id: str, reminder_count: int = 1):
    """
    Follow-up medication reminder sent 30 min (count=1) and 60 min (count=2) after
    the initial reminder, unless the patient has already confirmed today's dose.
    """
    try:
        from app.core.database import SessionLocal
        from app.models.medication import MedicationLog
        from app.models.patient import PatientProfile
        from app.services.notification_service import notification_service

        db = SessionLocal()
        try:
            today = date.today()
            today_start = datetime.combine(today, datetime.min.time())
            today_end = datetime.combine(today, datetime.max.time())

            confirmed = (
                db.query(MedicationLog)
                .filter(
                    MedicationLog.patient_id == patient_id,
                    MedicationLog.scheduled_time >= today_start,
                    MedicationLog.scheduled_time <= today_end,
                    MedicationLog.status == "confirmed",
                )
                .first()
            )
            if confirmed:
                logger.info(
                    "Patient %s already confirmed today — skipping followup #%d.",
                    patient_id,
                    reminder_count,
                )
                return

            patient = (
                db.query(PatientProfile).filter(PatientProfile.id == patient_id).first()
            )
            if not patient:
                return

            if reminder_count == 1:
                title = "Pengingat Kedua: Minum Obat TB"
                body = (
                    "Kami perhatikan Anda belum mengkonfirmasi minum obat hari ini. "
                    "Silakan minum obat dan konfirmasi sekarang."
                )
                # Schedule a third check in another 30 min
                send_followup_reminder.apply_async(
                    args=[patient_id, 2], countdown=1800
                )
            else:
                title = "Pengingat Terakhir: Obat TB Anda"
                body = (
                    "Ini pengingat terakhir untuk hari ini. Jangan lewatkan dosis obat TB Anda. "
                    "Konsistensi sangat penting untuk kesembuhan."
                )

            notification_service.send_and_save(
                db=db,
                patient_id=patient.id,
                notification_type="medication",
                title=title,
                body=body,
                data={
                    "type": "followup_medication_reminder",
                    "patient_id": patient_id,
                    "reminder_count": str(reminder_count),
                },
            )
            logger.info(
                "Followup reminder #%d sent to patient %s", reminder_count, patient_id
            )
        finally:
            db.close()
    except Exception as exc:
        logger.error(
            "Failed to send followup reminder #%d to %s: %s",
            reminder_count,
            patient_id,
            exc,
        )
        raise self.retry(exc=exc, countdown=120)


@celery_app.task(name="app.tasks.reminder_tasks.send_control_reminder", bind=True, max_retries=3)
def send_control_reminder(self, patient_id: str, control_id: str, days_before: int):
    """Send a single control/checkup reminder push notification."""
    try:
        from app.core.database import SessionLocal
        from app.models.control import ControlSchedule
        from app.models.patient import PatientProfile
        from app.services.notification_service import notification_service

        db = SessionLocal()
        try:
            control = (
                db.query(ControlSchedule)
                .filter(ControlSchedule.id == control_id)
                .first()
            )
            if not control:
                logger.warning("Control schedule %s not found.", control_id)
                return

            patient = (
                db.query(PatientProfile)
                .filter(PatientProfile.id == patient_id)
                .first()
            )
            if not patient:
                logger.warning("Patient %s not found for control reminder.", patient_id)
                return

            label = _CONTROL_TYPE_LABEL.get(str(control.control_type), control.control_type)
            if days_before == 0:
                title = "Kontrol TB Hari Ini!"
                body = (
                    f"Anda memiliki jadwal kontrol {label} hari ini. "
                    "Jangan lupa datang ke faskes."
                )
            else:
                title = f"Pengingat Kontrol TB — {days_before} Hari Lagi"
                body = (
                    f"Kontrol TB {label} Anda dijadwalkan {days_before} hari lagi "
                    f"pada {control.scheduled_date.strftime('%d/%m/%Y')}."
                )

            notification_service.send_and_save(
                db=db,
                patient_id=patient.id,
                notification_type="control",
                title=title,
                body=body,
                data={
                    "type": "control_reminder",
                    "control_id": control_id,
                    "control_type": str(control.control_type),
                    "days_before": str(days_before),
                },
            )
            logger.info(
                "Control reminder sent: patient=%s control=%s days_before=%d",
                patient_id,
                control_id,
                days_before,
            )
        finally:
            db.close()
    except Exception as exc:
        logger.error("Failed to send control reminder: %s", exc)
        raise self.retry(exc=exc, countdown=60)


# ── Scheduled batch tasks ──────────────────────────────────────────────────────

@celery_app.task(name="app.tasks.reminder_tasks.send_daily_medication_reminders")
def send_daily_medication_reminders():
    """
    Runs every minute. Dispatches medication reminder for each active patient
    whose scheduled time is within ±1 minute of now, then schedules a followup
    in 30 minutes if they haven't confirmed.
    """
    try:
        from app.core.database import SessionLocal
        from app.models.medication import MedicationSchedule
        from app.models.patient import PatientProfile

        db = SessionLocal()
        dispatched = 0
        try:
            now = datetime.now()
            current_minutes = now.hour * 60 + now.minute

            active_patients = (
                db.query(PatientProfile)
                .filter(PatientProfile.is_treatment_complete == False)
                .all()
            )

            for patient in active_patients:
                schedule = (
                    db.query(MedicationSchedule)
                    .filter(
                        MedicationSchedule.patient_id == patient.id,
                        MedicationSchedule.is_active == True,
                    )
                    .first()
                )
                if not schedule or not schedule.schedule_times:
                    continue

                # schedule_times is JSONB list of "HH:MM" strings
                for time_str in schedule.schedule_times:
                    try:
                        h, m = map(int, str(time_str).split(":"))
                        sched_minutes = h * 60 + m
                        if abs(current_minutes - sched_minutes) <= 1:
                            send_medication_reminder.delay(str(patient.id))
                            # Schedule followup in 30 min
                            send_followup_reminder.apply_async(
                                args=[str(patient.id), 1], countdown=1800
                            )
                            dispatched += 1
                            break
                    except (ValueError, AttributeError):
                        continue

            logger.info(
                "Daily medication reminder check: %d reminders dispatched.", dispatched
            )
        finally:
            db.close()
    except Exception as e:
        logger.error("Failed daily medication reminder check: %s", e)


@celery_app.task(name="app.tasks.reminder_tasks.send_control_reminders")
def send_control_reminders():
    """
    Runs daily at 08:00. Sends H-3, H-1, H-0 reminders for upcoming control
    schedules. Tracks sent reminders via ControlSchedule.reminders_sent JSONB.
    """
    try:
        from app.core.database import SessionLocal
        from app.models.control import ControlSchedule
        from app.models.patient import PatientProfile

        db = SessionLocal()
        dispatched = 0
        try:
            today = date.today()
            # Look at schedules within the next 3 days (plus today)
            lookahead = today + timedelta(days=3)

            controls = (
                db.query(ControlSchedule)
                .filter(
                    ControlSchedule.scheduled_date >= today,
                    ControlSchedule.scheduled_date <= lookahead,
                    ControlSchedule.is_completed == False,
                )
                .all()
            )

            for control in controls:
                days_until = (control.scheduled_date - today).days
                if days_until not in (0, 1, 3):
                    continue

                reminder_key = {0: "h0", 1: "h1", 3: "h3"}[days_until]
                reminders_sent = control.reminders_sent or {}
                if reminders_sent.get(reminder_key):
                    continue  # already sent

                send_control_reminder.delay(
                    str(control.patient_id),
                    str(control.id),
                    days_until,
                )
                # Mark as sent immediately to avoid duplicate dispatch
                control.reminders_sent = {**reminders_sent, reminder_key: True}
                dispatched += 1

            db.commit()
            logger.info("Control reminder check: %d reminders dispatched.", dispatched)
        finally:
            db.close()
    except Exception as e:
        logger.error("Failed control reminder check: %s", e)
