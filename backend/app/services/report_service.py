import logging
from calendar import monthrange
from datetime import date, datetime
from uuid import UUID

from sqlalchemy.orm import Session

from app.core.exceptions import NotFoundException, ValidationException
from app.models.medication import MedicationLog
from app.models.report import MonthlyReport
from app.models.symptom import SymptomLog
from app.models.side_effect import SideEffectLog
from app.services.ai_service import ai_service

logger = logging.getLogger(__name__)


def _build_daily_adherence(
    db: Session, patient_id, year: int, month: int, last_day: int
) -> list:
    """Return [{day, status}] for every calendar day in the month."""
    start_dt = datetime(year, month, 1)
    end_dt = datetime(year, month, last_day, 23, 59, 59)
    logs = (
        db.query(MedicationLog)
        .filter(
            MedicationLog.patient_id == patient_id,
            MedicationLog.scheduled_time >= start_dt,
            MedicationLog.scheduled_time <= end_dt,
        )
        .order_by(MedicationLog.scheduled_time)
        .all()
    )
    # Pick the best status per calendar day
    best: dict[int, str] = {}
    for log in logs:
        day = log.scheduled_time.day
        current = best.get(day)
        if current != "confirmed":
            best[day] = log.status
    return [
        {"day": d, "status": best.get(d, "pending")} for d in range(1, last_day + 1)
    ]


def _build_weekly_symptoms(
    db: Session, patient_id, year: int, month: int
) -> list:
    """Return [{week, cough, appetite, energy}] grouped by calendar week."""
    from app.models.symptom import SymptomLog as SL
    logs = (
        db.query(SL)
        .filter(
            SL.patient_id == patient_id,
            SL.logged_date >= date(year, month, 1),
            SL.logged_date <= date(year, month, monthrange(year, month)[1]),
        )
        .all()
    )
    weeks: dict[int, list] = {1: [], 2: [], 3: [], 4: [], 5: []}
    for sl in logs:
        w = min(((sl.logged_date.day - 1) // 7) + 1, 5)
        weeks[w].append(sl)

    result = []
    for w in range(1, 6):
        wlogs = weeks[w]
        if not wlogs:
            continue
        result.append({
            "week": w,
            "cough": sum(s.cough_scale for s in wlogs) / len(wlogs),
            "appetite": sum(s.appetite_scale for s in wlogs) / len(wlogs),
            "energy": sum(s.energy_scale for s in wlogs) / len(wlogs),
        })
    return result


def _parse_year_month(report_month: str) -> tuple[int, int]:
    try:
        year, month = report_month.split("-")
        year, month = int(year), int(month)
        if not (1 <= month <= 12):
            raise ValueError
        return year, month
    except (ValueError, AttributeError):
        raise ValidationException(
            detail="Format bulan tidak valid. Gunakan format 'YYYY-MM', contoh: '2025-03'."
        )


class ReportService:
    def generate_report(
        self, db: Session, patient_id: UUID, report_month: str
    ) -> MonthlyReport:
        year, month = _parse_year_month(report_month)
        _, last_day = monthrange(year, month)

        # report_month column stores the first day of the month (Date type)
        month_date = date(year, month, 1)
        start_dt = datetime(year, month, 1)
        end_dt = datetime(year, month, last_day, 23, 59, 59)

        # --- Dose counts ---
        total_scheduled = (
            db.query(MedicationLog)
            .filter(
                MedicationLog.patient_id == patient_id,
                MedicationLog.scheduled_time >= start_dt,
                MedicationLog.scheduled_time <= end_dt,
            )
            .count()
        )
        confirmed_doses = (
            db.query(MedicationLog)
            .filter(
                MedicationLog.patient_id == patient_id,
                MedicationLog.scheduled_time >= start_dt,
                MedicationLog.scheduled_time <= end_dt,
                MedicationLog.status == "confirmed",
            )
            .count()
        )
        missed_doses = (
            db.query(MedicationLog)
            .filter(
                MedicationLog.patient_id == patient_id,
                MedicationLog.scheduled_time >= start_dt,
                MedicationLog.scheduled_time <= end_dt,
                MedicationLog.status == "skipped",
            )
            .count()
        )
        late_doses = (
            db.query(MedicationLog)
            .filter(
                MedicationLog.patient_id == patient_id,
                MedicationLog.scheduled_time >= start_dt,
                MedicationLog.scheduled_time <= end_dt,
                MedicationLog.status == "late",
            )
            .count()
        )
        adherence_percentage = (
            confirmed_doses / total_scheduled * 100 if total_scheduled > 0 else 0.0
        )

        # --- Symptom averages ---
        symptom_logs = (
            db.query(SymptomLog)
            .filter(
                SymptomLog.patient_id == patient_id,
                SymptomLog.logged_date >= start_dt.date(),
                SymptomLog.logged_date <= end_dt.date(),
            )
            .all()
        )
        avg_cough = avg_appetite = avg_energy = None
        if symptom_logs:
            avg_cough = sum(s.cough_scale for s in symptom_logs) / len(symptom_logs)
            avg_appetite = sum(s.appetite_scale for s in symptom_logs) / len(symptom_logs)
            avg_energy = sum(s.energy_scale for s in symptom_logs) / len(symptom_logs)

        # --- Side-effects summary ---
        side_effect_logs = (
            db.query(SideEffectLog)
            .filter(
                SideEffectLog.patient_id == patient_id,
                SideEffectLog.created_at >= start_dt,
                SideEffectLog.created_at <= end_dt,
            )
            .all()
        )
        side_effects_summary: dict = {}
        for se_log in side_effect_logs:
            for effect in (se_log.side_effects or []):
                name = effect.get("name", "Unknown") if isinstance(effect, dict) else str(effect)
                side_effects_summary[name] = side_effects_summary.get(name, 0) + 1

        # --- AI content ---
        report_data = {
            "report_month": report_month,
            "total_scheduled": total_scheduled,
            "confirmed_doses": confirmed_doses,
            "missed_doses": missed_doses,
            "late_doses": late_doses,
            "adherence_percentage": adherence_percentage,
        }
        ai_summary = ai_service.generate_report_summary(report_data)
        ai_recommendation = ai_service.generate_recommendations(report_data)

        # --- Upsert ---
        existing = (
            db.query(MonthlyReport)
            .filter(
                MonthlyReport.patient_id == patient_id,
                MonthlyReport.report_month == month_date,
            )
            .first()
        )
        if existing:
            existing.total_scheduled = total_scheduled
            existing.confirmed_doses = confirmed_doses
            existing.missed_doses = missed_doses
            existing.late_doses = late_doses
            existing.adherence_percentage = adherence_percentage
            existing.avg_cough_scale = avg_cough
            existing.avg_appetite_scale = avg_appetite
            existing.avg_energy_scale = avg_energy
            existing.side_effects_summary = side_effects_summary or None
            existing.ai_summary = ai_summary
            existing.ai_recommendation = ai_recommendation
            existing.generated_at = datetime.utcnow()
            db.commit()
            db.refresh(existing)
            logger.info("Monthly report updated for patient %s, month=%s", patient_id, report_month)
            return existing

        report = MonthlyReport(
            patient_id=patient_id,
            report_month=month_date,
            total_scheduled=total_scheduled,
            confirmed_doses=confirmed_doses,
            missed_doses=missed_doses,
            late_doses=late_doses,
            adherence_percentage=adherence_percentage,
            avg_cough_scale=avg_cough,
            avg_appetite_scale=avg_appetite,
            avg_energy_scale=avg_energy,
            side_effects_summary=side_effects_summary or None,
            ai_summary=ai_summary,
            ai_recommendation=ai_recommendation,
            generated_at=datetime.utcnow(),
        )
        db.add(report)
        db.commit()
        db.refresh(report)
        logger.info("Monthly report generated for patient %s, month=%s", patient_id, report_month)
        return report

    def get_report(
        self, db: Session, patient_id: UUID, report_month: str
    ) -> MonthlyReport:
        year, month = _parse_year_month(report_month)
        month_date = date(year, month, 1)
        report = (
            db.query(MonthlyReport)
            .filter(
                MonthlyReport.patient_id == patient_id,
                MonthlyReport.report_month == month_date,
            )
            .first()
        )
        if not report:
            raise NotFoundException(
                detail=f"Laporan untuk bulan {report_month} tidak ditemukan."
            )
        return report

    def list_reports(self, db: Session, patient_id: UUID, limit: int = 6):
        return (
            db.query(MonthlyReport)
            .filter(MonthlyReport.patient_id == patient_id)
            .order_by(MonthlyReport.report_month.desc())
            .limit(limit)
            .all()
        )

    def generate_pdf(
        self, db: Session, patient_id: UUID, report_month: str, patient_name: str
    ) -> str:
        """
        Generate a PDF for *report_month*, upload to R2, persist the URL, and
        return a signed download URL.
        """
        from app.services.pdf_service import pdf_service
        from app.services.storage_service import storage_service

        year, month = _parse_year_month(report_month)
        _, last_day = monthrange(year, month)

        try:
            report = self.get_report(db, patient_id, report_month)
        except NotFoundException:
            report = self.generate_report(db, patient_id, report_month)

        daily = _build_daily_adherence(db, patient_id, year, month, last_day)
        weekly_sym = _build_weekly_symptoms(db, patient_id, year, month)

        pdf_bytes = pdf_service.generate_monthly_pdf(
            patient_name=patient_name,
            year=year,
            month=month,
            adherence_percentage=float(report.adherence_percentage),
            total_scheduled=report.total_scheduled,
            confirmed_doses=report.confirmed_doses,
            missed_doses=report.missed_doses,
            late_doses=report.late_doses,
            daily_adherence=daily,
            weekly_symptoms=weekly_sym,
            side_effects_summary=report.side_effects_summary,
            ai_summary=report.ai_summary,
            ai_recommendation=report.ai_recommendation,
        )

        timestamp = datetime.utcnow().strftime("%Y%m%d%H%M%S")
        key = f"reports/{patient_id}/{year}-{month:02d}-{timestamp}.pdf"
        result = storage_service.upload_bytes(pdf_bytes, key, "application/pdf")

        report.pdf_url = result["key"]  # store key, generate fresh signed URL on demand
        db.commit()

        signed_url = storage_service.generate_presigned_url(result["key"])
        logger.info(
            "PDF generated for patient %s, month=%s, key=%s", patient_id, report_month, key
        )
        return signed_url


report_service = ReportService()
