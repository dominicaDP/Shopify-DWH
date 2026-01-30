# Customers API Research & Schema Validation

**Date:** 2026-01-30
**Project:** Shopify DWH
**Type:** research / validation

## What was completed

1. Researched Shopify GraphQL Customer object structure
2. Researched CustomerEmailAddress object (new pattern)
3. Identified deprecated fields and migration paths
4. Validated dim_customer schema against API
5. Documented ETL query example

## Key findings

### Deprecated Field Pattern

Shopify has deprecated several scalar fields in favor of object patterns:

| Deprecated | New Pattern |
|------------|-------------|
| `email` | `defaultEmailAddress.emailAddress` |
| `phone` | `defaultPhoneNumber.phoneNumber` |
| `emailMarketingConsent` | `defaultEmailAddress.marketingState` |
| `smsMarketingConsent` | `defaultPhoneNumber.marketingState` |
| `addresses` | `defaultAddress` (single) |

**ETL Impact:** Must use new object patterns to avoid building on deprecated fields.

### Marketing Consent Handling

Marketing consent is now a state machine with values:
- `NOT_SUBSCRIBED`, `PENDING`, `SUBSCRIBED`, `UNSUBSCRIBED`, `REDACTED`, `INVALID`

**ETL Logic for accepts_marketing:**
```
accepts_marketing = TRUE when marketingState IN ('SUBSCRIBED', 'PENDING')
```

### Schema Validation Results

**dim_customer:** All fields validated successfully

| Our Field | API Source | Notes |
|-----------|------------|-------|
| customer_id | id | Direct map |
| email | defaultEmailAddress.emailAddress | Use new pattern |
| first_name | firstName | Direct map |
| last_name | lastName | Direct map |
| phone | defaultPhoneNumber.phoneNumber | Use new pattern |
| accepts_marketing | marketingState (derived) | TRUE if SUBSCRIBED/PENDING |
| created_at | createdAt | Direct map |
| order_count | numberOfOrders | Direct map |
| total_spent | amountSpent.amount | MoneyV2 type |
| default_country | defaultAddress.country | Direct map |
| default_province | defaultAddress.province | Direct map |
| tags | tags (array→string) | Join with commas |

**Conclusion:** Current schema is sufficient for generic layer. No changes required.

## Patterns identified

### Shopify Deprecated Scalars → Object Pattern
**Confidence:** MEDIUM (documented in API, consistent pattern)

When extracting customer data, use the new object-based patterns instead of deprecated scalar fields. This applies to email, phone, and marketing consent.

## Schema impact

No changes needed - existing dim_customer schema covers all required fields.

**Optional additions (deferred):**
- `note` - Customer notes (internal use)
- `updated_at` - Change tracking
- `marketing_opt_in_level` - Single vs double opt-in

## Issues encountered

- None - API documentation was clear

## Next steps

Remaining generic layer research:
- Inventory domain schema decision
- Fulfillment API research
- Multi-currency handling decision

## Links

- [Customer Object](https://shopify.dev/docs/api/admin-graphql/latest/objects/Customer)
- [CustomerEmailAddress](https://shopify.dev/docs/api/admin-graphql/latest/objects/CustomerEmailAddress)
- Notes: projects/research-notes/notes.md
