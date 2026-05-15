"""
Phase 0 / Stream A gate test: connect to local Exasol and run SELECT 1.

Polls every 5 seconds until Exasol is ready (typically 1-3 minutes after container start).

Run:
    python exasol_hello.py
"""

import os
import sys
import time
from pathlib import Path

import pyexasol
from dotenv import load_dotenv

load_dotenv(Path(__file__).parent / ".env")

DSN = os.environ["EXASOL_DSN"]
USER = os.environ["EXASOL_USER"]
PASSWORD = os.environ["EXASOL_PASSWORD"]

MAX_WAIT_SECONDS = 240
POLL_INTERVAL = 5

start = time.time()
attempt = 0
last_error = None

while time.time() - start < MAX_WAIT_SECONDS:
    attempt += 1
    try:
        conn = pyexasol.connect(dsn=DSN, user=USER, password=PASSWORD, websocket_sslopt={"cert_reqs": 0})
        result = conn.execute("SELECT 1, CURRENT_TIMESTAMP, PARAM_VALUE FROM EXA_METADATA WHERE PARAM_NAME = 'databaseProductVersion'").fetchone()
        elapsed = time.time() - start
        print(f"\nConnected to Exasol after {elapsed:.1f}s ({attempt} attempts):")
        print(f"  SELECT 1:        {result[0]}")
        print(f"  Server time:     {result[1]}")
        print(f"  DB version:      {result[2]}")
        conn.close()
        sys.exit(0)
    except Exception as e:
        last_error = e
        elapsed = time.time() - start
        print(f"  attempt {attempt} at {elapsed:.0f}s: not ready ({type(e).__name__})")
        time.sleep(POLL_INTERVAL)

print(f"\nGave up after {MAX_WAIT_SECONDS}s. Last error: {last_error}", file=sys.stderr)
sys.exit(1)
