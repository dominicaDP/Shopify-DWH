# Shopify DWH Implementation Guide

**Version:** 1.0
**Last Updated:** 2026-01-30

Quick reference for implementing the generic Shopify DWH.

---

## Architecture Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Shopify Store  │────▶│  Python ETL     │────▶│     Exasol      │
│  (GraphQL API)  │     │  (systemd timer)│     │   (Star Schema) │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

**Stack:**
- Source: Shopify GraphQL Admin API
- ETL: Python 3.10+ with PyExasol 2.0
- Scheduler: systemd timers
- Target: Exasol (columnar)

---

## Schema Summary

### Fact Tables

| Table | Grain | Rows/Month Est |
|-------|-------|----------------|
| fact_order_line_item | Line item | ~10k |
| fact_order_header | Order | ~3k |

### Dimensions

| Table | Type | Est Rows | Replicate |
|-------|------|----------|-----------|
| dim_date | Conformed | 3,650 | Yes |
| dim_customer | SCD1 | <50k | Yes |
| dim_product | SCD1 | <10k | Yes |
| dim_geography | SCD1 | <10k | Yes |
| dim_order | SCD1 | <50k | Yes |
| dim_discount | SCD1 | <1k | Yes |
| dim_location | SCD1 | <100 | Yes |

---

## ETL Jobs

### Job Schedule

| Job | Frequency | Type | Priority |
|-----|-----------|------|----------|
| Full Product Sync | Daily 02:00 | Bulk | HIGH |
| Incremental Orders | Every 6h | Filtered | HIGH |
| Incremental Customers | Every 6h | Filtered | MEDIUM |
| Discount Codes | Daily 03:00 | Standard | LOW |
| Locations | Weekly | Standard | LOW |

### Extraction Patterns

**Bulk Operations (Full Loads):**
```python
# Submit bulk query
mutation = """
mutation {
  bulkOperationRunQuery(query: "{ products { edges { node { ... } } } }") {
    bulkOperation { id status }
  }
}
"""

# Poll for completion
query = """
{ currentBulkOperation { id status url } }
"""

# Download JSONL when complete
# Parse line-by-line (memory efficient)
```

**Incremental Loads:**
```python
# Get orders updated since last sync
query = """
query($since: DateTime!) {
  orders(query: "updated_at:>$since", first: 250) {
    edges { node { ... } }
    pageInfo { hasNextPage endCursor }
  }
}
"""
```

### Load Pattern

```
1. Extract from Shopify → JSONL files
2. Load to staging (SHOPIFY_STG)
3. Transform staging → DWH (SHOPIFY_DWH)
4. Update ETL state table
```

---

## Exasol Configuration

### Create Schemas

```sql
CREATE SCHEMA IF NOT EXISTS SHOPIFY_STG;
CREATE SCHEMA IF NOT EXISTS SHOPIFY_DWH;
```

### Replication Border

```sql
-- Ensure dimensions replicate (default 100k is fine)
SELECT parameter_name, parameter_value
FROM exa_parameters
WHERE parameter_name = 'REPLICATION_BORDER';
```

### Key DDL Examples

```sql
-- Fact table with distribution and partition
CREATE TABLE SHOPIFY_DWH.fact_order_line_item (
    line_item_key       BIGINT NOT NULL,
    order_key           BIGINT NOT NULL,
    product_key         BIGINT NOT NULL,
    customer_key        BIGINT,
    order_date_key      INT NOT NULL,
    -- ... other columns ...
    PRIMARY KEY (line_item_key)
)
DISTRIBUTE BY order_key
PARTITION BY order_date_key;

-- Dimension (no partition, will auto-replicate)
CREATE TABLE SHOPIFY_DWH.dim_customer (
    customer_key        BIGINT NOT NULL,
    customer_id         VARCHAR(50) NOT NULL,
    -- ... other columns ...
    PRIMARY KEY (customer_key)
)
DISTRIBUTE BY customer_key;

-- Staging table (simple, no distribution)
CREATE TABLE SHOPIFY_STG.stg_orders (
    raw_json            VARCHAR(2000000),
    loaded_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### ETL State Table

```sql
CREATE TABLE SHOPIFY_STG._etl_state (
    entity              VARCHAR(50) PRIMARY KEY,
    last_sync_at        TIMESTAMP,
    last_run_status     VARCHAR(20),
    records_processed   INT,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Initialize
INSERT INTO SHOPIFY_STG._etl_state (entity, last_sync_at, last_run_status)
VALUES
    ('orders', '2020-01-01', 'INIT'),
    ('customers', '2020-01-01', 'INIT'),
    ('products', '2020-01-01', 'INIT');
```

---

## Python Project Structure

```
/opt/shopify-etl/
├── main.py                    # Entry point
├── config.yaml                # Non-sensitive config
├── .env                       # Credentials (gitignored)
├── requirements.txt
├── src/
│   ├── __init__.py
│   ├── shopify_client.py      # GraphQL client
│   ├── exasol_loader.py       # PyExasol wrapper
│   ├── transformers/          # Staging → DWH
│   │   ├── orders.py
│   │   ├── customers.py
│   │   └── products.py
│   └── jobs/                  # Scheduled jobs
│       ├── full_product_sync.py
│       ├── incremental_orders.py
│       └── incremental_customers.py
└── sql/
    ├── staging/               # Staging DDL
    └── dwh/                   # DWH DDL + transforms
```

### requirements.txt

```
pyexasol>=0.26.0
requests>=2.28.0
tenacity>=8.2.0
python-dotenv>=1.0.0
pyyaml>=6.0
```

### .env Template

```bash
# Shopify
SHOPIFY_STORE=your-store.myshopify.com
SHOPIFY_ACCESS_TOKEN=shpat_xxxxx

# Exasol
EXASOL_HOST=localhost
EXASOL_PORT=8563
EXASOL_USER=etl_user
EXASOL_PASSWORD=xxxxx
EXASOL_SCHEMA=SHOPIFY_DWH
```

---

## systemd Configuration

### Service File

`/etc/systemd/system/shopify-etl-orders.service`:
```ini
[Unit]
Description=Shopify Orders ETL
After=network.target

[Service]
Type=oneshot
User=etl
WorkingDirectory=/opt/shopify-etl
ExecStart=/opt/shopify-etl/venv/bin/python main.py orders
EnvironmentFile=/opt/shopify-etl/.env
StandardOutput=journal
StandardError=journal
MemoryMax=2G
CPUQuota=80%
```

### Timer File

`/etc/systemd/system/shopify-etl-orders.timer`:
```ini
[Unit]
Description=Run Shopify Orders ETL every 6 hours

[Timer]
OnCalendar=*-*-* 00,06,12,18:00:00
Persistent=true
RandomizedDelaySec=300

[Install]
WantedBy=timers.target
```

### Enable Timer

```bash
systemctl daemon-reload
systemctl enable shopify-etl-orders.timer
systemctl start shopify-etl-orders.timer
systemctl list-timers
```

---

## Key Decisions Reference

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Schema type | Star schema | Exasol-optimized, productizable |
| Fact grain | Line item | Flexible, standard retail |
| Product grain | Variant level | Enables option analysis |
| API | GraphQL | REST deprecated |
| ETL | Custom Python | Zero licensing cost |
| Scheduler | systemd timers | Single instance, catch-up |
| Currency | shopMoney only | Simpler, consistent |
| Fulfillment | Flags only | fact_fulfillment backlogged |
| Inventory | dim_location only | fact_inventory backlogged |

---

## Implementation Phases

### Phase 1: Foundation
- [ ] Create Exasol schemas (STG + DWH)
- [ ] Create dim_date (pre-populate)
- [ ] Set up Python project structure
- [ ] Implement Shopify GraphQL client
- [ ] Implement PyExasol loader utilities

### Phase 2: Products
- [ ] Create dim_product DDL
- [ ] Implement bulk product extraction
- [ ] Implement product transformer
- [ ] Test full product sync

### Phase 3: Orders
- [ ] Create fact tables DDL
- [ ] Create dim_order, dim_geography, dim_discount DDL
- [ ] Implement orders extraction (bulk + incremental)
- [ ] Implement order transformer
- [ ] Test order sync

### Phase 4: Customers
- [ ] Create dim_customer DDL
- [ ] Implement customer extraction
- [ ] Implement customer transformer
- [ ] Test customer sync

### Phase 5: Production
- [ ] Create dim_location DDL
- [ ] Configure systemd timers
- [ ] Add error handling & retries
- [ ] Add monitoring & alerting
- [ ] Documentation

---

## Quick Reference Links

- [Schema Definition](schema.md)
- [API Field Mapping](api-mapping.md)
- [Research Notes](notes.md)
- [Shopify GraphQL Docs](https://shopify.dev/docs/api/admin-graphql)
- [PyExasol Docs](https://github.com/exasol/pyexasol)
