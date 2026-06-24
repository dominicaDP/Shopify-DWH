"""
Exasol load utility for the POC (Phase 2.2).

The reusable DB side of every loader: connect, shape a DataFrame to a target
table, and bulk-load it. Loaders own the Shopify-JSON -> rows mapping; this module
owns getting those rows into Exasol cleanly.

Design choices:
  - Column alignment is by NAME (case-insensitive), read from the live table via
    EXA_ALL_COLUMNS, not by trusting the caller to match DDL order. Missing columns
    load as NULL; unexpected columns are dropped with a warning.
  - pandas NaN / NaT -> None -> SQL NULL.
  - Two write modes: load_full (TRUNCATE then insert) and merge_upsert (key-based,
    for the idempotent incremental loaders in Phase 2.6/2.7).

Run directly for a Phase 2.2 self-test (round-trips dummy rows through stg_products):
    python exasol_loader.py
"""

import logging
import os
from pathlib import Path
from typing import Iterable, Optional, Sequence

import pandas as pd
import pyexasol
from dotenv import load_dotenv

log = logging.getLogger("exasol")


def connect() -> pyexasol.ExaConnection:
    """Open a PyExasol connection from .env (self-signed cert tolerated locally)."""
    load_dotenv(Path(__file__).parent / ".env")
    return pyexasol.connect(
        dsn=os.environ["EXASOL_DSN"],
        user=os.environ["EXASOL_USER"],
        password=os.environ["EXASOL_PASSWORD"],
        websocket_sslopt={"cert_reqs": 0},
    )


def get_table_columns(conn: pyexasol.ExaConnection, schema: str, table: str) -> list[str]:
    """Return the table's column names (UPPERCASE) in ordinal order."""
    rows = conn.execute(
        """
        SELECT COLUMN_NAME
        FROM SYS.EXA_ALL_COLUMNS
        WHERE COLUMN_SCHEMA = {schema} AND COLUMN_TABLE = {table}
        ORDER BY COLUMN_ORDINAL_POSITION
        """,
        {"schema": schema.upper(), "table": table.upper()},
    ).fetchall()
    if not rows:
        raise ValueError(f"No such table or no columns: {schema}.{table}")
    return [r[0] for r in rows]


def _align(df: pd.DataFrame, table_columns: Sequence[str]) -> pd.DataFrame:
    """Match df columns to the table (by uppercased name), order them, NaN -> None."""
    renamed = df.rename(columns={c: c.upper() for c in df.columns})
    extra = set(renamed.columns) - set(table_columns)
    if extra:
        log.warning("dropping columns not in target table: %s", sorted(extra))
    aligned = renamed.reindex(columns=list(table_columns))
    # object-cast first so datetime/int columns can hold None without upcasting noise
    return aligned.astype(object).where(pd.notnull(aligned), None)


def load_full(
    conn: pyexasol.ExaConnection,
    schema: str,
    table: str,
    df: pd.DataFrame,
    *,
    truncate: bool = True,
) -> int:
    """Full load: optionally TRUNCATE, then bulk-insert the whole DataFrame.

    Returns the row count loaded.
    """
    cols = get_table_columns(conn, schema, table)
    aligned = _align(df, cols)
    if truncate:
        conn.execute(f"TRUNCATE TABLE {schema}.{table}")
    if len(aligned):
        conn.import_from_pandas(aligned, (schema, table))
    conn.commit()
    log.info("load_full %s.%s: %d rows", schema, table, len(aligned))
    return len(aligned)


def merge_upsert(
    conn: pyexasol.ExaConnection,
    schema: str,
    table: str,
    df: pd.DataFrame,
    key_columns: Sequence[str],
) -> int:
    """Idempotent upsert via a temp table + MERGE on key_columns.

    Used by the incremental loaders so re-running a window never duplicates rows.
    Returns the row count staged for merge.
    """
    cols = get_table_columns(conn, schema, table)
    aligned = _align(df, cols)
    if not len(aligned):
        log.info("merge_upsert %s.%s: nothing to merge", schema, table)
        return 0

    keys = [k.upper() for k in key_columns]
    non_keys = [c for c in cols if c not in keys]
    tmp = f"{table}_STG_TMP"

    conn.execute(f"CREATE OR REPLACE TABLE {schema}.{tmp} LIKE {schema}.{table}")
    try:
        conn.import_from_pandas(aligned, (schema, tmp))
        on_clause = " AND ".join(f"t.{k} = s.{k}" for k in keys)
        set_clause = ", ".join(f"t.{c} = s.{c}" for c in non_keys)
        insert_cols = ", ".join(cols)
        insert_vals = ", ".join(f"s.{c}" for c in cols)
        merge_sql = f"""
            MERGE INTO {schema}.{table} t
            USING {schema}.{tmp} s
              ON {on_clause}
            WHEN MATCHED THEN UPDATE SET {set_clause}
            WHEN NOT MATCHED THEN INSERT ({insert_cols}) VALUES ({insert_vals})
        """
        conn.execute(merge_sql)
        conn.commit()
    finally:
        conn.execute(f"DROP TABLE IF EXISTS {schema}.{tmp}")
        conn.commit()
    log.info("merge_upsert %s.%s: %d rows merged on %s", schema, table, len(aligned), keys)
    return len(aligned)


def count(conn: pyexasol.ExaConnection, schema: str, table: str) -> int:
    return conn.execute(f"SELECT COUNT(*) FROM {schema}.{table}").fetchone()[0]


def to_naive_utc(df: pd.DataFrame, columns: Iterable[str]) -> pd.DataFrame:
    """Parse Shopify ISO-8601 timestamps (e.g. 2024-01-15T10:30:00Z) into naive
    UTC datetimes that Exasol's IMPORT will cast cleanly to TIMESTAMP. In place."""
    for col in columns:
        df[col] = pd.to_datetime(df[col], utc=True, errors="coerce").dt.tz_localize(None)
    return df


# ---------------------------------------------------------------------------
# Phase 2.2 self-test: round-trip dummy rows through stg_products, then clean up.
# ---------------------------------------------------------------------------

def _selftest() -> int:
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(name)s: %(message)s")
    schema, table = "SHOPIFY_STG", "stg_products"

    now = pd.Timestamp.now()
    df = pd.DataFrame(
        [
            {
                "id": "gid://shopify/Product/_TEST_1",
                "title": "Loader self-test A",
                "handle": "loader-selftest-a",
                "description": None,            # exercises NULL
                "product_type": "TEST",
                "vendor": "POC",
                "status": "ACTIVE",
                "created_at": now,
                "updated_at": now,
                "published_at": None,           # exercises NULL timestamp
                "tags": "smoke,test",
                "extracted_at": now,
                "bogus_extra_col": "should be dropped",  # exercises extra-column warning
            },
            {
                "id": "gid://shopify/Product/_TEST_2",
                "title": "Loader self-test B",
                "handle": "loader-selftest-b",
                "description": "second row",
                "product_type": "TEST",
                "vendor": "POC",
                "status": "DRAFT",
                "created_at": now,
                "updated_at": now,
                "published_at": now,
                "tags": None,
                "extracted_at": now,
                "bogus_extra_col": "should be dropped",
            },
        ]
    )

    conn = connect()
    try:
        loaded = load_full(conn, schema, table, df)
        n = count(conn, schema, table)
        print(f"\nLoaded {loaded} rows, table now reports COUNT = {n}")
        # re-run to confirm load_full truncates (idempotent full load)
        load_full(conn, schema, table, df)
        n2 = count(conn, schema, table)
        print(f"After re-run, COUNT = {n2} (full load truncates, so still {len(df)})")
        # clean up — leave the table empty for the real Phase 2.3 loader
        conn.execute(f"TRUNCATE TABLE {schema}.{table}")
        conn.commit()
        print(f"Cleaned up, COUNT = {count(conn, schema, table)}")
        ok = loaded == len(df) and n == len(df) and n2 == len(df)
        print("\nself-test PASSED" if ok else "\nself-test FAILED")
        return 0 if ok else 1
    finally:
        conn.close()


if __name__ == "__main__":
    raise SystemExit(_selftest())
