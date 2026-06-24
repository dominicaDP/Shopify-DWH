"""
Generic Exasol DDL/SQL runner for the POC.

Reads a .sql file, strips full-line `--` comments, splits on `;`, and executes
each statement in order against the local Exasol. SELECT statements have their
result rows printed (handy for verification queries). Fails loud on the first
error so a broken statement can't hide behind a later success.

Usage:
    python deploy_ddl.py ddl/01_stg_schema.sql
    python deploy_ddl.py ddl/verify_stg.sql
"""

import os
import sys
from pathlib import Path

import pyexasol
from dotenv import load_dotenv

load_dotenv(Path(__file__).parent / ".env")

DSN = os.environ["EXASOL_DSN"]
USER = os.environ["EXASOL_USER"]
PASSWORD = os.environ["EXASOL_PASSWORD"]


def split_statements(sql: str) -> list[str]:
    """Drop full-line comments, then split on semicolons."""
    lines = [ln for ln in sql.splitlines() if not ln.strip().startswith("--")]
    body = "\n".join(lines)
    return [s.strip() for s in body.split(";") if s.strip()]


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: python deploy_ddl.py <path-to.sql>", file=sys.stderr)
        return 2

    sql_path = Path(sys.argv[1])
    if not sql_path.is_absolute():
        sql_path = Path(__file__).parent / sql_path
    statements = split_statements(sql_path.read_text(encoding="utf-8"))

    print(f"Running {len(statements)} statement(s) from {sql_path.name}\n")
    conn = pyexasol.connect(
        dsn=DSN, user=USER, password=PASSWORD, websocket_sslopt={"cert_reqs": 0}
    )
    try:
        for i, stmt in enumerate(statements, 1):
            label = " ".join(stmt.split())[:72]
            try:
                stm = conn.execute(stmt)
                if stmt.lstrip().upper().startswith("SELECT"):
                    rows = stm.fetchall()
                    print(f"[{i}/{len(statements)}] OK    {label}")
                    for row in rows:
                        print(f"               -> {row}")
                else:
                    print(f"[{i}/{len(statements)}] OK    {label}")
            except Exception as e:
                print(f"[{i}/{len(statements)}] FAIL  {label}")
                print(f"               !! {type(e).__name__}: {e}")
                raise
    finally:
        conn.close()

    print("\nDone.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
