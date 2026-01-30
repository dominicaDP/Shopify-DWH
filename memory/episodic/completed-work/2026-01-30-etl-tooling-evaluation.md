# ETL Tooling Evaluation

**Date:** 2026-01-30
**Project:** Shopify DWH
**Type:** research / decision

## What was completed

1. Evaluated off-the-shelf ETL options (Fivetran, Airbyte)
2. Researched custom ETL components (Python, PyExasol, Shopify API)
3. Compared scheduling options (systemd timers vs cron)
4. Designed recommended architecture for custom ETL
5. Documented implementation phases

## Key decision

**Custom Python ETL** running on the same Linux server as Exasol

**Rationale:**
- Fivetran: Too expensive ($500-$10k+/month), 40-70% price increase in 2025
- Airbyte: Still adds cost/complexity, overkill for single source
- Custom: Zero licensing cost, runs on existing infrastructure, full control

## Tech stack selected

| Component | Technology | Version |
|-----------|------------|---------|
| Language | Python | 3.10+ (required for PyExasol) |
| Shopify Client | shopify_python_api or custom GraphQL | Latest |
| Exasol Driver | PyExasol | 2.0+ |
| Scheduler | systemd timers | (built into Linux) |
| Config | YAML + .env files | - |

## Key patterns identified

### Shopify Bulk Operations
- Use `bulkOperationRunQuery` for full loads (async, JSONL output)
- Up to 5 concurrent operations per shop (API 2026-01+)
- Max 5 connections, 2 levels of nesting
- Results expire after 7 days
- Use webhook or polling for completion status

### PyExasol for Bulk Loading
- HTTP transport with compression (much faster than ODBC)
- Native pandas integration
- Parallel data streams for multi-core utilization

### systemd Timers over Cron
- Single instance guarantee (no overlapping runs)
- Persistent=true catches up on missed runs
- Resource limits (CPUQuota, MemoryLimit)
- journald integration for logging
- Environment file support

## ETL architecture

```
┌─────────────────┐
│  Shopify API    │
│  (GraphQL)      │
└────────┬────────┘
         │ Bulk Operations / Queries
         ▼
┌─────────────────┐
│  Python ETL     │  ← systemd timer triggers
│  (on Linux box) │
└────────┬────────┘
         │ PyExasol
         ▼
┌─────────────────┐     ┌─────────────────┐
│  SHOPIFY_STG    │────►│  SHOPIFY_DWH    │
│  (staging)      │     │  (star schema)  │
└─────────────────┘     └─────────────────┘
```

## Job schedule design

| Job | Frequency | Method |
|-----|-----------|--------|
| Full product sync | Daily 2am | Bulk operation |
| Incremental orders | Every 6h | Filtered query |
| Incremental customers | Every 6h | Filtered query |
| Discount codes | Daily | Standard query |
| Inventory levels | Hourly (optional) | Standard query |

## Cost analysis

| Solution | Monthly Cost |
|----------|--------------|
| Fivetran | $500-$10,000+ |
| Airbyte Cloud | $300-$2,000+ |
| Custom Python | $0 |

Custom approach pays off immediately at our scale (2-4k orders/month).

## Issues encountered

- Shopify official Python library's GraphQL support is basic but functional
- May need custom GraphQL client for better error handling
- Need to handle bulk operation polling carefully (rate limits)

## Next steps

Implementation phases documented in notes.md:
1. Foundation: Project setup, clients, staging tables
2. Core ETL: Orders, customers, discounts extraction + transforms
3. Production: systemd timers, monitoring, error handling
4. Optimization: Inventory, performance tuning

## Links

- [Shopify Bulk Operations](https://shopify.dev/docs/api/usage/bulk-operations/queries)
- [PyExasol](https://github.com/exasol/pyexasol)
- [systemd Timers](https://opensource.com/article/20/7/systemd-timers)
- Notes: projects/research-notes/notes.md
