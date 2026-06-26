"""
Generic Exasol DDL/SQL runner.

Ported from the POC's deploy_ddl.py. Reads a .sql file, strips full-line `--`
comments, splits on `;`, and executes each statement in order. SELECT statements
have their result rows printed (handy for verification queries). Fails loud on the
first error so a broken statement can't hide behind a later success.

Usage (run from code/etl/):
    python -m shopify_dwh.ddl_runner ddl/01_stg_schema.sql
    python -m shopify_dwh.ddl_runner ddl/verify_stg.sql
"""

from __future__ import annotations

import sys
from pathlib import Path

from shopify_dwh.config import load_settings
from shopify_dwh.exasol_loader import connect


def split_statements(sql: str) -> list[str]:
    """Drop full-line comments, then split on semicolons."""
    lines = [ln for ln in sql.splitlines() if not ln.strip().startswith("--")]
    body = "\n".join(lines)
    return [s.strip() for s in body.split(";") if s.strip()]


def run_file(sql_path: Path) -> int:
    statements = split_statements(sql_path.read_text(encoding="utf-8"))
    print(f"Running {len(statements)} statement(s) from {sql_path.name}\n")

    conn = connect(load_settings())
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


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: python -m shopify_dwh.ddl_runner <path-to.sql>", file=sys.stderr)
        return 2
    sql_path = Path(sys.argv[1])
    if not sql_path.is_absolute():
        sql_path = Path.cwd() / sql_path
    return run_file(sql_path)


if __name__ == "__main__":
    raise SystemExit(main())
