# Phase 4: Natural Language Analytics Layer — Exploration

**Status:** Idea / Exploration
**Last Updated:** 2026-03-06
**Reference:** [Exasol AI Text Summary Documentation](https://exasol.github.io/developer-documentation/main/gen_ai/ai_text_summary/index.html)

---

## Vision

Turn the Shopify DWH from "data team builds reports" into "anyone can ask questions." End users (Finance, Exco, channel managers) interact with the DWH in plain English — no SQL required.

**Key constraint:** Data stays on-premises. No cloud LLM APIs. Self-hosted model running alongside Exasol.

---

## How It Works (Exasol + Ollama)

```
End User
  |
  | "How did Vodacom perform this month?"
  v
Exasol Python UDF
  |
  | 1. Runs pre-built SQL to pull relevant data
  | 2. Formats data as context for LLM
  | 3. Sends prompt + context to Ollama via HTTP
  |
  v
Ollama (Self-Hosted LLM)
  |
  | Mistral 7B (or similar)
  | Running on same Linux server as Exasol
  | Apache 2.0 licensed — no cost
  |
  v
Natural Language Response
  "Vodacom distributed 3,200 vouchers in February,
   with a 67% redemption rate (up 4% from January).
   Overspend averaged R120 per order."
```

**Infrastructure:** Ollama runs on the existing Exasol Linux server. No additional hardware needed for Mistral 7B (~4GB model). Communication via local HTTP (not localhost — Exasol Docker needs machine IP).

---

## Three Use Cases

### 1. Data Summarisation (Easiest — Start Here)

Generate narrative summaries from pre-aggregated data. No SQL generation needed — the UDF runs a fixed query and asks the LLM to narrate the results.

**Example: Channel Performance Summary**

```sql
-- UDF that summarises a channel's monthly performance
SELECT
    channel_name,
    SHOPIFY_DWH.SUMMARIZE_CHANNEL_PERFORMANCE(
        'OLLAMA_CONNECTION',
        channel_name,
        vouchers_distributed,
        vouchers_redeemed,
        redemption_rate,
        overspend_total,
        face_value_redeemed
    ) AS performance_summary
FROM DYT_DWH.fact_channel_daily_monthly_agg
WHERE month = 2 AND year = 2026;
```

**Output:**
| channel_name | performance_summary |
|---|---|
| Vodacom | Vodacom distributed 3,200 vouchers in February with a 67% redemption rate, up 4pp from January. Total face value redeemed was R480K with R384K in overspend, indicating strong upsell. |
| Telkom | Telkom had a quieter month with 1,800 distributions and 52% redemption. Overspend was below average at R65 per order. Subscription vouchers made up 70% of volume. |

**UDF Implementation:**

```python
CREATE OR REPLACE PYTHON3 SCALAR SCRIPT DEMO.SUMMARIZE_CHANNEL_PERFORMANCE(
    connection_name VARCHAR(200),
    channel_name VARCHAR(255),
    distributed INT,
    redeemed INT,
    redemption_rate DECIMAL(5,2),
    overspend DECIMAL(18,2),
    face_value DECIMAL(18,2)
)
RETURNS VARCHAR(2000) AS
import requests
import json

def run(ctx):
    conn_info = exa.get_connection(ctx.connection_name)

    data_context = (
        f"Channel: {ctx.channel_name}\n"
        f"Vouchers Distributed: {ctx.distributed}\n"
        f"Vouchers Redeemed: {ctx.redeemed}\n"
        f"Redemption Rate: {ctx.redemption_rate}%\n"
        f"Overspend (customer spend beyond voucher): R{ctx.overspend:,.0f}\n"
        f"Face Value Redeemed: R{ctx.face_value:,.0f}\n"
    )

    prompt = (
        "You are a business analyst. Summarise this channel's monthly "
        "voucher performance in 2-3 sentences. Highlight trends, flag "
        "anything unusual, and use business-friendly language. "
        "Use South African Rand (R) for currency.\n\n"
        f"{data_context}"
    )

    try:
        payload = {
            'model': 'mistral:latest',
            'prompt': prompt,
            'stream': False,
            'options': {
                'temperature': 0.3,
                'num_predict': 150
            }
        }
        response = requests.post(conn_info.address, json=payload, timeout=30)
        response.raise_for_status()
        return response.json()['response'].strip()
    except Exception as e:
        return f'ERROR: {str(e)}'
/
```

**Other summarisation ideas:**
- Daily Exco briefing: "Here's what happened across all channels yesterday"
- Weekly product performance: "Top 5 products by revenue, with trend commentary"
- Anomaly alerts: "Telkom redemptions dropped 30% on Tuesday — here's the context"

---

### 2. Natural Language to SQL (Medium Difficulty)

User asks a question in English, LLM generates SQL, Exasol executes it, LLM narrates the result.

**Example:**

User: "Which channel had the highest redemption rate last week?"

```
Step 1: LLM generates SQL
  SELECT channel_name, redemption_rate
  FROM DYT_DWH.fact_channel_daily
  WHERE date_key BETWEEN 20260223 AND 20260301
  ORDER BY redemption_rate DESC
  LIMIT 1;

Step 2: Exasol executes → "FNB, 78.3%"

Step 3: LLM narrates → "FNB had the highest redemption rate last week
  at 78.3%, significantly above the average of 61%."
```

**Implementation approach:**

```python
CREATE OR REPLACE PYTHON3 SCALAR SCRIPT DEMO.ASK_DWH(
    connection_name VARCHAR(200),
    question VARCHAR(2000)
)
RETURNS VARCHAR(5000) AS
import requests
import json

SCHEMA_CONTEXT = """
Available tables and columns:

DYT_DWH.fact_channel_daily:
  channel_key, date_key, channel_name,
  vouchers_created, vouchers_distributed, vouchers_redeemed, vouchers_expired,
  face_value_created, face_value_distributed, face_value_redeemed,
  redemption_order_revenue, overspend_total, breakage_total,
  cumulative_created, cumulative_distributed, cumulative_redeemed,
  outstanding_distributed, distribution_rate, redemption_rate

DYT_DWH.dim_channel:
  channel_key, channel_id, channel_name, industry, is_active

SHOPIFY_DWH.dim_date:
  date_key (YYYYMMDD format), full_date, year, quarter, month, month_name,
  week_of_year, day_of_month, day_name, is_weekend

Currency is South African Rand (R). Today's date is available via CURRENT_DATE.
"""

def run(ctx):
    conn_info = exa.get_connection(ctx.connection_name)

    prompt = (
        "You are a SQL expert for an Exasol data warehouse. "
        "Generate a single SELECT query to answer the user's question. "
        "Return ONLY the SQL query, no explanation.\n\n"
        f"Schema:\n{SCHEMA_CONTEXT}\n\n"
        f"Question: {ctx.question}\n\n"
        "SQL:"
    )

    try:
        payload = {
            'model': 'mistral:latest',
            'prompt': prompt,
            'stream': False,
            'options': {'temperature': 0.1, 'num_predict': 300}
        }
        response = requests.post(conn_info.address, json=payload, timeout=30)
        response.raise_for_status()
        generated_sql = response.json()['response'].strip()

        # SAFETY: Only allow SELECT statements
        if not generated_sql.upper().startswith('SELECT'):
            return 'ERROR: Only SELECT queries are allowed.'

        return f"Generated SQL:\n{generated_sql}"
    except Exception as e:
        return f'ERROR: {str(e)}'
/
```

**Important safety considerations:**
- Only allow SELECT (never INSERT/UPDATE/DELETE/DROP)
- Run with a read-only database user
- Validate generated SQL before execution
- Rate limit to prevent abuse
- Log all generated queries for audit

---

### 3. Anomaly Narration (Advanced)

Detect statistical anomalies in the data, pull surrounding context, and have the LLM explain what happened in plain English.

**Example flow:**

```sql
-- Step 1: Detect anomalies (pure SQL — no LLM needed)
SELECT
    channel_name,
    date_key,
    vouchers_redeemed,
    AVG(vouchers_redeemed) OVER (
        PARTITION BY channel_key
        ORDER BY date_key
        ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING
    ) AS avg_7d,
    vouchers_redeemed / NULLIF(avg_7d, 0) AS ratio
FROM DYT_DWH.fact_channel_daily
WHERE ratio < 0.5 OR ratio > 2.0;  -- 50% below or 100% above average

-- Step 2: For each anomaly, gather context and ask LLM to explain
SELECT
    DEMO.EXPLAIN_ANOMALY(
        'OLLAMA_CONNECTION',
        channel_name,
        date_key,
        'vouchers_redeemed',
        vouchers_redeemed,
        avg_7d,
        -- Pass additional context: was it a weekend? public holiday? etc.
        day_name,
        is_weekend
    ) AS explanation
FROM anomalies;
```

**Output:** "Telkom redemptions dropped to 45 on Tuesday (vs 7-day average of 120). This was not a weekend or holiday. Possible causes: distribution delay, SMS delivery issue, or campaign end. Recommend checking stg_voucher_distributions for Tuesday's SMS delivery rates."

---

## POC Plan

### Phase 4a: Proof of Concept (1-2 days)

1. Install Ollama on the Exasol Linux server
2. Pull Mistral 7B (`ollama pull mistral`)
3. Create the Exasol connection object
4. Build one summarisation UDF (channel performance)
5. Test against fact_channel_daily with 5 channels
6. Measure latency and quality

**Success criteria:**
- UDF runs in < 5 seconds per summary
- Output is coherent and business-appropriate
- No data leaves the server

### Phase 4b: Expand Use Cases (1 week)

1. Build 3-4 summarisation UDFs (channel, product, daily briefing, anomaly)
2. Explore NL-to-SQL with schema context injection
3. Test with real end users (Finance, Exco)
4. Gather feedback on quality and usefulness

### Phase 4c: Productise (if validated)

1. Package UDFs as part of the DWH deployment
2. Add summarisation UDFs to the configuration-driven schema generator
3. Create a simple web interface or email scheduler for summaries
4. Document prompt templates as configurable elements

---

## Model Options

| Model | Size | Speed (~per query) | Quality | License | Best For |
|-------|------|-------------------|---------|---------|----------|
| Mistral 7B | 4GB | ~2s | Good | Apache 2.0 | General summarisation (recommended start) |
| Qwen3 4B | 2.5GB | ~1s | Good | Apache 2.0 | Fast summaries, smaller footprint |
| GPT-OSS 20B | 12GB | ~5s+ | Best | Open | Complex narration, NL-to-SQL |
| SQLCoder | 4GB | ~2s | N/A | Open | SQL generation specifically |
| Phi-3 | 2GB | <1s | Decent | MIT | Minimal resource usage |

**Recommendation:** Start with Mistral 7B. If NL-to-SQL becomes a focus, evaluate SQLCoder alongside it.

---

## Configuration Integration (Productisation)

If this proves valuable, the NL layer becomes part of the configuration-driven deployment:

```yaml
# deployment_config.yaml (Phase 4 additions)
nl_analytics:
  enabled: true
  ollama_host: "10.0.0.186"
  ollama_port: 11434
  model: "mistral:latest"

  summarisation:
    channel_performance: true
    daily_briefing: true
    anomaly_alerts: true

  nl_to_sql:
    enabled: false  # Enable when validated
    allowed_schemas:
      - "SHOPIFY_DWH"
      - "DYT_DWH"
    read_only: true

  scheduling:
    daily_briefing_time: "07:00"
    recipients:
      - "dominic@digitalplanet.co.za"
```

---

## Risks and Considerations

| Risk | Mitigation |
|------|------------|
| LLM hallucination (wrong numbers) | Summaries narrate pre-computed data, not generate it. Numbers come from SQL, words come from LLM. |
| Slow performance at scale | Summarise aggregated tables (fact_channel_daily), not raw facts. Limit concurrent UDF calls. |
| Resource contention with Exasol | Run Ollama on same server but monitor CPU/RAM. Mistral 7B needs ~4GB RAM. |
| NL-to-SQL generates bad queries | Read-only user, SELECT-only validation, query logging, human review initially. |
| Model quality insufficient | Start with summarisation (lowest risk). Only move to NL-to-SQL if quality is proven. |
| Prompt injection via user input | Sanitise inputs, use parameterised prompts, restrict schema access. |

---

## Elevator Pitch Addition

If Phase 4 proves out, this extends the Exasol event pitch:

> "And because we're on Exasol, we can take it further. Using Exasol's Python UDFs and a self-hosted LLM, end users can get natural language summaries of their data — directly from SQL. 'How did Vodacom perform this month?' returns a narrative paragraph, not a table. The model runs on the same server as Exasol, data never leaves your infrastructure, and it costs nothing in API fees."

---

---

# Alternative: Claude MCP (Interactive NL Analytics)

## Overview

Instead of (or in addition to) self-hosted Ollama, use Claude via MCP (Model Context Protocol) for interactive conversational analytics. An MCP server connects Claude to Exasol, exposing query tools and schema context. Users talk to their data through Claude Desktop or a custom app.

**Key advantage over Ollama:** Conversational drill-down. Users can ask follow-ups, compare periods, and explore data interactively — not just get a one-shot summary from a SQL UDF.

**Key trade-off:** Data goes through Anthropic's API, so POPIA compliance requires a tiered approach.

## Architecture

```
End User (Claude Desktop / Custom App / API)
  |
  | "How did Vodacom perform this month?"
  v
Claude (Opus / Sonnet)
  |
  | Inspects schema via MCP resources
  | Generates SQL via MCP tools
  | Narrates results in business language
  v
MCP Server (Python — Exasol connector)
  |
  | Tools: query_exasol(sql), get_schema(), get_metrics()
  | Resources: schema definitions, metric glossary
  | Prompts: business context templates
  v
Exasol Database (read-only connection)
```

## POPIA-Compliant Tiered Model

Data sensitivity determines which engine processes it.

### Tier 1: Claude MCP (Cloud API — non-PII only)

**Allowed data:**
- fact_channel_daily (aggregated — no individual data)
- dim_channel (business entities, not people)
- dim_product, product catalogue, product performance
- Aggregated redemption/revenue/financial metrics
- dim_date (calendar data)
- ref_commission_rate (business rates)

**Use cases:**
- Interactive ad-hoc exploration ("Compare Vodacom vs Telkom Q1")
- Exco briefings and summaries
- Product performance analysis
- Channel trend analysis

**Why safe:** All data is aggregated at channel/product/day level. No natural person is identifiable.

### Tier 2: Ollama (Self-hosted — all data including PII)

**Required for:**
- dim_customer (names, emails, phones, tags, segments)
- stg_voucher_distributions (recipient_phone, recipient_name)
- Order-level data with customer references
- Any data identifiable to a natural person under POPIA

**Use cases:**
- Scheduled customer segment summaries
- Anomaly narration involving individual orders
- Membership tier analysis (customer tags)
- Data quality reports

**Why on-prem:** POPIA requires that personal information of data subjects is handled with appropriate security measures. Sending PII to a cloud API is a compliance risk.

## MCP Server Design

A lightweight Python MCP server using PyExasol:

### Tools (actions Claude can take)

```python
@server.tool("query_exasol")
async def query_exasol(sql: str) -> str:
    """Execute a read-only SQL query against the DWH.
    Only SELECT statements allowed. Returns results as formatted table."""

    # Safety: reject non-SELECT
    if not sql.strip().upper().startswith("SELECT"):
        return "ERROR: Only SELECT queries are allowed."

    # Safety: reject PII tables
    PII_TABLES = ["dim_customer", "stg_voucher_distributions",
                   "stg_customers"]
    for table in PII_TABLES:
        if table.lower() in sql.lower():
            return f"ERROR: {table} contains PII and cannot be queried via cloud API."

    conn = pyexasol.connect(dsn=EXASOL_DSN, user=READONLY_USER, password=PWD)
    try:
        result = conn.export_to_pandas(sql)
        return result.to_markdown(index=False)
    finally:
        conn.close()


@server.tool("get_channel_performance")
async def get_channel_performance(channel: str, period: str) -> str:
    """Get pre-built performance summary for a channel.
    Period: 'this_month', 'last_month', 'this_quarter', 'ytd'."""
    # Pre-built safe query — no PII risk
    ...


@server.tool("get_product_performance")
async def get_product_performance(top_n: int = 10, period: str = "this_month") -> str:
    """Get top/bottom products by revenue for a period."""
    ...
```

### Resources (context Claude can read)

```python
@server.resource("schema://dyt_dwh")
async def get_schema() -> str:
    """DYT DWH schema — tables, columns, descriptions.
    Used by Claude to understand what data is available."""
    return SCHEMA_DESCRIPTION  # Pre-built string from design.md

@server.resource("metrics://glossary")
async def get_metrics_glossary() -> str:
    """Business metric definitions — what each metric means,
    how it's calculated, which table it comes from."""
    return METRICS_GLOSSARY  # From metrics reference
```

### Prompts (interaction templates)

```python
@server.prompt("exco_briefing")
async def exco_briefing_prompt() -> str:
    """Template for generating executive briefings.
    Provides tone, format, and business context."""
    return """You are a business analyst at Digital Planet, reporting to
    the Head of Analytics. Generate a concise executive briefing using
    South African Rand (R) for currency. Focus on:
    1. Key channel performance (redemption rates, revenue)
    2. Notable trends (up/down vs prior period)
    3. Action items or flags
    Keep it to 1 page / 3-4 paragraphs. Use business language."""
```

## Safety Controls

| Control | Implementation |
|---------|---------------|
| Read-only DB user | MCP server connects with a user that has SELECT-only permissions |
| PII table blocklist | MCP tool rejects queries referencing dim_customer, stg_customers, stg_voucher_distributions |
| SELECT-only validation | Reject any SQL not starting with SELECT |
| Query logging | Log all queries executed via MCP for audit |
| Rate limiting | Limit queries per user per hour |
| Schema exposure | Only expose non-PII table schemas in MCP resources |

## POC Plan (Claude MCP)

### Phase 4a-MCP: Proof of Concept (1-2 days)

1. Build a minimal MCP server with PyExasol (3 tools: query, channel performance, product performance)
2. Add schema resource with non-PII tables only
3. Connect from Claude Desktop
4. Test: "How did Vodacom perform this month?" → Claude queries fact_channel_daily → narrates result
5. Test: "Break it down by campaign" → Claude generates follow-up query → drills down

**Success criteria:**
- Claude generates correct SQL from natural language
- Conversational drill-down works (3+ turns)
- PII tables are blocked
- Response quality is business-appropriate

### Phase 4b-MCP: Expand (1 week)

1. Add more pre-built tools (top products, redemption trends, anomaly detection)
2. Add Exco briefing prompt template
3. Test with Finance and Exco users
4. Compare quality vs Ollama summaries
5. Evaluate API costs at expected usage volume

## Cost Estimate

| Usage | Claude Sonnet 4.6 Cost (approx) |
|-------|-------------------------------|
| 10 queries/day (light use) | ~$1-3/month |
| 50 queries/day (moderate) | ~$5-15/month |
| 200 queries/day (heavy) | ~$20-60/month |

Minimal compared to Fivetran licensing ($500-10K/month) that the DWH replaces.

## Comparison Summary

| Capability | Ollama (Tier 2) | Claude MCP (Tier 1) |
|-----------|-----------------|---------------------|
| Model quality | Good (Mistral 7B) | Excellent (Opus/Sonnet) |
| Conversation | Single prompt-response | Multi-turn drill-down |
| Data access | All data (PII included) | Non-PII aggregated only |
| Cost | Free | Low ($1-60/month) |
| Internet | Not required | Required |
| User interface | SQL / scheduled reports | Claude Desktop / custom app |
| Setup | Ollama + UDFs | MCP server + API key |
| Best for | Batch summaries, PII data | Interactive exploration, ad-hoc |

**Recommendation:** Build both. They're complementary, not competing.
- Claude MCP for interactive exploration (the "ask anything" experience)
- Ollama for scheduled summaries and anything touching PII

---

# Web Interface: DYT Analytics Assistant

## Concept

A web-based chat interface where users log in and ask questions about the DWH in plain English. Behind the scenes, the web app calls the Claude API with the MCP connector pointing at the Exasol MCP server. The user sees a conversation. Claude sees the database.

No one needs to know about "Ollama", "Claude", "MCP", or "SQL". They just type a question and get an answer.

## Architecture

```
User's Browser
  |
  | Opens webpage, logs in, types a question
  v
Web App (hosted on your server)
  |
  | Knows who the user is (auth)
  | Knows what they're allowed to see (role/channel)
  | Calls Claude API with MCP connector
  v
Claude API (Anthropic cloud)
  |
  | Sees MCP tools (query_exasol, get_metrics, etc.)
  | Generates SQL, calls tools, narrates results
  |
  | Connects to MCP server via HTTPS
  v
MCP Server (hosted alongside Exasol)
  |
  | Receives tool calls from Claude
  | Runs read-only queries against Exasol
  | Blocks PII tables
  | Injects role-based filters (e.g. channel restriction)
  | Returns results
  v
Exasol Database
```

**Key API finding:** The Claude API has a built-in MCP connector (beta header `mcp-client-2025-11-20`). You pass `mcp_servers` in the API call and Claude connects to your MCP server directly — no separate MCP client needed.

## What the User Sees

A simple chat page:

```
+----------------------------------------------+
|  DYT Analytics Assistant          [Logout]   |
|----------------------------------------------|
|                                              |
|  You: How did Vodacom do this month?         |
|                                              |
|  Assistant: Vodacom distributed 3,200        |
|  vouchers in February with a 67% redemption  |
|  rate, up 4pp from January. Total face       |
|  value redeemed was R480K with R384K in      |
|  overspend.                                  |
|                                              |
|  You: Compare that to Telkom                 |
|                                              |
|  Assistant: Telkom distributed 5,100         |
|  vouchers but at a lower 52% redemption      |
|  rate. Subscriptions made up 70% of their    |
|  volume vs Vodacom's 30%.                    |
|                                              |
|  You: Which channels are underperforming?    |
|                                              |
|  Assistant: Three channels are below the     |
|  60% target: Cell C (47%), PayJoy (52%),     |
|  and Teljoy (55%). Cell C has dropped 12pp   |
|  since January.                              |
|                                              |
|  +----------------------------------+  [Send]|
|  | Type your question...            |        |
|  +----------------------------------+        |
+----------------------------------------------+
```

What the user does NOT see: Claude deciding which SQL to write, the MCP server running the query, the PII filter, the role-based WHERE clause. To them, it's just a conversation.

## User Roles and Access Control

The login determines what each user can see. The web app passes the user's role to the MCP server, which enforces the filter server-side. Users cannot bypass this by asking cleverly — the SQL is always filtered before execution.

| Role | Users | Can Ask About | Enforcement |
|------|-------|--------------|-------------|
| **Exco / Finance** | CFO, CEO, Finance team | All channels, all products, financial summaries | MCP allows all non-PII tables |
| **Analytics** | Dominic, data team | Everything non-PII, complex questions | Full tool access |
| **Channel Manager** | Vodacom rep, Telkom rep | Their channel only | MCP injects `WHERE channel_name = '{user_channel}'` |
| **Product Manager** | Product team | Product data only | MCP restricts to dim_product + product metrics |

### How Role Filtering Works

```python
# In the MCP server — tool handler for query_exasol
@server.tool("query_exasol")
async def query_exasol(sql: str, user_role: str, user_channel: str = None) -> str:
    # Block PII tables
    PII_TABLES = ["dim_customer", "stg_voucher_distributions", "stg_customers"]
    for table in PII_TABLES:
        if table.lower() in sql.lower():
            return f"Access denied: {table} contains personal data."

    # Channel manager restriction
    if user_role == "channel_manager" and user_channel:
        # Inject channel filter if not already present
        if "channel_name" not in sql.lower():
            # Wrap query with channel filter
            sql = f"SELECT * FROM ({sql}) sub WHERE channel_name = '{user_channel}'"

    # Read-only enforcement
    if not sql.strip().upper().startswith("SELECT"):
        return "Only SELECT queries are allowed."

    # Execute
    conn = pyexasol.connect(dsn=DSN, user=READONLY_USER, password=PWD)
    try:
        result = conn.export_to_pandas(sql)
        return result.to_markdown(index=False)
    finally:
        conn.close()
```

## Interface by User Type

### Exco / Finance — Two Options

**Option A: Email summaries (automatic, Ollama)**
Daily/weekly briefings arrive by email. No interaction needed. Generated by Ollama on a schedule.

**Option B: Web chat (on-demand, Claude)**
Same web interface as everyone else. They log in when they have a specific question. Good for board prep, ad-hoc queries, "what happened yesterday?"

### Analytics Team — Power Mode

Full access to the web chat. Can ask complex multi-step questions, compare periods, investigate anomalies. Also has Claude Desktop/Claude Code access for deeper exploration.

### Channel Managers — Filtered View

Same web interface but restricted to their channel. They see a simpler landing page:

```
+----------------------------------------------+
|  Vodacom Analytics        [John]  [Logout]   |
|----------------------------------------------|
|                                              |
|  Quick actions:                              |
|  [This month's summary] [Outstanding vouchers]|
|  [Top products]          [Redemption trend]   |
|                                              |
|  Or ask a question:                          |
|  +----------------------------------+  [Ask] |
|  | e.g. "How are subscriptions      |        |
|  |  performing vs one-off?"         |        |
|  +----------------------------------+        |
+----------------------------------------------+
```

The quick action buttons are pre-built prompts that run common queries. The free-text box is for anything else. Both go through Claude + MCP.

## Tech Stack

| Component | Technology | Purpose | Effort |
|-----------|-----------|---------|--------|
| **Frontend** | React / Next.js (or plain HTML + JS) | Chat UI with login | 2-3 days |
| **Auth** | Existing company auth, or simple user/password table | Who is this user, what role? | 1 day |
| **Backend API** | Python (FastAPI) or Node.js | Receives messages, calls Claude API, manages sessions | 1-2 days |
| **MCP Server** | Python + PyExasol | Exposes Exasol query tools over HTTPS | 1-2 days |
| **Hosting** | Same Linux server as Exasol | Everything runs together | Already have it |

**Total estimated effort: 1-2 weeks** for a functional prototype.

## Backend Core Code

The backend is small. This is the core of it:

```python
# backend/app.py (FastAPI)
from fastapi import FastAPI, Depends
import anthropic

app = FastAPI()
client = anthropic.Anthropic(api_key="your-key")

# In-memory conversation store (use Redis/DB for production)
conversations = {}

@app.post("/api/chat")
async def chat(message: str, user = Depends(get_current_user)):
    # Get or create conversation history
    history = conversations.get(user.id, [])
    history.append({"role": "user", "content": message})

    # Build system prompt with user context
    system = (
        f"You are the DYT Analytics Assistant. "
        f"User: {user.name}, Role: {user.role}. "
        f"{'Channel: ' + user.channel if user.channel else 'All channels'}. "
        f"Use South African Rand (R). Be concise and business-friendly. "
        f"When showing data, use tables. Highlight trends and anomalies."
    )

    # Call Claude with MCP connector
    response = client.beta.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=2000,
        system=system,
        messages=history,
        mcp_servers=[{
            "type": "url",
            "url": "https://your-server:8443/mcp",
            "name": "exasol-dwh",
            "authorization_token": generate_mcp_token(user)
        }],
        tools=[{
            "type": "mcp_toolset",
            "mcp_server_name": "exasol-dwh"
        }],
        betas=["mcp-client-2025-11-20"]
    )

    # Extract assistant message
    assistant_message = extract_text(response)
    history.append({"role": "assistant", "content": assistant_message})
    conversations[user.id] = history

    return {"reply": assistant_message}
```

## MCP Server Core Code

```python
# mcp_server/server.py
from mcp.server import Server
import pyexasol

server = Server("exasol-dwh")

SCHEMA_CONTEXT = """
Available tables (non-PII only):

DYT_DWH.fact_channel_daily: channel_key, date_key, channel_name,
  vouchers_created, vouchers_distributed, vouchers_redeemed, vouchers_expired,
  face_value_created, face_value_distributed, face_value_redeemed,
  redemption_order_revenue, overspend_total, breakage_total,
  outstanding_distributed, distribution_rate, redemption_rate

DYT_DWH.dim_channel: channel_key, channel_id, channel_name, industry, is_active

SHOPIFY_DWH.dim_product: product_key, product_title, variant_title,
  product_type, vendor, current_price, sku

SHOPIFY_DWH.dim_date: date_key (YYYYMMDD), full_date, year, quarter,
  month, month_name, week_of_year, day_name, is_weekend

DYT_DWH.ref_commission_rate: channel_key, rate_type, rate_value,
  effective_from, effective_to

Currency: South African Rand (R). Date keys are YYYYMMDD integers.
"""

@server.resource("schema://dwh")
async def get_schema():
    """DWH schema for non-PII tables."""
    return SCHEMA_CONTEXT

@server.tool("query_exasol")
async def query_exasol(sql: str) -> str:
    """Run a read-only SQL query against the DWH.
    Only SELECT on non-PII tables allowed."""

    # Safety checks
    BLOCKED = ["dim_customer", "stg_customers", "stg_voucher_distributions"]
    sql_lower = sql.lower()

    if not sql_lower.strip().startswith("select"):
        return "ERROR: Only SELECT queries allowed."

    for table in BLOCKED:
        if table in sql_lower:
            return f"ERROR: {table} contains personal data and cannot be queried."

    try:
        conn = pyexasol.connect(dsn="exasol-host:8563", user="readonly", password="***")
        result = conn.export_to_pandas(sql)
        conn.close()

        if len(result) == 0:
            return "No results found."
        if len(result) > 100:
            result = result.head(50)
            return result.to_markdown(index=False) + "\n\n(Showing first 50 of many rows)"
        return result.to_markdown(index=False)
    except Exception as e:
        return f"Query error: {str(e)}"


@server.tool("get_channel_summary")
async def get_channel_summary(channel_name: str, period: str = "this_month") -> str:
    """Get a pre-built performance summary for a specific channel.
    Period options: this_month, last_month, this_quarter, ytd."""

    period_filter = {
        "this_month": "d.year = YEAR(CURRENT_DATE) AND d.month = MONTH(CURRENT_DATE)",
        "last_month": "d.full_date BETWEEN ADD_MONTHS(DATE_TRUNC('month', CURRENT_DATE), -1) AND DATE_TRUNC('month', CURRENT_DATE) - 1",
        "this_quarter": "d.year = YEAR(CURRENT_DATE) AND d.quarter = QUARTER(CURRENT_DATE)",
        "ytd": "d.year = YEAR(CURRENT_DATE)"
    }.get(period, "d.year = YEAR(CURRENT_DATE) AND d.month = MONTH(CURRENT_DATE)")

    sql = f"""
    SELECT
        f.channel_name,
        SUM(f.vouchers_distributed) as distributed,
        SUM(f.vouchers_redeemed) as redeemed,
        ROUND(SUM(f.vouchers_redeemed) * 100.0 / NULLIF(SUM(f.vouchers_distributed), 0), 1) as redemption_pct,
        SUM(f.face_value_redeemed) as face_value_redeemed,
        SUM(f.overspend_total) as overspend,
        SUM(f.redemption_order_revenue) as revenue,
        MAX(f.outstanding_distributed) as outstanding
    FROM DYT_DWH.fact_channel_daily f
    JOIN SHOPIFY_DWH.dim_date d ON f.date_key = d.date_key
    WHERE f.channel_name = '{channel_name}'
      AND {period_filter}
    GROUP BY f.channel_name
    """

    try:
        conn = pyexasol.connect(dsn="exasol-host:8563", user="readonly", password="***")
        result = conn.export_to_pandas(sql)
        conn.close()
        if len(result) == 0:
            return f"No data found for {channel_name} in {period}."
        return result.to_markdown(index=False)
    except Exception as e:
        return f"Query error: {str(e)}"


@server.tool("get_top_products")
async def get_top_products(top_n: int = 10, period: str = "this_month") -> str:
    """Get top products by units sold for a period."""
    # Similar pre-built safe query
    ...
```

## Yellowfin BI Integration

The chat interface is NOT a replacement for Yellowfin. Yellowfin handles structured, repeatable reporting — dashboards, scheduled reports, standard KPIs. The chat interface fills the gap: ad-hoc questions, unexpected drill-downs, and plain-English explanations of what the numbers mean.

### How They Complement Each Other

| Need | Yellowfin | Chat |
|------|-----------|------|
| "Show me this month's dashboard" | Yes | No — YF is better |
| "Same report every Monday" | Yes — scheduled delivery | No |
| "Filter by channel, drill into product" | Yes — pre-built drill paths | Overkill |
| "Why did Telkom redemptions drop?" | Hard — needs a new report | Yes — just ask |
| "Compare Q1 vs last year by campaign" | Possible but needs building | Yes — one question |
| "What should I focus on this week?" | No — dashboards don't advise | Yes — Claude can reason |
| "Give me a paragraph for the board pack" | No — YF gives tables/charts | Yes — narrative output |

### Page Layout: YF Reports + Chat Panel

The web interface hosts both Yellowfin (embedded) and the chat panel. Yellowfin is primary. Chat is an add-on that the user can expand when they want to go deeper.

**Default state (chat collapsed):**

```
+------------------------------------------------------------------+
|  Report: Channel Performance                              [Menu] |
|------------------------------------------------------------------|
|                                                                  |
|  [Embedded Yellowfin Dashboard / Report]                         |
|  +------------------------------------------------------------+ |
|  |                                                             | |
|  |  Charts, tables, filters — standard Yellowfin content       | |
|  |                                                             | |
|  |  Vodacom  |  3,200 distributed  |  67% redemption  | ...   | |
|  |  Telkom   |  5,100 distributed  |  52% redemption  | ...   | |
|  |                                                             | |
|  +------------------------------------------------------------+ |
|                                                                  |
|  +------------------------------------------------------------+ |
|  |  Ask AI about this data                          [Expand ^] | |
|  +------------------------------------------------------------+ |
|                                                                  |
+------------------------------------------------------------------+
```

**Expanded state (chat open):**

```
+------------------------------------------------------------------+
|  Report: Channel Performance                              [Menu] |
|------------------------------------------------------------------|
|                                                                  |
|  [Embedded Yellowfin Dashboard - compressed]                     |
|  +------------------------------------------------------------+ |
|  |  (same YF content, reduced height)                          | |
|  +------------------------------------------------------------+ |
|                                                                  |
|  +------------------------------------------------------------+ |
|  |  AI Assistant                                  [Collapse v] | |
|  |------------------------------------------------------------| |
|  |                                                             | |
|  |  Assistant: I can see you're looking at Channel             | |
|  |  Performance. What would you like to know?                  | |
|  |                                                             | |
|  |  You: Why is Telkom's redemption rate so low?               | |
|  |                                                             | |
|  |  Assistant: Telkom's 52% rate is driven by their            | |
|  |  subscription vouchers — 70% of volume. Subscription        | |
|  |  vouchers typically redeem slower (avg 12 days vs 3         | |
|  |  days for one-off). Their one-off rate is actually 71%,     | |
|  |  in line with Vodacom.                                      | |
|  |                                                             | |
|  |  +----------------------------------------------+  [Send]  | |
|  |  | Ask a question...                            |          | |
|  |  +----------------------------------------------+          | |
|  +------------------------------------------------------------+ |
+------------------------------------------------------------------+
```

### Report Context Passing

The key feature: when the chat panel opens, it **knows which report the user is looking at**. The page passes context to the chat backend:

```javascript
// When user expands the chat panel
function openChat() {
    const reportContext = {
        report_name: "Channel Performance",         // Which YF report
        report_type: "channel_summary",             // Maps to a prompt template
        active_filters: {
            date_range: "2026-02-01 to 2026-02-28", // Current YF filters
            channel: null                            // null = all channels
        },
        visible_metrics: [                          // What's on screen
            "vouchers_distributed",
            "vouchers_redeemed",
            "redemption_rate"
        ]
    };

    // Send to backend — Claude gets this as context
    chatApi.startSession(reportContext);
}
```

The backend uses this to give Claude a head start:

```python
# Backend builds system prompt with report context
system = (
    f"You are the DYT Analytics Assistant. "
    f"The user is currently viewing the '{report_context['report_name']}' report "
    f"in Yellowfin, filtered to {report_context['active_filters']}. "
    f"They can see: {', '.join(report_context['visible_metrics'])}. "
    f"Answer questions in context of what they're looking at. "
    f"Use South African Rand (R). Be concise."
)
```

This means the user doesn't have to say "I'm looking at channel performance for February" — Claude already knows.

### The Realistic User Journey

```
1. User opens Yellowfin dashboard (morning routine)
   → Sees redemption rate dropped for Telkom

2. Clicks "Ask AI about this data" (chat panel expands)
   → Chat knows they're on the Channel Performance report for Feb 2026

3. Types: "Why did Telkom drop?"
   → Claude queries fact_channel_daily, breaks down by voucher type
   → "Telkom's 52% rate is driven by subscription vouchers (70% of volume).
      One-off redemptions are actually 71%. Subscription vouchers take
      12 days to redeem on average vs 3 days for one-off."

4. Types: "Is that normal for subscriptions?"
   → Claude compares to historical subscription rates
   → "Yes — Telkom subscription redemption has been 48-55% consistently.
      The apparent drop is because this month had a larger subscription
      batch (3,600 vs usual 2,400). More are still in the redemption
      window."

5. User collapses chat, goes back to reviewing the dashboard
   → Now understands the numbers, no analyst needed
```

### Technical Architecture

```
+------------------------------------------------------------------+
|  Web Page (your app)                                              |
|  +---------------------------+  +------------------------------+ |
|  |  Yellowfin Embed          |  |  Chat Component (React/JS)  | |
|  |  (iframe or JS API)       |  |                              | |
|  |                           |  |  Sends: user message +       | |
|  |  Standard YF content      |  |  report context              | |
|  |  Handles its own auth     |  |                              | |
|  |                           |  |  Receives: Claude's reply    | |
|  +---------------------------+  +------------------------------+ |
|              |                               |                    |
|              |                               v                    |
|              |                    Your Backend (FastAPI)           |
|              |                       |                            |
|              |                       | Adds: user role, filters,  |
|              |                       | report context to prompt   |
|              |                       |                            |
|              |                       v                            |
|              |                    Claude API + MCP connector       |
|              |                       |                            |
|              |                       v                            |
|              |                    MCP Server                      |
|              |                       |                            |
|              +--------> Exasol <-----+                            |
|              (YF reads              (MCP reads                    |
|               directly)             via tools)                    |
+------------------------------------------------------------------+
```

Both Yellowfin and the MCP server read from the same Exasol database. Yellowfin uses its own connection (as it does today). The MCP server uses a separate read-only connection with PII restrictions.

### Yellowfin Embedding Options

Yellowfin supports several embedding methods:

| Method | How | Complexity |
|--------|-----|-----------|
| **iframe** | `<iframe src="https://yf-server/report/12345">` | Simplest — just an iframe on your page |
| **Yellowfin JS API** | JavaScript SDK embeds reports with filter control | More control — can read active filters programmatically |
| **URL parameters** | Pass filters via URL: `?CHANNEL=Vodacom&DATE=202602` | Simple, works with iframes |

**Recommendation:** Start with iframe embedding (simplest). Move to JS API if you need to read filters programmatically for richer context passing to Claude.

### What Yellowfin Handles vs What You Build

| Component | Who Handles It |
|-----------|---------------|
| Reports, dashboards, charts | Yellowfin (existing) |
| Report embedding | Yellowfin iframe / JS API |
| User authentication | Your web app (or pass-through to YF auth) |
| Chat UI component | Your build (React/JS) |
| Chat backend | Your build (FastAPI + Claude API) |
| MCP server | Your build (Python + PyExasol) |
| Data | Exasol DWH (shared) |

## Yellowfin Native AI vs Claude MCP — Honest Assessment

Before building the Claude MCP chat panel, evaluate what Yellowfin already provides natively. There is overlap, but the gaps are real.

### What Yellowfin Already Does

Yellowfin has built-in AI/NL features (availability depends on version and licence):

| YF Feature | What It Does | Limitation |
|------------|-------------|------------|
| **Assisted Insights** | Automated anomaly detection on reports — flags spikes, drops, trends | Template-based explanations, not conversational. Can't answer "why?" |
| **Natural Language Queries (Guided NLQ)** | Users type questions like "revenue by channel this month" and YF generates a report | Constrained to YF's data model. Generates YF reports, not raw SQL. Can't reason across tables or follow up conversationally |
| **Signals** | Automated monitoring — alerts when metrics change significantly | Detection only, no explanation or drill-down |
| **Stories** | Narrative dashboards combining text and data | Manual authoring, not AI-generated |

### Where YF Falls Short (Claude MCP Fills the Gap)

| Capability | Yellowfin Native | Claude MCP |
|---|---|---|
| "Why did revenue drop?" | Flags the drop, shows correlated changes | Reasons across multiple tables, hypothesises causes, suggests investigation paths |
| Cross-source reasoning | Limited to what's in YF's data source config | Can query any table the MCP server exposes |
| Conversational follow-up | One-shot NLQ (no memory of prior questions) | Multi-turn conversation with full context |
| Custom business logic | Doesn't know your B2B2C model, voucher lifecycle, or channel dynamics | System prompt encodes domain knowledge |
| Ad-hoc exploration | Must map to existing YF report structures or views | Can write arbitrary SQL against the warehouse |
| Plain English summaries | Canned insight text from templates | Natural, contextual narrative tailored to the audience |
| "What should I focus on?" | Dashboards show data, they don't advise | Claude can reason and prioritise |

### Recommendation: Phased Approach

**Don't build the Claude MCP chat panel immediately. Evaluate YF's native capabilities first.**

1. **Now:** Turn on YF's Assisted Insights and Signals (already paid for in your licence). See if they cover the "what changed?" use case adequately.

2. **Track the gaps:** When users hit the wall — "I asked YF why channel X dropped and it just showed me the number" — log those as use cases for Claude MCP.

3. **Build Ollama/UDF first (Tier 2):** Batch summaries for scheduled reports don't overlap with YF at all. This is independently valuable and lower risk.

4. **Build Claude MCP when the gap is proven:** The architecture designed in this document is still valid. Nothing about waiting changes the design. You're just deferring build until you have evidence of exactly which questions YF can't answer.

**The gap will almost certainly exist** — YF's NLQ is rigid (report generation, not conversation), and it can't encode your specific business context. But building after evaluation means you know exactly what to build instead of guessing.

### What This Changes in the POC Plan

| Original Plan | Revised Plan |
|---|---|
| Week 1: MCP Server + Backend | Phase 4a: Ollama UDFs (summarisation POC) |
| Week 2: Web Page + YF Embed + Chat | Phase 4b: Enable YF Assisted Insights + Signals, gather feedback (2-4 weeks) |
| Week 3: Polish | Phase 4c: Build Claude MCP chat panel targeting the specific gaps identified |

The total build effort is the same. The sequencing is smarter.

## POC Plan for Yellowfin + Chat

### Week 1: Backend + MCP Server

1. Build MCP server with 3 tools: `query_exasol`, `get_channel_summary`, `get_top_products`
2. Add PII blocklist and SELECT-only validation
3. Build FastAPI backend with Claude API + MCP connector integration
4. Test end-to-end: question → Claude → MCP → Exasol → answer

### Week 2: Web Page + Yellowfin Embed

1. Build web page with Yellowfin report embedded (iframe)
2. Add collapsible chat panel below the report
3. Pass report context (report name, filters) to chat backend
4. Add user login and role-based filtering
5. Test with 2-3 real users

### Week 3: Polish + Feedback

1. Improve prompts based on feedback (tone, detail level, format)
2. Add conversation history (persist across sessions)
3. Test context passing — does Claude's awareness of the active report feel natural?
4. Add the email summary feature (Ollama, scheduled)
5. Explore YF JS API if richer filter context is needed

## Cost Estimate

| Component | Monthly Cost |
|-----------|-------------|
| Claude API (Sonnet, ~50 queries/day) | ~$5-15 |
| Claude API (Sonnet, ~200 queries/day) | ~$20-60 |
| Hosting (if using existing server) | $0 |
| Anthropic API key | Free to create |
| **Total** | **$5-60/month** |

Compare: Fivetran ($500-10K/month), Tableau ($70/user/month), Power BI Pro ($10/user/month).

---

## Related

- [Exasol AI Text Summary Docs](https://exasol.github.io/developer-documentation/main/gen_ai/ai_text_summary/index.html)
- [MCP Documentation](https://modelcontextprotocol.io/introduction)
- [Claude MCP Connector API Docs](https://platform.claude.com/docs/en/agents-and-tools/mcp-connector)
- [productization-strategy.md](productization-strategy.md) — Configuration-driven deployment
- [schema-layered.md](schema-layered.md) — DWH schema (what the LLM would query)
