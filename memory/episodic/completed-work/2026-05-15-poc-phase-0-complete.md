# 2026-05-15: Shopify POC — Phase 0 Foundations Complete

**Date:** 2026-05-15
**Project:** shopify-poc (new), dyt-dwh (design v2.1), research-notes (membership_tier added)
**Type:** experiment / infrastructure

## What Was Completed

### 1. Closed Out dyt-dwh Design Task (v2.1)
Audited the 8 items in the open HIGH task ("Update schema design with confirmed findings from report mapping"). 6 of 8 were already present from prior work. Two real additions:
- `membership_tier` column on Layer 1 `dim_customer` (derived from `tags` at load time; documented SB-Gold/Silver/Platinum mapping pattern, config-driven)
- `DYT_DWH.v_dyt_order_payment_split` view (Reports 8, 9, 14, 15 — GC/Discount/Cash split, joined to `dim_voucher` for channel context)
- Doc bumped to v2.1, status: design complete, ready for ETL

### 2. Created `shopify-poc` Project
New standalone project for validating Layer 1 design with real DYT data on local Exasol Community Edition. Structure:
- `context.md` — purpose, scope (4 STG + 4 DWH objects → "revenue by product by day"), success criteria, security posture, decisions
- `plan.md` — 5-phase execution path with gates (sequence-driven, not calendar-driven)
- `tasks.md` — phased task list
- `notes.md` — append-only findings log

INDEX.md, CURRENT switched. research-notes and dyt-dwh marked "On Hold" pending POC outcome.

### 3. Completed Phase 0 — Foundations

**Stream A (Exasol):**
- Installed Docker Desktop (mid-session update required), pulled `exasol/docker-db:latest` (~3 GB)
- Started container: `docker run -d --name exasol-db --privileged -p 8563:8563 -p 2580:2580 -v exasol-data:/exa exasol/docker-db:latest`
- Container ready in ~30s (faster than docs' 1-3 min estimate)
- PyExasol connects with default `sys/exasol` credentials
- Running Exasol v2025.2.1

**Stream B (Python):**
- Created `code/poc/` inside repo (user chose in-repo over separate repo)
- venv with Python 3.11.9
- Installed: httpx 0.28.1, pandas 3.0.3, pyexasol 2.2.1, python-dotenv 1.2.2
- `.gitignore` at repo root excludes `.env`, venvs, data dumps, Exasol volumes

**Stream C (Shopify):**
- App created on `dev.shopify.com` dashboard (modern unified dev console, not in-admin "Develop apps")
- Name: "DataWarehouse", scopes `read_orders,read_products`
- Required toggling "Use legacy install flow" ON — without it Shopify uses managed installation that doesn't fit our backend OAuth pattern
- App config is versioned: changes need Create version + Release to activate
- Redirect URL `http://localhost:3001/callback` (port 3001 to avoid `mirofish` container squatting on 3000)
- Built one-shot OAuth helper (`oauth_install.py`): tiny http.server catches callback, exchanges code for offline token, writes to `.env`
- Token captured (`shpat_93...`), `shopify_hello.py` confirmed connection — shop "Dress Your Tech" on `garnishonline.myshopify.com`, ZAR, Africa/Johannesburg

## Key Decisions

1. **Standalone POC, not on Digital Planet infrastructure.** Removes IT coordination, lets work start immediately.
2. **Exasol Community Edition (not Personal).** Community = local VM/ISO with 200GB cap and non-commercial license. Personal = BYOC, reintroduces cloud setup. Volume cap fine for POC.
3. **No anonymisation.** Legitimate data access (Head of Analytics) + secure local environment (BitLocker, localhost-only Exasol, gitignored secrets) satisfies POPIA without dropping data fidelity.
4. **Sequence-driven planning over calendar-driven.** User explicitly: "We will work on it when we can - lets not worry about timeframes." Plans now use phases + gates, not week-counts.
5. **Membership_tier derived at load, raw tags retained.** Config-driven mapping (SB-Gold etc.) extensible to future B2B partners without schema change.
6. **Payment split as a Layer 2 view, not Layer 1 columns.** Keeps Layer 1 productisable — DYT-specific gateway groupings live in `DYT_DWH.v_dyt_order_payment_split`.

## Patterns Identified

- **Phase + Gate Planning** (HIGH confidence) — Sequence-driven, each phase has explicit "you know it worked because…" criteria. Pick-up-and-put-down friendly. Use for any multi-step work the user might not finish in one sitting.
- **Standalone POC Before Infrastructure Commit** (HIGH confidence) — Local-only validation of designs before involving operational infrastructure. Decoupling from DevOps removes scheduling and access dependencies.
- **OAuth One-Shot Helper Script** (MEDIUM confidence) — When a Shopify app uses OAuth, a small Python script with `http.server` + `webbrowser.open()` + token-exchange is enough to capture an offline token. Reusable for any single-store backend app.

## Issues Encountered

- **Initial wrong Shopify route.** Sent user to Partner Dashboard signup (`partners.shopify.com`) and then to in-admin "Develop apps". Actual home was `dev.shopify.com`. Lesson: ask which dashboard before recommending navigation.
- **Wrong App URL field for redirect.** User initially put `http://localhost:3001/callback` in App URL (it belongs in "Allowed redirection URLs" — App URL is a separate, less-important field for our use).
- **Docker mid-session update.** Required reinstall, wiped local image cache, ~3 GB re-pull. Lesson: pre-check Docker Desktop for pending updates before kicking off heavy operations.
- **Oracle-syntax-in-Exasol footgun.** Test used `DBMS_METADATA.GET_DATABASE_VERSION_NUMBER()` — Oracle-only. Exasol equivalent: `SELECT PARAM_VALUE FROM EXA_METADATA WHERE PARAM_NAME = 'databaseProductVersion'`.
- **Self-signed cert on local Exasol.** PyExasol needs `websocket_sslopt={"cert_reqs": 0}` to skip verification. Not needed against production Exasol with a real cert.

## Time Spent

One working session of mixed activity (estimating ~2 hours hands-on, paced by Shopify app dashboard tangents).

## Links

- `projects/shopify-poc/context.md` — POC scope and decisions
- `projects/shopify-poc/plan.md` — 5-phase execution path
- `projects/shopify-poc/notes.md` — running findings log
- `code/poc/` — POC code (oauth_install.py, shopify_hello.py, exasol_hello.py, requirements.txt, .env)
- `projects/dyt-dwh/design.md` — v2.1 with new view + membership_tier reference
- `projects/research-notes/schema-layered.md` — dim_customer with membership_tier
