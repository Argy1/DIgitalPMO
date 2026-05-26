"""Smart migration runner for Railway.

State-aware: stamps already-applied schema instead of re-running,
so partial migrations from previous failed deploys don't block startup.
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


def main() -> None:
    with engine.connect() as conn:
        insp = inspect(conn)

        # Check if alembic_version already has our revision
        if insp.has_table("alembic_version"):
            row = conn.execute(text("SELECT version_num FROM alembic_version LIMIT 1")).fetchone()
            if row and row[0] == REVISION:
                print(f"[migrate] Already at {REVISION}, nothing to do.")
                return

        # Tables exist but no alembic_version record → stamp then upgrade
        if insp.has_table("users"):
            print(f"[migrate] Tables exist without version record — stamping {REVISION}.")
            _run(["alembic", "stamp", REVISION])
            _run(["alembic", "upgrade", "head"])
            return

    # Fresh database — run full migration
    print("[migrate] Fresh database — running alembic upgrade head.")
    _run(["alembic", "upgrade", "head"])


if __name__ == "__main__":
    main()
