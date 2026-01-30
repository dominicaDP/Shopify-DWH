# Orders API Research & Schema Validation

**Date:** 2026-01-30
**Project:** Shopify DWH
**Type:** research / validation

## What was completed

1. Researched Shopify GraphQL Order object structure
2. Researched LineItem object structure
3. Researched Refund object structure
4. Understood MoneyBag dual-currency pattern
5. Validated fact_order_line_item schema against API
6. Validated fact_order_header schema against API
7. Created ETL query example for bulk export

## Key findings

### MoneyBag Pattern
All financial fields in Shopify return MoneyBag with two currencies:
- `shopMoney` - Merchant's base currency (use this for DWH)
- `presentmentMoney` - Customer's display currency

```graphql
totalPriceSet {
  shopMoney { amount currencyCode }
  presentmentMoney { amount currencyCode }
}
```

**Decision:** Use `shopMoney.amount` for all DWH financial fields.

### Schema Validation Results

**fact_order_line_item:** ✓ All fields map correctly
- `line_tax_amount` needs aggregation from `taxLines` array
- `is_fulfilled` derived from `unfulfilledQuantity == 0`
- `is_refunded` derived from `currentQuantity < quantity`

**fact_order_header:** ✓ All fields map correctly
- Direct mapping to `*Set.shopMoney.amount` fields

### Deprecated Fields
Must avoid scalar fields, use `*Set` variants:
- ❌ totalPrice → ✓ totalPriceSet
- ❌ subtotalPrice → ✓ subtotalPriceSet
- etc.

## Patterns identified

### MoneyBag for Multi-Currency
**Confidence:** MEDIUM (verified in official docs)

Shopify uses MoneyBag pattern for all monetary values:
- Always has shopMoney (merchant currency)
- Always has presentmentMoney (customer currency)
- For DWH, consistently use shopMoney

### Derived Boolean Flags
Some statuses aren't direct fields, must be derived:
- `is_fulfilled` = unfulfilledQuantity == 0
- `is_refunded` = currentQuantity < quantity

## Schema impact

No changes needed to existing schema - validation passed.

**Potential additions (low priority):**
- `currency_code` on fact_order_header (for multi-currency analysis)
- `is_test_order` flag (to filter test data)

## Issues encountered

- None - API structure matches our design well

## Next steps

- Ready to start ETL implementation
- First job: Products sync (simpler, establishes patterns)
- Then: Orders sync (validated today)

## Links

- [Order Object](https://shopify.dev/docs/api/admin-graphql/latest/objects/Order)
- [LineItem Object](https://shopify.dev/docs/api/admin-graphql/latest/objects/LineItem)
- [Orders Query](https://shopify.dev/docs/api/admin-graphql/latest/queries/orders)
- Notes: projects/research-notes/notes.md
