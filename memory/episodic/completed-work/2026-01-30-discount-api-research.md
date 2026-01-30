# Discount/Voucher API Research

**Date:** 2026-01-30
**Project:** Shopify DWH
**Type:** research

## What was completed

1. Researched Shopify GraphQL Admin API discount system architecture
2. Documented all discount code types (Basic, BXGY, FreeShipping, App)
3. Understood redemption tracking via DiscountRedeemCode.asyncUsageCount
4. Mapped DiscountApplication structure on orders
5. Validated current dim_discount schema against API capabilities

## Key findings

### Discount Types
| Type | Use Case |
|------|----------|
| DiscountCodeBasic | Fixed amount or % off products |
| DiscountCodeBxgy | Buy X Get Y promotions |
| DiscountCodeFreeShipping | Free/reduced shipping |
| DiscountCodeApp | Custom app-defined |

### Redemption Tracking
- `DiscountRedeemCode.asyncUsageCount` - Count of times code was used
- Updated asynchronously (not real-time)
- Each code has unique ID + code string

### Discount Value Types
- `MoneyV2` - Fixed amount { amount, currencyCode }
- `PricingPercentageValue` - Percentage { percentage }
- Determined by union type `PricingValue`

### On Orders
- `discountCodes` - Array of codes applied
- `discountApplications` - Interface showing allocation method, target, value
- `totalDiscountsSet` - Total discount amount

### On Line Items
- `discountAllocations` - How discount was distributed to line
- `originalTotalSet` vs `discountedTotalSet` - For calculating discount impact

## Patterns identified

- **Union Types for Flexibility:** Shopify uses union types (PricingValue) to handle different value formats - allows same field to represent amount OR percentage
- **Application vs Definition:** Discount "definitions" (DiscountCodeBasic) are separate from "applications" (DiscountCodeApplication) - captures intent at time of application

## Schema assessment

**Current dim_discount fields - all valid:**
- discount_key, discount_code, discount_type, value, value_type, target_type, allocation_method

**Potential enhancements:**
- title (discount name)
- usage_limit / usage_count (for redemption analytics)
- starts_at / ends_at (validity period)

## B2B2C implications

- Shopify discount codes = business vouchers
- Can track redemptions via asyncUsageCount
- Corporate client attribution NOT available in Shopify
- Layer 2 requirement: external data source for client-voucher mapping

## Issues encountered

- Some Shopify GraphQL docs URLs returned 404 (object vs interface naming)
- Workaround: Used search to find correct URLs

## Next steps

- Consider dim_discount schema enhancements
- Research Orders API structure
- Continue with ETL tooling evaluation

## Links

- [DiscountCodeBasic](https://shopify.dev/docs/api/admin-graphql/latest/objects/DiscountCodeBasic)
- [DiscountRedeemCode](https://shopify.dev/docs/api/admin-graphql/latest/objects/discountredeemcode)
- [Discounts Overview](https://shopify.dev/docs/apps/build/discounts)
- Notes: projects/research-notes/notes.md
