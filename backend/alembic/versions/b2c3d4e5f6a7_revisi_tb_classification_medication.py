"""Revisi klasifikasi TB, jenis obat, dan relasi PMO-pasien

Revision ID: b2c3d4e5f6a7
Revises: a1b2c3d4e5f6
Create Date: 2026-06-09 00:00:00.000000
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "b2c3d4e5f6a7"
down_revision: Union[str, None] = "a1b2c3d4e5f6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _enum(*values, name: str) -> postgresql.ENUM:
    """postgresql.ENUM with create_type=False — type is created separately via DO block."""
    return postgresql.ENUM(*values, name=name, create_type=False)


_TB_SO_TYPES = (
    "TB Paru",
    "TB Ekstra Paru - Otak",
    "TB Ekstra Paru - Tulang",
    "TB Ekstra Paru - Kulit",
    "TB Ekstra Paru - Kelenjar",
    "TB Ekstra Paru - Pleura",
    "TB Ekstra Paru - Abdominal",
    "TB Ekstra Paru - Milier",
)


def upgrade() -> None:
    conn = op.get_bind()

    # ── 1. Create new ENUM types (idempotent) ────────────────────────────────
    so_values = ", ".join(f"'{v}'" for v in _TB_SO_TYPES)
    enum_statements = [
        "DO $$ BEGIN CREATE TYPE tb_category AS ENUM ('SO', 'RO'); EXCEPTION WHEN duplicate_object THEN NULL; END $$",
        f"DO $$ BEGIN CREATE TYPE tb_so_type AS ENUM ({so_values}); EXCEPTION WHEN duplicate_object THEN NULL; END $$",
        "DO $$ BEGIN CREATE TYPE tb_ro_type AS ENUM ('MDR', 'XDR', 'RR'); EXCEPTION WHEN duplicate_object THEN NULL; END $$",
        "DO $$ BEGIN CREATE TYPE medication_type AS ENUM ('FDC', 'Kombinasi'); EXCEPTION WHEN duplicate_object THEN NULL; END $$",
        "DO $$ BEGIN CREATE TYPE fdc_type AS ENUM ('FDC', 'Kombipak'); EXCEPTION WHEN duplicate_object THEN NULL; END $$",
    ]
    for stmt in enum_statements:
        conn.execute(sa.text(stmt))

    tb_category = _enum("SO", "RO", name="tb_category")
    tb_so_type = _enum(*_TB_SO_TYPES, name="tb_so_type")
    tb_ro_type = _enum("MDR", "XDR", "RR", name="tb_ro_type")
    medication_type = _enum("FDC", "Kombinasi", name="medication_type")
    fdc_type = _enum("FDC", "Kombipak", name="fdc_type")

    # ── 2. patient_profiles ──────────────────────────────────────────────────
    op.add_column("patient_profiles", sa.Column("tb_category", tb_category, nullable=False, server_default="SO"))
    op.add_column("patient_profiles", sa.Column("tb_so_type", tb_so_type, nullable=True))
    op.add_column("patient_profiles", sa.Column("tb_ro_type", tb_ro_type, nullable=True))
    op.add_column("patient_profiles", sa.Column("treatment_duration_days", sa.Integer, nullable=True))
    op.add_column("patient_profiles", sa.Column("medication_type", medication_type, nullable=True))
    op.add_column("patient_profiles", sa.Column("fdc_type", fdc_type, nullable=True))
    op.add_column("patient_profiles", sa.Column("custom_medications", postgresql.JSONB, nullable=True))

    # Migrate existing data dari kolom tb_type lama (jika kolomnya masih ada)
    if _column_exists(conn, "patient_profiles", "tb_type"):
        # SO untuk semua row, kecuali yang lama 'TB RO' → RO
        conn.execute(sa.text(
            "UPDATE patient_profiles SET tb_category = 'RO' WHERE tb_type = 'TB RO'"
        ))
        conn.execute(sa.text(
            "UPDATE patient_profiles SET tb_category = 'SO' WHERE tb_type <> 'TB RO'"
        ))
        # tb_so_type 'TB Paru' untuk row yang sebelumnya 'TB Paru'
        conn.execute(sa.text(
            "UPDATE patient_profiles SET tb_so_type = 'TB Paru' "
            "WHERE tb_type IN ('TB Paru', 'TB Ekstra Paru')"
        ))
        op.drop_column("patient_profiles", "tb_type")

    # ── 3. medication_schedules ──────────────────────────────────────────────
    op.add_column("medication_schedules", sa.Column("medication_type", medication_type, nullable=True))
    op.add_column("medication_schedules", sa.Column("fdc_type", fdc_type, nullable=True))
    op.add_column("medication_schedules", sa.Column("tablet_count", sa.Integer, nullable=True))
    op.add_column("medication_schedules", sa.Column("frequency_per_week", sa.Integer, nullable=False, server_default="7"))
    op.add_column("medication_schedules", sa.Column("schedule_days", postgresql.JSONB, nullable=True))

    # ── 4. pmo_patients ──────────────────────────────────────────────────────
    op.create_table(
        "pmo_patients",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("pmo_user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("patient_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("patient_profiles.id", ondelete="CASCADE"), nullable=False, unique=True),
        sa.Column("linked_via", sa.String(20), nullable=False, server_default="phone_request"),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default=sa.true()),
        sa.Column("linked_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_pmo_patients_pmo_user_id", "pmo_patients", ["pmo_user_id"])
    op.create_index("ix_pmo_patients_patient_id", "pmo_patients", ["patient_id"], unique=True)


def downgrade() -> None:
    conn = op.get_bind()

    # ── 4. drop pmo_patients ─────────────────────────────────────────────────
    op.drop_index("ix_pmo_patients_patient_id", table_name="pmo_patients")
    op.drop_index("ix_pmo_patients_pmo_user_id", table_name="pmo_patients")
    op.drop_table("pmo_patients")

    # ── 3. medication_schedules ──────────────────────────────────────────────
    for col in ("schedule_days", "frequency_per_week", "tablet_count", "fdc_type", "medication_type"):
        op.drop_column("medication_schedules", col)

    # ── 2. patient_profiles — restore tb_type lama ───────────────────────────
    conn.execute(sa.text(
        "DO $$ BEGIN CREATE TYPE tb_type AS ENUM ('TB Paru', 'TB Ekstra Paru', 'TB RO'); "
        "EXCEPTION WHEN duplicate_object THEN NULL; END $$"
    ))
    tb_type = _enum("TB Paru", "TB Ekstra Paru", "TB RO", name="tb_type")
    op.add_column("patient_profiles", sa.Column("tb_type", tb_type, nullable=False, server_default="TB Paru"))
    # Map balik: RO → 'TB RO', selain itu → 'TB Paru'
    conn.execute(sa.text("UPDATE patient_profiles SET tb_type = 'TB RO' WHERE tb_category = 'RO'"))
    conn.execute(sa.text("UPDATE patient_profiles SET tb_type = 'TB Paru' WHERE tb_category = 'SO'"))

    for col in ("custom_medications", "fdc_type", "medication_type", "treatment_duration_days", "tb_ro_type", "tb_so_type", "tb_category"):
        op.drop_column("patient_profiles", col)

    # ── 1. drop new ENUM types ───────────────────────────────────────────────
    for enum_name in ("fdc_type", "medication_type", "tb_ro_type", "tb_so_type", "tb_category"):
        conn.execute(sa.text(f"DROP TYPE IF EXISTS {enum_name}"))


def _column_exists(conn, table: str, column: str) -> bool:
    row = conn.execute(
        sa.text(
            "SELECT EXISTS (SELECT 1 FROM information_schema.columns "
            "WHERE table_name = :t AND column_name = :c)"
        ),
        {"t": table, "c": column},
    ).scalar()
    return bool(row)
