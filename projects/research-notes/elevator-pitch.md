# Shopify DWH on Exasol — Elevator Pitch

**Audience:** Mixed tech/business (Exasol event)
**Duration:** 60-90 seconds spoken
**Date prepared:** 2026-03-06

---

## The Pitch

Shopify powers over 2 million stores, but getting analytics out of it is painful. The built-in reports are basic, the API gives you raw transactional data — nested line items, separate payment transactions, tax arrays — and there's no clean way to get that into a proper analytical model.

We're building a **configuration-driven Shopify data warehouse that runs natively on Exasol**.

You give it a YAML config — your payment methods, tax types, discount categories, fiscal calendar — and it generates a complete star schema with named, self-documenting columns. No generic "payment_1", "payment_2" columns. If you take PayFast and gift cards, you get `payment_payfast_amount` and `payment_gift_card_amount`. The schema fits your business, not the other way around.

Under the hood it's a **two-layer architecture**: a staging layer that mirrors the Shopify API, and a reporting layer optimised for Exasol — distribution keys on join columns, partition keys on date columns, small dimensions replicated across nodes. The ETL is lightweight Python using Shopify's bulk operations API and PyExasol. No Fivetran, no Airbyte, no licensing fees.

What makes this interesting for Exasol specifically: **star schemas are exactly what the columnar engine is built for**. Wide fact table scans, pre-aggregated metrics, denormalised dimensions — Exasol eats this for breakfast. We're not fighting the engine, we're designing for it.

The product covers **57 standard ecommerce metrics** out of the box — revenue, AOV, customer lifetime value, RFM segmentation, fulfilment timing, refund rates, inventory tracking — all with full data lineage back to the Shopify API fields they're derived from.

And because it's configuration-driven, deploying to a new merchant is a matter of hours, not weeks. Run the auto-discovery script against their store, generate the config, generate the schema, load the data.

We're running this in production for our own ecommerce business today, with a custom layer on top for B2B2C voucher analytics. The generic layer is designed to be **deployable to any Shopify merchant on Exasol**.

---

## Key Stats to Drop (if asked)

| Stat | Value |
|------|-------|
| Shopify merchants globally | 2M+ |
| Schema tables | 17 staging + 12 warehouse |
| Metrics out of the box | 57 (with full lineage) |
| Configuration elements | 20+ (payments, tax, discounts, segments, fiscal calendar, tags, regions) |
| ETL licensing cost | Zero (custom Python) |
| New merchant deployment | Hours, not weeks |
| Target market gap | No Exasol-native Shopify DWH product exists |

## Conversation Starters (follow-ups they might ask)

**"How is this different from Fivetran + dbt?"**
> Fivetran gives you raw Shopify data in a generic schema — you still need to build the warehouse model yourself. We generate the entire star schema, optimised for Exasol, from a config file. And Fivetran costs $500-10k/month in licensing alone.

**"Why Exasol and not Snowflake/BigQuery?"**
> Exasol's columnar engine with in-memory processing is ideal for star schema workloads — wide fact scans and aggregations are exactly what it's optimised for. Plus, for mid-market merchants who already run Exasol, this is a natural fit without adding another platform.

**"What does 'configuration-driven' actually mean?"**
> Every Shopify store is different — different payment gateways, tax structures, discount patterns. Instead of hardcoding these into the schema, we define them in YAML. The schema generator turns that into DDL with named columns. When the store adds a new payment method, you update the config and regenerate. No manual schema migration.

**"Can I see it?"**
> We have complete schema documentation, API mappings, and a productisation strategy. Happy to walk through the architecture — it's all designed and documented, with our own deployment running as proof of concept.

**"What about stores that aren't on Exasol?"**
> The design is Exasol-optimised but the star schema pattern is universal. The config-driven approach could generate DDL for other columnar databases. But our focus is Exasol-native — that's the gap in the market.
