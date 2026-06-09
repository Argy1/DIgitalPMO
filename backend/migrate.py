"""Smart migration runner for Railway.

Handles all DB states so deploys never fail due to partial previous runs:
  - Fresh DB                  → run alembic upgrade head
  - Partial (types, no tables) → run alembic upgrade head (migration is idempotent)
  - Tables exist, no version  → stamp baseline then upgrade head
  - Already versioned          → upgrade head (applies any newer migrations)
"""
import subprocess
import sys

from sqlalchemy import inspect, text
from app.core.database import engine

# Baseline revision = the initial schema. Used only to stamp pre-existing DBs
# that have tables but no alembic_version record. New migrations chain off this
# and are always applied via `alembic upgrade head` below.
BASELINE_REVISION = "a1b2c3d4e5f6"


def _run(cmd: list[str]) -> None:
    result = subprocess.run(cmd)
    if result.returncode != 0:
        sys.exit(result.returncode)


def _enum_types_exist(conn) -> bool:
    row = conn.execute(
        text("SELECT EXISTS(SELECT 1 FROM pg_type WHERE typname = 'user_role')")
    ).scalar()
    return bool(row)


def main() -> None:
    with engine.connect() as conn:
        insp = inspect(conn)

        # Versioned DB — always upgrade to head so newer migrations get applied.
        if insp.has_table("alembic_version"):
            row = conn.execute(
                text("SELECT version_num FROM alembic_version LIMIT 1")
            ).fetchone()
            print(f"[migrate] Versioned DB at {row[0] if row else 'unknown'} — upgrading to head.")

        # Tables exist but no version record — stamp baseline then upgrade head.
        elif insp.has_table("users"):
            print(f"[migrate] Tables exist without version record — stamping {BASELINE_REVISION}.")
            _run(["alembic", "stamp", BASELINE_REVISION])

        # Partial state: enum types from a previous failed run but no tables.
        # Migration is idempotent (DO $$ BEGIN ... EXCEPTION + create_type=False),
        # so upgrade head is safe.
        elif _enum_types_exist(conn):
            print("[migrate] Partial state detected (enum types exist, no tables) — running upgrade.")

    # Apply all migrations up to head.
    print("[migrate] Running alembic upgrade head.")
    _run(["alembic", "upgrade", "head"])


if __name__ == "__main__":
    main()
