import logging
from datetime import datetime

from app.tasks.celery_config import celery_app

logger = logging.getLogger(__name__)


@celery_app.task(name="app.tasks.report_tasks.generate_monthly_reports")
def generate_monthly_reports():
    """Generate monthly reports for all patients for the previous month.
    Should be run on the 1st of each month.
    """
    try:
        from app.core.database import SessionLocal
        from app.models.patient import PatientProfile
        from app.services.report_service import report_service

        now = datetime.utcnow()
        # Generate report for previous month
        if now.month == 1:
            prev_year = now.year - 1
            prev_month = 12
        else:
            prev_year = now.year
            prev_month = now.month - 1

        report_month = f"{prev_year}-{prev_month:02d}"
        db = SessionLocal()
        generated = 0
        failed = 0

        try:
            active_patients = (
                db.query(PatientProfile)
                .filter(PatientProfile.is_treatment_complete == False)
                .all()
            )

            for patient in active_patients:
                try:
                    report_service.generate_report(db, patient.id, report_month)
                    generated += 1
                except Exception as e:
                    logger.error(
                        f"Failed to generate report for patient {patient.id}, "
                        f"month={report_month}: {e}"
                    )
                    failed += 1

            logger.info(
                f"Monthly report generation complete for {report_month}: "
                f"{generated} generated, {failed} failed."
            )
        finally:
            db.close()
    except Exception as e:
        logger.error(f"Failed to run generate_monthly_reports task: {e}")


@celery_app.task(
    name="app.tasks.report_tasks.generate_patient_report",
    bind=True,
    max_retries=3,
)
def generate_patient_report(self, patient_id: str, report_month: str):
    """Generate monthly report for a specific patient."""
    try:
        from app.core.database import SessionLocal
        from app.services.report_service import report_service

        db = SessionLocal()
        try:
            report = report_service.generate_report(db, patient_id, report_month)
            logger.info(
                f"Report generated for patient {patient_id}, month={report_month}, "
                f"report_id={report.id}"
            )
            return str(report.id)
        finally:
            db.close()
    except Exception as exc:
        logger.error(
            f"Failed to generate report for patient {patient_id}, "
            f"month={report_month}: {exc}"
        )
        raise self.retry(exc=exc, countdown=300)
