"""STG loaders (Phase B). One module per extraction shape.

Each loader owns its Shopify GraphQL query + node->row mapping, and delegates the
DB write to shopify_dwh.exasol_loader (load_full / merge_upsert). Port the POC
loaders (load_products / load_variants / load_orders / load_line_items) here first,
then add the remaining 13 STG tables per schema-layered.md.
"""
