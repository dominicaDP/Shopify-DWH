-- =============================================================================
-- Phase E — distribution keys (OPTIONAL, apply after the first full load)
--
-- NOT part of the unattended pipeline and NOT needed at DYT's current volume
-- (< single-digit GB — see ddl/README.md). Exasol auto-distributes well enough
-- that these only matter once the order/line tables are large enough for the
-- order-key join to spill. Apply then, measure, and DROP if they don't help.
--
-- Rationale: the hot joins are all on the order id —
--   transform:  stg_order_line_items.order_id  =  stg_orders.id
--   DWH query:  fact_order_line_item.order_id   =  fact_order.order_id
-- Co-locating both sides of each join on that key removes the shuffle.
--
-- Apply:   python -m shopify_dwh.ddl_runner ddl/09_distribution_keys.sql
-- Revert:  ALTER TABLE <t> DROP DISTRIBUTION KEYS;   (one per table)
-- =============================================================================

-- STG order-grain tables (co-locate the line-items -> orders transform join)
ALTER TABLE SHOPIFY_STG.stg_orders            DISTRIBUTE BY id;
ALTER TABLE SHOPIFY_STG.stg_order_line_items  DISTRIBUTE BY order_id;

-- DWH order-grain facts (co-locate the line-item -> order reporting join)
ALTER TABLE SHOPIFY_DWH.fact_order            DISTRIBUTE BY order_id;
ALTER TABLE SHOPIFY_DWH.fact_order_line_item  DISTRIBUTE BY order_id;
