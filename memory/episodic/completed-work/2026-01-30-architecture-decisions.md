# Architecture Decisions Session - 2026-01-30

## Context
**Project:** Shopify DWH
**Goal:** Complete generic layer documentation with proper architecture decisions
**Duration:** ~3 hours

## What Happened

Comprehensive session covering multiple aspects of the Shopify DWH design:

1. **API Mapping Enhancements**
   - Added GraphQL endpoint references to all table mappings
   - Added 13 transformation types with code examples
   - Clarified GraphQL single-endpoint model vs REST multiple endpoints

2. **Schema Redesign (STG + DWH)**
   - Identified that original star schema was too source-like
   - User insight: "If order has multiple payments as rows, we want columns"
   - Redesigned with two layers: STG (mirrors API) → DWH (reporting-optimized)
   - Created schema-layered.md with pivot transformations

3. **Lakehouse vs Warehouse Evaluation**
   - Researched data lakehouse architecture
   - Compared against our requirements
   - Confirmed warehouse is correct choice for this use case

## Key Insights

### 1. DWH Should Be Reporting-First
Don't design DWH to be a "clean" version of the source. Design it for how consumers will use it.

### 2. Lakehouse Wasn't Needed
Surprised to confirm that trendy lakehouse architecture would be overkill:
- No unstructured data
- No ML/AI requirements
- Single source (Shopify API)
- Existing Exasol infrastructure

### 3. Document Transformations Upfront
The 13 transformation types (GID extraction, pivots, etc.) should be defined before implementation, not discovered during coding.

## Patterns Applied
- **Two-Layer DWH Architecture** (new) - STG mirrors source, DWH is reporting-optimized
- **Pivot Transformation** (new) - rows to columns for multi-value arrays
- **Mid-Session Checkpointing** - documented as we went

## Patterns Extracted
- **Architecture Selection (Warehouse vs Lakehouse)** - decision framework

## Outcome
**Result:** SUCCESS
**Quality:** High - comprehensive documentation, clear architecture

## Learnings for Next Time
1. Design for reporting first, not source structure
2. Ask "what does the consumer need?" earlier in design phase
3. Document transformations upfront - they're a significant part of the design
4. Don't adopt trendy architecture (lakehouse) without clear problem it solves

## Artifacts Created
- `schema-layered.md` - Two-layer schema definition
- `Shopify-DWH-Schema-Layered.docx` - Word document for review
- Updated `api-mapping.md` with transformations and GraphQL clarification
- Updated `Shopify-DWH-API-Mapping.docx`

## Linked Patterns
→ New: Architecture Selection (Warehouse vs Lakehouse)
→ Reinforced: Two-Layer DWH Architecture
→ Reinforced: Mid-Session Checkpointing

## User Feedback
- Key insight confirmed: "DWH should be reporting-optimized from the start"
- Surprised by: Lakehouse wasn't needed for this use case
- Will do differently: Design for reporting first, ask consumer needs earlier, document transformations upfront
- Confidence level: Medium - need to review docs before implementation
