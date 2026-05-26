"""Shared SQLAlchemy Enum type definitions.

Defining each Enum once here prevents SQLAlchemy from attempting to CREATE
the underlying PostgreSQL ENUM type more than once when multiple models share
the same enum (e.g. treatment_phase is used in both patient_profiles and
medication_schedules).
"""
from sqlalchemy import Enum

user_role_enum = Enum(
    "patient", "pmo", "doctor", "admin",
    name="user_role",
)

gender_enum = Enum(
    "laki-laki", "perempuan",
    name="gender_type",
)

tb_type_enum = Enum(
    "TB Paru", "TB Ekstra Paru", "TB RO",
    name="tb_type",
)

treatment_phase_enum = Enum(
    "intensive", "continuation",
    name="treatment_phase",
)

medication_status_enum = Enum(
    "confirmed", "skipped", "late", "pending",
    name="medication_status",
)

side_effect_severity_enum = Enum(
    "ringan", "sedang", "berat",
    name="side_effect_severity",
)

control_type_enum = Enum(
    "kontrol_1", "kontrol_2", "kontrol_3",
    name="control_type",
)

risk_level_enum = Enum(
    "low", "medium", "high", "critical",
    name="risk_level",
)

notification_type_enum = Enum(
    "medication", "control", "education", "ai", "system", "risk_alert",
    name="notification_type",
)
