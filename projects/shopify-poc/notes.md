# POC Notes

Findings, surprises, decisions, and observations captured during the POC. Append-only; date each entry.

Use this file for anything that doesn't belong in `plan.md` (the path) or `tasks.md` (the checklist):

- Things that took longer than expected
- API quirks (Shopify deprecations, rate-limit behaviour, undocumented response shapes)
- Exasol-specific surprises (load performance, type coercion edge cases, distribution key choices)
- Decisions made mid-flight that change the plan
- Out-of-scope questions worth coming back to
- Numbers worth keeping (row counts, durations, sizes)

---

## Log

### 2026-05-15 — POC scoped and planned

POC scope, plan, and tasks set up. Awaiting Phase 0 kickoff.

Key decisions: see `context.md` Decisions Made section.

---

### 2026-05-15 — Phase 0 complete

All three streams green. Findings:

**Shopify app creation — actual flow used:**
- App was created via `dev.shopify.com` (the modern unified dashboard) — not the in-admin "Develop apps" route. That route gives Client ID + Secret only; no static `shpat_` token shortcut.
- Required toggling **"Use legacy install flow"** ON in app settings. Without it Shopify uses managed installation and our standard OAuth flow fails.
- App config is versioned — every change requires Create version + Release to take effect. Worth knowing for any future scope/scope-bump.
- The shop's Shopify subdomain is `garnishonline.myshopify.com` even though the brand is "Dress Your Tech" and the customer URL is `dressyourtech.co.za`. Historic naming.

**Docker:**
- Docker Desktop required an update mid-session. Reinstall wiped local image cache, had to re-pull the ~3 GB Exasol image.
- Container started cleanly with `--privileged` flag on Windows / WSL2 backend.
- Exasol takes ~30s post-`docker run` to accept connections (faster than the expected 1-3 min from documentation).

**Exasol:**
- Default credentials `sys/exasol` work out of the box for the Community Edition Docker image.
- `pyexasol` needed `websocket_sslopt={"cert_reqs": 0}` to skip self-signed cert verification on the local container. Won't be needed against production Exasol with a real cert.
- **Reminder for future SQL work:** Exasol is NOT Oracle. Initial test used `DBMS_METADATA.GET_DATABASE_VERSION_NUMBER()` (Oracle) which doesn't exist. Correct Exasol equivalent: `SELECT PARAM_VALUE FROM EXA_METADATA WHERE PARAM_NAME = 'databaseProductVersion'`.
- Running version: **2025.2.1**

**Mid-session port juggle:**
- Started with `mirofish` container on port 3000 → moved OAuth callback to port 3001. After Docker reinstall the container is gone, port 3000 is free again, but no need to change anything now.

**Time to first green light:** Roughly one session of evening-equivalent work, paced by the Shopify app config tangents.
