# Architecture Decisions

**Last Updated:** 2026-01-30

---

## Tech Stack Overview

### Shopify DWH Project

| Category | Technology | Notes |
|----------|------------|-------|
| Source | Shopify Admin API | Use GraphQL (REST deprecated) |
| Target DWH | Exasol | Columnar database |
| Schema | Star schema | See ADR-001 |
| ETL | Custom Python + PyExasol | See ADR-004 |
| Scheduler | systemd timers | On Linux/Exasol server |

---

## Architecture Decision Records (ADRs)

### ADR-001: Star Schema for DWH Modeling

**Date:** 2026-01-29
**Status:** Accepted
**Deciders:** Dominic

**Context:**
Need to choose data modeling approach for Shopify DWH. Must be productizable (generic for any Shopify store) and optimized for Exasol.

**Decision:**
Use star schema with line-item grain fact tables.

**Consequences:**
- **Positive:** Exasol optimized for star schema, BI tools expect it, customers understand it, solo-developer friendly
- **Negative:** Less flexible for schema evolution than Data Vault
- **Neutral:** Appropriate complexity for single-source DWH

**Alternatives Considered:**
1. Data Vault - Rejected: Over-engineered for single source, high build complexity
2. Snowflake schema - Rejected: No advantage over star, more joins
3. One Big Table (OBT) - Rejected: Doesn't scale with scope
4. Activity Schema - Rejected: Wrong paradigm for Shopify's data structure

---

### ADR-002: GraphQL API for Data Extraction

**Date:** 2026-01-29
**Status:** Accepted
**Deciders:** Dominic

**Context:**
Shopify offers both REST and GraphQL Admin APIs. REST is being deprecated.

**Decision:**
Build ETL against GraphQL Admin API from the start.

**Consequences:**
- **Positive:** Future-proof, REST deprecated Oct 2024, required for new apps April 2025
- **Negative:** Slightly more complex query structure than REST
- **Neutral:** Better rate limiting model (cost-based vs call-based)

**Alternatives Considered:**
1. REST API - Rejected: Being deprecated, would require migration later

---

### ADR-003: Variant-Level Product Dimension

**Date:** 2026-01-29
**Status:** Accepted
**Deciders:** Dominic

**Context:**
Shopify products have nested variants. Need to decide dimension grain.

**Decision:**
dim_product at variant level (one row per variant, not per product).

**Consequences:**
- **Positive:** Enables variant-level analysis, includes option1/2/3 attributes
- **Negative:** More rows than product-level grain
- **Neutral:** Standard approach for retail DWH

**Key Fields Added:**
- option1/2/3 for variant attributes (Size, Color, Material)
- barcode for inventory/fulfillment matching

---

### ADR-004: Custom Python ETL with PyExasol

**Date:** 2026-01-30
**Status:** Accepted
**Deciders:** Dominic

**Context:**
Need ETL solution to move data from Shopify GraphQL API to Exasol. Must be cost-effective and run on existing infrastructure (Linux server hosting Exasol).

**Decision:**
Build custom Python ETL using:
- PyExasol 2.0 for Exasol connectivity
- Shopify GraphQL bulk operations for full loads
- Incremental queries for updates
- systemd timers for scheduling

**Consequences:**
- **Positive:** Zero licensing cost, full control, runs on existing infrastructure, productizable
- **Negative:** Development effort required, maintenance responsibility
- **Neutral:** Python 3.10+ required for PyExasol 2.0

**Alternatives Considered:**
1. Fivetran - Rejected: Cost prohibitive ($500-$10k+/mo), 40-70% price increase in 2025
2. Airbyte Cloud - Rejected: Still adds ongoing cost, external dependency
3. Airbyte Self-Hosted - Rejected: Heavy infrastructure (Docker/K8s), overkill for single source

**Implementation Notes:**
- Use `bulkOperationRunQuery` for full loads (async, JSONL output)
- Use filtered queries with `updated_at` for incremental loads
- systemd timers preferred over cron (single instance guarantee, Persistent=true)

---

## Patterns Learned

### Shopify API Patterns

| Pattern | Confidence | Notes |
|---------|------------|-------|
| Cost from InventoryItem | MEDIUM | `Variant.inventory_item_id → InventoryItem.cost` |
| REST deprecation | HIGH | Build on GraphQL, REST legacy Oct 2024 |

---

## Evolution Notes

### 2026-01-30 - ETL Decision
- Decided on custom Python ETL (rejected Fivetran/Airbyte due to cost)
- Selected PyExasol for fast bulk loading
- Selected systemd timers for scheduling
- Documented bulk operations workflow for Shopify extraction

### 2026-01-29 - Initial Setup
- Established star schema approach
- Defined Orders domain (2 facts, 6 dimensions)
- Researched Product API, updated dim_product with variant attributes
