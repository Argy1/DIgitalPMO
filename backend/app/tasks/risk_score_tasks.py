import logging

from app.tasks.celery_config import celery_app

logger = logging.getLogger(__name__)


@celery_app.task(name="app.tasks.risk_score_tasks.calculate_risk_scores")
def calculate_risk_scores():
    """Calculate dropout risk scores for all active patients and send alerts."""
    try:
        from app.core.database import SessionLocal
        from app.models.patient import PatientProfile
        from app.services.notification_service import notification_service
        from app.services.risk_score_service import risk_score_service

        db = SessionLocal()
        processed = 0
        critical_count = 0

        try:
            active_patients = (
                db.query(PatientProfile)
                .filter(PatientProfile.is_treatment_complete == False)
                .all()
            )

            for patient in active_patients:
                try:
                    risk_score = risk_score_service.calculate(db, patient.id)
                    processed += 1

                    if risk_score.risk_level == "critical":
                        critical_count += 1
                        notification_service.send_and_save(
                            db=db,
                            patient_id=patient.id,
                            notification_type="ai",
                            title="Peringatan: Risiko Kritis Terdeteksi",
                            body=(
                                "Sistem mendeteksi risiko kritis pada pengobatan TB Anda. "
                                "Segera hubungi dokter atau petugas kesehatan Anda."
                            ),
                            data={
                                "type": "risk_alert",
                                "risk_level": "critical",
                                "patient_id": str(patient.id),
                            },
                        )
                    elif risk_score.risk_level == "high":
                        notification_service.send_and_save(
                            db=db,
                            patient_id=patient.id,
                            notification_type="ai",
                            title="Perhatian: Risiko Tinggi",
                            body=(
                                "Tingkat risiko Anda tinggi. "
                                "Hubungi PMO atau dokter untuk evaluasi."
                            ),
                            data={
                                "type": "risk_alert",
                                "risk_level": "high",
                                "patient_id": str(patient.id),
                            },
                        )
                except Exception as e:
                    logger.error(
                        "Failed to calculate risk score for patient %s: %s", patient.id, e
                    )

            logger.info(
                "Risk score calculation complete: %d processed, %d critical.",
                processed,
                critical_count,
            )
        finally:
            db.close()
    except Exception as e:
        logger.error("Failed to run calculate_risk_scores task: %s", e)


@celery_app.task(name="app.tasks.risk_score_tasks.calculate_weekly_risk_scores")
def calculate_weekly_risk_scores():
    """Weekly Sunday 00:00 task — calculate risk scores for all patients."""
    logger.info("Starting weekly risk score calculation.")
    calculate_risk_scores.delay()
    logger.info("Weekly risk score task dispatched.")


# Keep for backwards compatibility with any existing beat schedules
@celery_app.task(name="app.tasks.risk_score_tasks.daily_risk_check")
def daily_risk_check():
    """Daily risk check — delegates to calculate_risk_scores."""
    calculate_risk_scores.delay()
