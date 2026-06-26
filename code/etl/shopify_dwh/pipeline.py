"""
End-to-end ETL orchestrator — the single entry point a scheduler calls.

Runs the whole Layer 1 pipeline in dependency order:

    (optional healthcheck) -> STG loaders -> DWH build (DDL + transforms + verify
    + metric views)

Each step is invoked as its own `python -m ...` subprocess — the same way you'd run
it by hand — so this module is a thin, observable conductor over the existing entry
points rather than a re-implementation. That keeps each step's logic in one place
and means a subprocess crash can't take the orchestrator's own state with it.

Design choices:
  - **Fail-fast** by default: a failed step aborts the run (downstream depends on
    upstream). `--continue-on-error` overrides for diagnostics.
  - **Idempotent**: every step is safe to re-run. The DWH DDL is CREATE ... IF NOT
    EXISTS / TRUNCATE+INSERT / CREATE OR REPLACE, so the transforms do a full rebuild
    from STG each run — correct and simple at DYT's volume (the POC did the same).
  - **Mode passthrough**: `--mode {full|incremental|auto}` is forwarded to the STG
    loaders (auto = full if the table is empty, else incremental).
  - **Selectable**: `--stg-only` / `--dwh-only` run just one half.

Run (from code/etl/):
    python -m shopify_dwh.pipeline                  # full pipeline, auto mode
    python -m shopify_dwh.pipeline --check          # healthcheck first, then run
    python -m shopify_dwh.pipeline --mode full      # force a full reload
    python -m shopify_dwh.pipeline --stg-only       # extraction + load only
    python -m shopify_dwh.pipeline --dwh-only       # rebuild DWH from existing STG
"""

from __future__ import annotations

import argparse
import logging
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path

from shopify_dwh.config import configure_logging, load_settings

log = logging.getLogger("pipeline")

# code/etl/ — the working dir steps run from (so `ddl/...` paths and `-m` resolve).
ETL_ROOT = Path(__file__).resolve().parent.parent

# STG loaders in dependency order: top-level entities first (no dependency), then
# orders (establishes the updated_at watermark), then everything that re-reads
# orders, then the standalone snapshots. Mirrors README "Run" §4.
# discount_codes + gift_cards are deferred (scope decision) — not listed here.
STG_LOADERS = [
    "products",
    "variants",
    "customers",
    "locations",
    "orders",
    "line_items",
    "transactions",
    "tax_lines",
    "discount_applications",
    "shipping_lines",
    "fulfillments",
    "fulfillment_line_items",
    "refunds",
    "refund_line_items",
    "inventory_levels",
    "abandoned_checkouts",
]

# DWH build steps, in deploy order. 08_reconcile is intentionally excluded — it is a
# windowed, manual reconciliation, not an unattended step.
DWH_SQL = [
    "ddl/02_dwh_schema.sql",
    "ddl/03_dim_date.sql",
    "ddl/04_dim_time.sql",
    "ddl/05_transforms.sql",
    "ddl/06_verify_dwh.sql",
    "ddl/07_metric_views.sql",
]


@dataclass
class StepResult:
    label: str
    ok: bool
    seconds: float
    returncode: int


def _run(cmd: list[str], label: str) -> StepResult:
    """Run one step as a subprocess from ETL_ROOT; return its result (never raises)."""
    log.info("▶ %s", label)
    start = time.monotonic()
    proc = subprocess.run(cmd, cwd=str(ETL_ROOT))
    seconds = time.monotonic() - start
    ok = proc.returncode == 0
    log.log(
        logging.INFO if ok else logging.ERROR,
        "%s %s  (%.1fs, exit %d)",
        "✓" if ok else "✗",
        label,
        seconds,
        proc.returncode,
    )
    return StepResult(label, ok, seconds, proc.returncode)


def _steps(args) -> list[tuple[list[str], str]]:
    """Build the ordered (command, label) list from the CLI selection."""
    py = sys.executable
    steps: list[tuple[list[str], str]] = []

    if args.check:
        steps.append(([py, "-m", "shopify_dwh.healthcheck"], "healthcheck"))

    if not args.dwh_only:
        for name in STG_LOADERS:
            steps.append(([py, "-m", f"shopify_dwh.loaders.{name}", args.mode],
                          f"stg:{name} ({args.mode})"))

    if not args.stg_only:
        for sql in DWH_SQL:
            steps.append(([py, "-m", "shopify_dwh.ddl_runner", sql],
                          f"dwh:{Path(sql).name}"))

    return steps


def _summary(results: list[StepResult], total_seconds: float) -> None:
    print("\n" + "=" * 60)
    print("PIPELINE SUMMARY")
    print("=" * 60)
    for r in results:
        print(f"  {'OK  ' if r.ok else 'FAIL'}  {r.seconds:7.1f}s  {r.label}")
    failed = [r for r in results if not r.ok]
    print("-" * 60)
    print(f"  {len(results)} step(s), {len(failed)} failed, {total_seconds:.1f}s total")
    if failed:
        print(f"  FAILED: {', '.join(r.label for r in failed)}")
    print("=" * 60)


def main() -> int:
    parser = argparse.ArgumentParser(description="Run the Shopify -> Exasol ETL pipeline.")
    parser.add_argument("--mode", choices=["full", "incremental", "auto"], default="auto",
                        help="STG loader mode (default: auto)")
    parser.add_argument("--stg-only", action="store_true", help="run only the STG loaders")
    parser.add_argument("--dwh-only", action="store_true", help="run only the DWH build")
    parser.add_argument("--check", action="store_true", help="run the healthcheck first")
    parser.add_argument("--continue-on-error", action="store_true",
                        help="keep going after a step fails (default: fail-fast)")
    args = parser.parse_args()

    if args.stg_only and args.dwh_only:
        print("error: --stg-only and --dwh-only are mutually exclusive", file=sys.stderr)
        return 2

    # Validate config up front so a missing .env fails before any step runs.
    configure_logging(load_settings())

    steps = _steps(args)
    log.info("pipeline starting: %d step(s), mode=%s", len(steps), args.mode)

    results: list[StepResult] = []
    run_start = time.monotonic()
    aborted = False
    for cmd, label in steps:
        result = _run(cmd, label)
        results.append(result)
        if not result.ok and not args.continue_on_error:
            log.error("aborting: %s failed (use --continue-on-error to override)", label)
            aborted = True
            break

    _summary(results, time.monotonic() - run_start)

    failed = any(not r.ok for r in results)
    if aborted or failed:
        return 1
    log.info("pipeline complete: all %d step(s) OK", len(results))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
