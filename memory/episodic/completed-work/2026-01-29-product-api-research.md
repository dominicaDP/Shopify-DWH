# Product API Research & Schema Update

**Date:** 2026-01-29
**Project:** Shopify DWH
**Type:** research

## What was completed

1. Researched Shopify Product API structure (REST Admin API)
2. Validated dim_product schema against API fields
3. Added 4 new fields to dim_product: option1, option2, option3, barcode
4. Documented API findings in project notes

## Key decisions

- **Added option1/2/3:** Variant attributes essential for product analysis (size, color, material)
- **Added barcode:** Standard identifier needed for Gamatek integration
- **Deferred handle:** URL slug rarely needed for analytics
- **Deferred updated_at:** ETL metadata (_loaded_at) sufficient

## Patterns identified

- **Cost data location:** Cost is NOT in Product API. Comes from InventoryItem resource via `Variant.inventory_item_id → InventoryItem.cost`. (MEDIUM confidence - verified in API docs)
- **REST deprecation:** REST Product API legacy as of Oct 2024, GraphQL required for new apps April 2025. Build ETL against GraphQL. (HIGH confidence - official Shopify announcement)

## Issues encountered

- Previous session got stuck during Product API research - no notes saved
- Resolution: Established practice to update tracking docs mid-session

## Next steps

- Research InventoryItem API for cost data extraction
- Continue with Discount/Voucher API research
- ETL tooling evaluation (GraphQL-focused)

## Links

- Shopify Product API: https://shopify.dev/docs/api/admin-rest/2024-01/resources/product
- Schema: projects/research-notes/schema.md
- Notes: projects/research-notes/notes.md
