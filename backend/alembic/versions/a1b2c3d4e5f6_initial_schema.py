"""Initial schema — all 13 tables

Revision ID: a1b2c3d4e5f6
Revises:
Create Date: 2025-05-19 00:00:00.000000
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "a1b2c3d4e5f6"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


# ---------------------------------------------------------------------------
# Helpers — reuse Enum type objects with create_type=False after first use
# ---------------------------------------------------------------------------

def _enum(*values, name: str) -> sa.Enum:
    return sa.Enum(*values, name=name, create_type=False)


def upgrade() -> None:
    conn = op.get_bind()

    # ── 1. Create PostgreSQL ENUM types ─────────────────────────────────────
    conn.execute(sa.text(
        "CREATE TYPE user_role AS ENUM ('patient', 'pmo', 'doctor', 'admin')"
    ))
    conn.execute(sa.text(
        "CREATE TYPE gender_type AS ENUM ('laki-laki', 'perempuan')"
    ))
    conn.execute(sa.text(
        "CREATE TYPE tb_type AS ENUM ('TB Paru', 'TB Ekstra Paru', 'TB RO')"
    ))
    conn.execute(sa.text(
        "CREATE TYPE treatment_phase AS ENUM ('intensive', 'continuation')"
    ))
    conn.execute(sa.text(
        "CREATE TYPE medication_status AS ENUM ('confirmed', 'skipped', 'late', 'pending')"
    ))
    conn.execute(sa.text(
        "CREATE TYPE side_effect_severity AS ENUM ('ringan', 'sedang', 'berat')"
    ))
    conn.execute(sa.text(
        "CREATE TYPE control_type AS ENUM ('kontrol_1', 'kontrol_2', 'kontrol_3')"
    ))
    conn.execute(sa.text(
        "CREATE TYPE risk_level AS ENUM ('low', 'medium', 'high', 'critical')"
    ))
    conn.execute(sa.text(
        "CREATE TYPE notification_type AS ENUM "
        "('medication', 'control', 'education', 'ai', 'system', 'risk_alert')"
    ))

    # ── 2. users ─────────────────────────────────────────────────────────────
    op.create_table(
        "users",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("full_name", sa.String(100), nullable=False),
        sa.Column("phone_number", sa.String(20), unique=True, nullable=False),
        sa.Column("email", sa.String(255), unique=True, nullable=True),
        sa.Column("password_hash", sa.String(255), nullable=True),
        sa.Column("role", _enum("patient","pmo","doctor","admin", name="user_role"), nullable=False, server_default="patient"),
        sa.Column("is_verified", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("verified_by", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("fcm_token", sa.String(500), nullable=True),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default=sa.true()),
        sa.Column("otp_code", sa.String(6), nullable=True),
        sa.Column("otp_expires_at", sa.DateTime, nullable=True),
        sa.Column("created_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime, nullable=False, server_default=sa.func.now(), onupdate=sa.func.now()),
    )
    op.create_index("ix_users_phone_number", "users", ["phone_number"], unique=True)
    op.create_index("ix_users_email", "users", ["email"])

    # ── 3. patient_profiles ───────────────────────────────────────────────────
    op.create_table(
        "patient_profiles",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True),
        sa.Column("date_of_birth", sa.Date, nullable=False),
        sa.Column("gender", _enum("laki-laki","perempuan", name="gender_type"), nullable=False),
        sa.Column("address", sa.Text, nullable=True),
        sa.Column("faskes_name", sa.String(200), nullable=False),
        sa.Column("doctor_name", sa.String(100), nullable=False),
        sa.Column("tb_type", _enum("TB Paru","TB Ekstra Paru","TB RO", name="tb_type"), nullable=False, server_default="TB Paru"),
        sa.Column("treatment_start_date", sa.Date, nullable=False),
        sa.Column("current_phase", _enum("intensive","continuation", name="treatment_phase"), nullable=False, server_default="intensive"),
        sa.Column("phase_updated_at", sa.DateTime, nullable=True),
        sa.Column("treatment_end_date", sa.Date, nullable=True),
        sa.Column("weight_kg", sa.Float, nullable=True),
        sa.Column("is_treatment_complete", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("is_hospitalized", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("is_pregnant", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("data_confirmed_by_patient", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("created_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_patient_profiles_user_id", "patient_profiles", ["user_id"], unique=True)

    # ── 4. medication_schedules ───────────────────────────────────────────────
    op.create_table(
        "medication_schedules",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("patient_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("patient_profiles.id", ondelete="CASCADE"), nullable=False),
        sa.Column("phase", _enum("intensive","continuation", name="treatment_phase"), nullable=False),
        sa.Column("medications", postgresql.JSONB, nullable=False, server_default="[]"),
        sa.Column("schedule_times", postgresql.JSONB, nullable=False, server_default="[]"),
        sa.Column("reminder_before", sa.Integer, nullable=False, server_default="30"),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_medication_schedules_patient_id", "medication_schedules", ["patient_id"])

    # ── 5. ai_photo_verifications (created BEFORE medication_logs) ────────────
    op.create_table(
        "ai_photo_verifications",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        # medication_log_id FK added later via ALTER TABLE (circular dependency)
        sa.Column("medication_log_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("photo_url", sa.String(500), nullable=False),
        sa.Column("photo_taken_at", sa.DateTime, nullable=True),
        sa.Column("device_id", sa.String(200), nullable=True),
        sa.Column("ai_model", sa.String(100), nullable=True),
        sa.Column("ai_response_raw", postgresql.JSONB, nullable=True),
        sa.Column("is_valid", sa.Boolean, nullable=True),
        sa.Column("confidence_score", sa.Float, nullable=True),
        sa.Column("rejection_reason", sa.Text, nullable=True),
        sa.Column("processing_time", sa.Float, nullable=True),
        sa.Column("created_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
    )

    # ── 6. medication_logs ────────────────────────────────────────────────────
    op.create_table(
        "medication_logs",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("patient_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("patient_profiles.id", ondelete="CASCADE"), nullable=False),
        sa.Column("schedule_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("medication_schedules.id", ondelete="SET NULL"), nullable=True),
        sa.Column("scheduled_time", sa.DateTime, nullable=False),
        sa.Column("confirmed_at", sa.DateTime, nullable=True),
        sa.Column("status", _enum("confirmed","skipped","late","pending", name="medication_status"), nullable=False, server_default="pending"),
        sa.Column("photo_url", sa.String(500), nullable=True),
        sa.Column("is_photo_verified", sa.Boolean, nullable=True),
        sa.Column("ai_verification_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("ai_photo_verifications.id", ondelete="SET NULL"), nullable=True),
        sa.Column("streak_count", sa.Integer, nullable=False, server_default="0"),
        sa.Column("notes", sa.Text, nullable=True),
        sa.Column("created_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_medlog_patient_scheduled", "medication_logs", ["patient_id", "scheduled_time"])
    op.create_index("ix_medlog_status", "medication_logs", ["status"])

    # ── 6b. Deferred FK: ai_photo_verifications.medication_log_id → medication_logs ─
    op.create_foreign_key(
        "fk_ai_photo_verif_medication_log",
        "ai_photo_verifications",
        "medication_logs",
        ["medication_log_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_index("ix_ai_photo_verif_medlog_id", "ai_photo_verifications", ["medication_log_id"])

    # ── 7. symptom_logs ───────────────────────────────────────────────────────
    op.create_table(
        "symptom_logs",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("patient_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("patient_profiles.id", ondelete="CASCADE"), nullable=False),
        sa.Column("logged_date", sa.Date, nullable=False),
        sa.Column("cough_scale", sa.SmallInteger, nullable=False, server_default="1"),
        sa.Column("fever", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("fever_temperature", sa.Float, nullable=True),
        sa.Column("shortness_of_breath", sa.SmallInteger, nullable=False, server_default="1"),
        sa.Column("night_sweats", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("appetite_scale", sa.SmallInteger, nullable=False, server_default="1"),
        sa.Column("energy_scale", sa.SmallInteger, nullable=False, server_default="1"),
        sa.Column("weight_kg", sa.Float, nullable=True),
        sa.Column("additional_notes", sa.Text, nullable=True),
        sa.Column("ai_assessment", sa.Text, nullable=True),
        sa.Column("created_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint("patient_id", "logged_date", name="uq_symptom_patient_date"),
    )
    op.create_index("ix_symptom_patient_date", "symptom_logs", ["patient_id", "logged_date"])

    # ── 8. side_effect_logs ───────────────────────────────────────────────────
    op.create_table(
        "side_effect_logs",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("patient_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("patient_profiles.id", ondelete="CASCADE"), nullable=False),
        sa.Column("medication_log_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("medication_logs.id", ondelete="SET NULL"), nullable=True),
        sa.Column("logged_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
        sa.Column("side_effects", postgresql.JSONB, nullable=False, server_default="[]"),
        sa.Column("severity", _enum("ringan","sedang","berat", name="side_effect_severity"), nullable=False),
        sa.Column("ai_response", sa.Text, nullable=True),
        sa.Column("is_emergency", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("created_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_side_effect_patient_id", "side_effect_logs", ["patient_id"])

    # ── 9. control_schedules ──────────────────────────────────────────────────
    op.create_table(
        "control_schedules",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("patient_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("patient_profiles.id", ondelete="CASCADE"), nullable=False),
        sa.Column("scheduled_date", sa.Date, nullable=False),
        sa.Column("control_type", _enum("kontrol_1","kontrol_2","kontrol_3", name="control_type"), nullable=False),
        sa.Column("faskes_name", sa.String(200), nullable=True),
        sa.Column("notes", sa.Text, nullable=True),
        sa.Column("reminders_sent", postgresql.JSONB, nullable=False, server_default="{}"),
        sa.Column("is_completed", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("completed_at", sa.DateTime, nullable=True),
        sa.Column("created_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_control_schedules_patient_id", "control_schedules", ["patient_id"])

    # ── 10. education_logs ────────────────────────────────────────────────────
    op.create_table(
        "education_logs",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("patient_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("patient_profiles.id", ondelete="CASCADE"), nullable=False),
        sa.Column("content_id", sa.String(100), nullable=False),
        sa.Column("content_category", sa.String(100), nullable=True),
        sa.Column("trigger_type", sa.String(100), nullable=True),
        sa.Column("delivered_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
        sa.Column("is_read", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("read_at", sa.DateTime, nullable=True),
    )
    op.create_index("ix_education_logs_patient_id", "education_logs", ["patient_id"])
    op.create_index("ix_education_logs_content_id", "education_logs", ["content_id"])

    # ── 11. dropout_risk_scores ───────────────────────────────────────────────
    op.create_table(
        "dropout_risk_scores",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("patient_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("patient_profiles.id", ondelete="CASCADE"), nullable=False),
        sa.Column("calculated_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
        sa.Column("score", sa.Numeric(5, 4), nullable=False),
        sa.Column("risk_level", _enum("low","medium","high","critical", name="risk_level"), nullable=False),
        sa.Column("factors", postgresql.JSONB, nullable=False, server_default="[]"),
        sa.Column("ai_recommendation", sa.Text, nullable=True),
        sa.Column("action_taken", sa.String(200), nullable=True),
        sa.Column("created_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_dropout_risk_patient_id", "dropout_risk_scores", ["patient_id"])

    # ── 12. monthly_reports ───────────────────────────────────────────────────
    op.create_table(
        "monthly_reports",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("patient_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("patient_profiles.id", ondelete="CASCADE"), nullable=False),
        sa.Column("report_month", sa.Date, nullable=False),
        sa.Column("total_scheduled", sa.Integer, nullable=False, server_default="0"),
        sa.Column("confirmed_doses", sa.Integer, nullable=False, server_default="0"),
        sa.Column("missed_doses", sa.Integer, nullable=False, server_default="0"),
        sa.Column("late_doses", sa.Integer, nullable=False, server_default="0"),
        sa.Column("adherence_percentage", sa.Float, nullable=False, server_default="0"),
        sa.Column("avg_cough_scale", sa.Float, nullable=True),
        sa.Column("avg_appetite_scale", sa.Float, nullable=True),
        sa.Column("avg_energy_scale", sa.Float, nullable=True),
        sa.Column("side_effects_summary", postgresql.JSONB, nullable=True),
        sa.Column("ai_summary", sa.Text, nullable=True),
        sa.Column("ai_recommendation", postgresql.JSONB, nullable=True),
        sa.Column("pdf_url", sa.String(500), nullable=True),
        sa.Column("generated_at", sa.DateTime, nullable=True),
        sa.Column("created_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint("patient_id", "report_month", name="uq_monthly_report_patient_month"),
    )
    op.create_index("ix_monthly_reports_patient_id", "monthly_reports", ["patient_id"])

    # ── 13. notifications ─────────────────────────────────────────────────────
    op.create_table(
        "notifications",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("patient_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("patient_profiles.id", ondelete="CASCADE"), nullable=False),
        sa.Column("type", _enum("medication","control","education","ai","system","risk_alert", name="notification_type"), nullable=False),
        sa.Column("title", sa.String(200), nullable=False),
        sa.Column("body", sa.Text, nullable=False),
        sa.Column("data", postgresql.JSONB, nullable=True),
        sa.Column("is_sent", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("sent_at", sa.DateTime, nullable=True),
        sa.Column("is_read", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("read_at", sa.DateTime, nullable=True),
        sa.Column("scheduled_for", sa.DateTime, nullable=True),
        sa.Column("created_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_notif_patient_sent", "notifications", ["patient_id", "is_sent"])
    op.create_index("ix_notif_scheduled_for", "notifications", ["scheduled_for"])

    # ── 14. audit_logs ────────────────────────────────────────────────────────
    op.create_table(
        "audit_logs",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("action", sa.String(100), nullable=False),
        sa.Column("entity_type", sa.String(50), nullable=True),
        sa.Column("entity_id", sa.String(100), nullable=True),
        sa.Column("ip_address", sa.String(45), nullable=True),
        sa.Column("device_info", postgresql.JSONB, nullable=True),
        sa.Column("created_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_audit_user_created", "audit_logs", ["user_id", "created_at"])
    op.create_index("ix_audit_action", "audit_logs", ["action"])


def downgrade() -> None:
    conn = op.get_bind()

    # Drop deferred FK first
    op.drop_constraint("fk_ai_photo_verif_medication_log", "ai_photo_verifications", type_="foreignkey")

    # Drop tables in reverse dependency order
    for table in [
        "audit_logs",
        "notifications",
        "monthly_reports",
        "dropout_risk_scores",
        "education_logs",
        "control_schedules",
        "side_effect_logs",
        "symptom_logs",
        "medication_logs",
        "ai_photo_verifications",
        "medication_schedules",
        "patient_profiles",
        "users",
    ]:
        op.drop_table(table)

    # Drop ENUM types
    for enum_name in [
        "notification_type",
        "risk_level",
        "control_type",
        "side_effect_severity",
        "medication_status",
        "treatment_phase",
        "tb_type",
        "gender_type",
        "user_role",
    ]:
        conn.execute(sa.text(f"DROP TYPE IF EXISTS {enum_name}"))
