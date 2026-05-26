"""Smart migration runner for Railway.

Handles all DB states so deploys never fail due to partial previous runs:
  - Fresh DB                  → run alembic upgrade head
  - Partial (types, no tables) → run alembic upgrade head (migration is idempotent)
  - Tables exist, no version  → stamp then upgrade head
  - Already at head           → no-op
"""
import subprocess
import sys

from sqlalchemy import inspect, text
from app.core.database import engine

REVISION = "a1b2c3d4e5f6"


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

        # Already fully migrated — nothing to do
        if insp.has_table("alembic_version"):
            row = conn.execute(
                text("SELECT version_num FROM alembic_version LIMIT 1")
            ).fetchone()
            if row and row[0] == REVISION:
                print(f"[migrate] Already at {REVISION}, nothing to do.")
                return

        # Tables fully exist but no version record — stamp and check for newer migrations
        if insp.has_table("users"):
            print(f"[migrate] Tables exist without version record — stamping {REVISION}.")
            _run(["alembic", "stamp", REVISION])
            _run(["alembic", "upgrade", "head"])
            return

        # Partial state: enum types were created in a previous failed run but
        # tables were never created. The migration handles this via DO $$ BEGIN
        # ... EXCEPTION blocks for types and postgresql.ENUM(create_type=False)
        # for columns — so alembic upgrade head is safe to run.
        if _enum_types_exist(conn):
            print("[migrate] Partial state detected (enum types exist, no tables) — running upgrade.")

    # Fresh DB or partial state — run full migration
    print("[migrate] Running alembic upgrade head.")
    _run(["alembic", "upgrade", "head"])


if __name__ == "__main__":
    main()
