# Fulfillment API Research

**Date:** 2026-01-30
**Project:** Shopify DWH
**Type:** research

## What was completed

1. Researched Shopify GraphQL Fulfillment object hierarchy
2. Documented FulfillmentOrder vs Fulfillment distinction
3. Documented FulfillmentStatus and FulfillmentOrderStatus enums
4. Analyzed FulfillmentTrackingInfo for carrier data
5. Evaluated DWH design options for fulfillment data
6. Made recommendation for generic layer approach

## Key findings

### FulfillmentOrder vs Fulfillment

Critical distinction in Shopify's model:

| Object | Represents | When Created |
|--------|------------|--------------|
| **FulfillmentOrder** | What SHOULD be shipped (plan) | Auto-created when order placed |
| **Fulfillment** | What WAS shipped (actual) | Created when items ship |

**Hierarchy:**
```
Order
  └→ FulfillmentOrder[] (grouped by location)
       └→ Fulfillment[] (actual shipments)
            └→ FulfillmentLineItem[] (items in shipment)
```

### Status Enums

**FulfillmentOrderStatus** (7 values):
- OPEN, IN_PROGRESS, SCHEDULED, ON_HOLD, INCOMPLETE, CLOSED, CANCELLED

**FulfillmentStatus** (4 active):
- SUCCESS, CANCELLED, ERROR, FAILURE
- (Deprecated: OPEN, PENDING)

### Tracking Info Structure

```graphql
trackingInfo {
  company    # "DHL", "Aramex", etc.
  number     # Tracking number
  url        # Tracking URL
}
```

### DWH Design Decision

**Recommendation:** Option A - Use existing fulfillment flags

Current schema already has:
- `fact_order_line_item.is_fulfilled`
- `fact_order_header.is_fulfilled`, `is_partially_fulfilled`
- `dim_order.fulfillment_status`

**Backlogged:** Option B - fact_fulfillment table for:
- Carrier performance analytics
- Delivery time analysis
- Multi-location fulfillment tracking

## Patterns identified

### Shopify Plan vs Actual Pattern
**Confidence:** LOW (first use)

Shopify distinguishes between planned operations and actual executions:
- FulfillmentOrder = plan/intent
- Fulfillment = execution/result

This pattern appears in other Shopify domains (e.g., DiscountCode vs DiscountApplication).

## Schema impact

No changes needed for generic layer. Current flags sufficient.

**Future consideration (backlogged):**
```
fact_fulfillment
├── fulfillment_key
├── order_key
├── location_key (→ dim_location)
├── carrier_name
├── tracking_number
├── delivery_method_type
├── status
├── shipped_at
├── delivered_at
```

## Issues encountered

- None - API documentation was clear

## Next steps

Generic layer API research complete. Remaining decisions:
- Inventory domain schema (fact_inventory_level?)
- Multi-currency handling
- dim_time consideration
- View layer design

## Links

- [Fulfillment Object](https://shopify.dev/docs/api/admin-graphql/latest/objects/Fulfillment)
- [FulfillmentOrder Object](https://shopify.dev/docs/api/admin-graphql/latest/objects/FulfillmentOrder)
- Notes: projects/research-notes/notes.md
