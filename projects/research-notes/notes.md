# Notes

**Project:** Shopify DWH Research
**Last Updated:** 2026-01-29

---

## Research Log

### 2026-01-29 - Project Setup & Business Context

**Topic:** Dress Your Tech Business Model

**Key Understanding:**
- B2B2C model, NOT traditional ecommerce
- Primary revenue: voucher-based value-added products
- Corporate clients (e.g., telecoms) attach vouchers to their products
- End consumers redeem vouchers on Dress Your Tech
- Gamatek handles fulfillment

**Data Flow:**
```
Corporate Client → Issues Voucher → Consumer → Redeems on DYT → Order → Gamatek Fulfills
```

**Implications for DWH:**
- Need to track voucher issuance (from where?)
- Track redemption (Shopify orders with discount codes?)
- Attribution back to corporate clients
- Standard ecommerce metrics (AOV, conversion) less relevant

**Open Questions:**
- How are vouchers issued and tracked?
- What data comes from Shopify vs. other systems?
- How to identify which corporate client a redemption belongs to?

---

### 2026-01-29 - Second Brain Setup

**Topic:** Knowledge Management System

**What I learned:**
- Three-layer architecture: Commands → Skills → Memory
- Progressive disclosure pattern for managing complexity
- Pattern confidence levels (LOW → MEDIUM → HIGH)

**Key Commands:**
- `/overview` - Daily dashboard
- `/switch [project]` - Context switching
- `/learn` - Extract patterns from work
- `/recall [topic]` - Search memory
- `/grow` - Brain health metrics

---

## Shopify Data Notes

<!-- Capture Shopify-specific findings here -->

### Key Entities to Research
- Orders (redemptions)
- Products (mobile accessories)
- Customers (end consumers)
- Discount Codes (vouchers)
- Metafields (custom data?)

### API Considerations
- REST API vs GraphQL
- Rate limits
- Historical data access

---

## Code Snippets

<!-- Add useful code snippets here with context -->

### Template
```
### [Snippet Name]

**Language:**
**Use Case:**
**Source:**

\```[language]
// code
\```

**Notes:**
```

---

## Research Topics

### Active
- [ ] Shopify data model for Dress Your Tech
- [ ] Voucher/discount code tracking in Shopify
- [ ] DWH architecture patterns for ecommerce

### Completed
- [x] Initial system setup
- [x] Business context documentation

### Future
- [ ] ETL tool evaluation
- [ ] BI platform selection
- [ ] Data quality monitoring

---

## Ideas & Future Improvements

- [ ] Create Shopify API query templates
- [ ] Build voucher lifecycle tracking dashboard
- [ ] Develop corporate client attribution logic

---

## External References

- **Shopify API Docs:** https://shopify.dev/docs/api
- **Shopify Admin API:** https://shopify.dev/docs/api/admin
- **Second Brain system:** See CLAUDE.md

---

## Quick Capture

<!-- Use this section for quick notes during research sessions -->
<!-- Move organized content to appropriate sections above -->
