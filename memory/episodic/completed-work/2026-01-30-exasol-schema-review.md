# Exasol Schema Review

**Date:** 2026-01-30
**Project:** Shopify DWH
**Type:** research / optimization

## What was completed

1. Reviewed existing schema against Exasol best practices
2. Defined distribution keys for all tables
3. Defined partition keys for fact tables
4. Assessed data type sizing
5. Documented replication border configuration
6. Created optimized DDL examples

## Key decisions

### Distribution Keys
| Table | Distribution Key | Rationale |
|-------|------------------|-----------|
| fact_order_line_item | order_key | Most common join |
| fact_order_header | customer_key | Customer analysis joins |
| Dimensions | (replicate) | Small tables auto-replicate |

### Partition Keys
| Table | Partition Key |
|-------|---------------|
| fact_order_line_item | order_date_key |
| fact_order_header | order_date_key |

### Data Type Changes
- dim_product.title: VARCHAR(500) → VARCHAR(255)
- dim_product.variant_title: VARCHAR(500) → VARCHAR(255)

## Patterns identified

### Exasol Star Schema Optimization
**Confidence:** LOW (first use)

Key principles:
1. **Distribution on JOIN columns** - Not WHERE columns
2. **Partition on WHERE columns** - For filtering
3. **Replication border** - Small dims auto-replicate
4. **No manual indexes** - Exasol auto-creates
5. **Surrogate keys** - BIGINT/INT faster than VARCHAR joins

### Staging vs DWH Tables
- Staging: No distribution (faster bulk loads)
- DWH: Proper distribution (faster queries)

## Schema changes made

1. Added Exasol-specific optimizations section to schema.md
2. Defined DISTRIBUTE BY for all tables
3. Defined PARTITION BY for fact tables
4. Created DDL reference with optimized syntax
5. Added performance monitoring queries

## Issues encountered

- None - Exasol documentation is comprehensive

## Next steps

- Create actual DDL scripts for deployment
- Set up staging schema (SHOPIFY_STG)
- Implement replication border configuration

## Links

- [Exasol Performance Best Practices](https://docs.exasol.com/db/latest/performance/best_practices.htm)
- [Exasol Data Types](https://docs.exasol.com/db/latest/sql_references/data_types/datatypedetails.htm)
- Schema: projects/research-notes/schema.md
