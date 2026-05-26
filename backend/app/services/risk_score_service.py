import logging
from datetime import datetime, timedelta
from typing import List
from uuid import UUID

from sqlalchemy.orm import Session

from app.models.medication import MedicationLog
from app.models.risk_score import DropoutRiskScore
from app.models.side_effect import SideEffectLog
from app.models.symptom import SymptomLog

logger = logging.getLogger(__name__)


class RiskScoreService:
    def calculate(self, db: Session, patient_id: UUID) -> DropoutRiskScore:
        now = datetime.utcnow()

        # --- Adherence sub-score (last 14 days) ---
        start_14 = now - timedelta(days=14)
        total_logs_14 = (
            db.query(MedicationLog)
            .filter(
                MedicationLog.patient_id == patient_id,
                MedicationLog.scheduled_time >= start_14,
            )
            .count()
        )
        confirmed_14 = (
            db.query(MedicationLog)
            .filter(
                MedicationLog.patient_id == patient_id,
                MedicationLog.scheduled_time >= start_14,
                MedicationLog.status == "confirmed",
            )
            .count()
        )
        adherence_rate = confirmed_14 / total_logs_14 if total_logs_14 > 0 else 0.0
        adherence_sub = 1.0 - adherence_rate  # higher non-adherence = higher risk

        # --- Symptom sub-score (last 7 days) ---
        start_7 = now - timedelta(days=7)
        symptom_logs: List[SymptomLog] = (
            db.query(SymptomLog)
            .filter(
                SymptomLog.patient_id == patient_id,
                SymptomLog.logged_date >= start_7.date(),
            )
            .all()
        )
        if symptom_logs:
            total_avg = sum(
                (s.cough_scale + s.shortness_of_breath + s.appetite_scale + s.energy_scale) / 4.0
                for s in symptom_logs
            )
            avg_scale = total_avg / len(symptom_logs)
            symptom_sub = (avg_scale - 1) / 4.0  # normalise 1–5 to 0–1
        else:
            symptom_sub = 0.0

        # --- Side-effect sub-score (last 7 days) ---
        severe_count = (
            db.query(SideEffectLog)
            .filter(
                SideEffectLog.patient_id == patient_id,
                SideEffectLog.created_at >= start_7,
                SideEffectLog.severity == "berat",
            )
            .count()
        )
        side_effect_sub = min(severe_count * 0.2, 1.0)

        # --- Composite score ---
        total_score = adherence_sub * 0.5 + symptom_sub * 0.3 + side_effect_sub * 0.2

        # --- Risk level ---
        if total_score < 0.25:
            risk_level = "low"
        elif total_score < 0.5:
            risk_level = "medium"
        elif total_score < 0.75:
            risk_level = "high"
        else:
            risk_level = "critical"

        # --- Factor strings ---
        factors: List[str] = []
        if adherence_sub > 0.5:
            missed = total_logs_14 - confirmed_14
            factors.append(
                f"Kepatuhan rendah: {missed} dosis terlewat dalam 14 hari terakhir "
                f"({adherence_rate * 100:.0f}% kepatuhan)."
            )
        if symptom_sub > 0.5:
            factors.append(
                "Gejala berat dilaporkan dalam 7 hari terakhir. Pantau kondisi dengan seksama."
            )
        if side_effect_sub > 0:
            factors.append(
                f"{severe_count} efek samping berat dilaporkan dalam 7 hari terakhir."
            )
        if not factors:
            factors.append("Kondisi pasien dalam batas normal.")

        recommendation_map = {
            "low": "Pertahankan kepatuhan minum obat dan laporkan gejala secara rutin.",
            "medium": "Tingkatkan kepatuhan minum obat. Konsultasikan gejala dengan dokter atau PMO.",
            "high": (
                "Perhatian diperlukan! Segera hubungi PMO atau dokter untuk evaluasi kondisi Anda."
            ),
            "critical": (
                "KRITIS: Segera hubungi dokter atau pergi ke faskes terdekat. "
                "Kondisi memerlukan perhatian medis segera."
            ),
        }

        risk_score = DropoutRiskScore(
            patient_id=patient_id,
            calculated_at=now,
            score=round(total_score, 4),
            risk_level=risk_level,
            factors=factors,
            ai_recommendation=recommendation_map[risk_level],
        )
        db.add(risk_score)
        db.commit()
        db.refresh(risk_score)
        logger.info(
            "Risk score calculated for patient %s: score=%.4f level=%s",
            patient_id, total_score, risk_level,
        )
        return risk_score


risk_score_service = RiskScoreService()
