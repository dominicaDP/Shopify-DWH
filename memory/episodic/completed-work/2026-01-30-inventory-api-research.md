# InventoryItem API Research

**Date:** 2026-01-30
**Project:** Shopify DWH
**Type:** research

## What was completed

1. Researched Shopify GraphQL Admin API for inventory-related objects
2. Documented InventoryItem, InventoryLevel, and InventoryQuantity structures
3. Identified cost data extraction path (ProductVariant → InventoryItem → unitCost)
4. Understood multi-location inventory model (InventoryLevel per item per location)
5. Documented bulk operation support for large data extraction

## Key findings

### Cost Data Path
```
Product
  └→ Variant
       └→ inventoryItem
            └→ unitCost { amount, currencyCode }
```
- unitCost is MoneyV2 type (amount as decimal string + ISO currency code)
- Need to handle multi-currency if store operates in multiple currencies

### Inventory Levels (Stock Quantities)
```
InventoryItem
  └→ inventoryLevels (per location)
       └→ quantities (named states)
            ├→ available
            ├→ on_hand
            ├→ committed
            ├→ incoming
            └→ (etc.)
```
- Grain: one InventoryLevel per InventoryItem per Location
- Quantities are normalized: InventoryQuantity has `name` and `quantity` fields

### Bulk Operations
- Use `bulkOperationRunQuery` for large extracts
- Output: JSONL format
- Results retained 7 days
- Limit: 1 bulk query + 1 bulk mutation per shop at a time

## Patterns identified

- **API Object Relationships:** Shopify uses object references rather than IDs for GraphQL traversal (e.g., `variant.inventoryItem` not `variant.inventoryItemId`)
- **Normalized Quantity States:** Rather than separate fields for each state, Shopify uses a normalized `quantities` array with name/value pairs - more flexible for API evolution

## Schema implications

- `dim_product.cost` field is correctly nullable - will be populated during ETL via InventoryItem join
- If multi-location inventory needed later: add dim_location + fact_inventory_level
- Multi-currency consideration: may need to store both raw amount + currency, plus converted amount in base currency

## Issues encountered

- None - API documentation was clear

## Next steps

- Continue with Discount/Voucher API research
- Or evaluate ETL tooling options (GraphQL-focused)

## Links

- Shopify InventoryItem: https://shopify.dev/docs/api/admin-graphql/latest/objects/InventoryItem
- Shopify InventoryLevel: https://shopify.dev/docs/api/admin-graphql/latest/objects/InventoryLevel
- Bulk Operations: https://shopify.dev/docs/api/admin-graphql/latest/mutations/bulkOperationRunQuery
- Notes: projects/research-notes/notes.md
