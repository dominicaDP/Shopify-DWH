# Example 2: Client Work - Discovery Process Pattern

## Scenario

**Context**: the user just completed a successful discovery call with a new client (Client D - Healthcare SaaS). The call went exceptionally well, and the client signed a contract immediately after.

**Work completed**: 90-minute discovery call using a structured approach

**Time spent**: 90 min call + 30 min prep = 2 hours

**Outcome**: Client signed contract same day (unusual - typically takes 2-3 follow-ups) ✅

---

## Skill Execution: /learn

### Step 1: Identify Recent Work

**User Input**: `/learn`

**Skill Question**:
```
What did you just complete?

Options:
1. Code work (bug fix, feature, refactor)
2. Client project milestone
3. Content creation (blog, video, social)
4. Research/learning
5. Something else: ________
```

**User Response**: `2. Client project milestone` (discovery call)

**Stored**: `work_type = "client"`

---

### Step 2: Extract Learning (Quick Questions)

**Skill Questions** (for client work):

**Q1**: "What was unique about this client's needs?"
**A1**: "Healthcare compliance requirements - they needed HIPAA-compliant solution, very specific about data residency and audit logs"

**Q2**: "What worked particularly well?"
**A2**: "Started with 'What's NOT working today?' instead of 'What do you want to build?' - uncovered 3 pain points they hadn't articulated yet"

**Q3**: "What surprised you?"
**A3**: "They signed immediately - no follow-up needed. Realized the discovery structure created urgency and clarity"

**Additional Context**: "Used a 3-part structure: Pain Discovery (30 min) → Current State Audit (30 min) → Future State Design (30 min)"

---

### Step 3: Search for Similar Patterns

**Tool: Grep**
```bash
Grep(
  pattern="discovery.*call|client.*discovery",
  path="memory/semantic/patterns/",
  output_mode="files_with_matches"
)
```

**Result**: Match found in `client-patterns.md`

**Decision**: REINFORCEMENT (increase confidence)

---

### Step 4: Update Semantic Memory

**Domain**: `client-patterns.md` (work_type = client)

**Tool: Read**
```bash
Read("memory/semantic/patterns/client-patterns.md")
```

**Current content**:
```markdown
# Client Patterns

## Structured Discovery Process

### Description
Use 3-part discovery structure: Pain Discovery → Current State Audit → Future State Design. Focus on "what's NOT working" before discussing solutions.

### When to Use
- First client discovery calls
- Scoping new projects
- Re-engaging existing clients for new work

### Examples
- Example 1 (2024-12-20): Client C - Asked "What's broken?" instead of "What do you want?" - revealed budget constraints early
- Example 2 (2025-01-03): Internal product - Used same structure for user interviews, identified 5 pain points in 45 min

### Confidence
- **Level:** MEDIUM
- **Based on:** 2 examples
- **Last reinforced:** 2025-01-03

### Time Savings
- **Estimated:** ~60 min per application (fewer follow-up calls, clearer scope)
- **Total saved:** 2 hours

### Sources
- memory/episodic/projects/2024-12-20-client-c-discovery.md
- memory/episodic/projects/2025-01-03-user-interviews.md

---
```

**Tool: Edit** (add new example and promote confidence)
```bash
Edit(
  file_path="memory/semantic/patterns/client-patterns.md",
  old_string="- Example 2 (2025-01-03): Internal product - Used same structure for user interviews, identified 5 pain points in 45 min",
  new_string="- Example 2 (2025-01-03): Internal product - Used same structure for user interviews, identified 5 pain points in 45 min\n- Example 3 (2025-01-09): Client D (Healthcare SaaS) - Discovery call led to same-day contract signing (no follow-ups needed)"
)

Edit(
  file_path="memory/semantic/patterns/client-patterns.md",
  old_string="### Confidence\n- **Level:** MEDIUM\n- **Based on:** 2 examples\n- **Last reinforced:** 2025-01-03",
  new_string="### Confidence\n- **Level:** MEDIUM\n- **Based on:** 3 examples\n- **Last reinforced:** 2025-01-09"
)

Edit(
  file_path="memory/semantic/patterns/client-patterns.md",
  old_string="### Time Savings\n- **Estimated:** ~60 min per application (fewer follow-up calls, clearer scope)\n- **Total saved:** 2 hours",
  new_string="### Time Savings\n- **Estimated:** ~60 min per application (fewer follow-up calls, clearer scope)\n- **Total saved:** 3 hours (this instance: 60 min - no follow-up calls needed)"
)

Edit(
  file_path="memory/semantic/patterns/client-patterns.md",
  old_string="- memory/episodic/projects/2025-01-03-user-interviews.md",
  new_string="- memory/episodic/projects/2025-01-03-user-interviews.md\n- memory/episodic/projects/2025-01-09-client-d-discovery.md"
)
```

**Result**: Pattern reinforced, confidence MEDIUM → MEDIUM (3 examples, needs 5 for HIGH) ✅

---

### Step 5: Create Episodic Memory Entry

**Tool: Bash**
```bash
Bash(command="date '+%Y-%m-%d'")
```
**Result**: `2025-01-09`

**Tool: Write**
```bash
Write(
  file_path="memory/episodic/projects/2025-01-09-client-d-discovery.md",
  content="""
# Client D Discovery Call - Healthcare SaaS - 2025-01-09

## Context
**Project:** Client D - Healthcare SaaS Platform
**Goal:** Discovery call to scope HIPAA-compliant feature development
**Duration:** 2 hours (30 min prep, 90 min call)

## What Happened
First discovery call with Client D (Healthcare SaaS company). They needed help building HIPAA-compliant data pipeline for patient records.

Used 3-part discovery structure:
1. **Pain Discovery (30 min)**: "What's NOT working today?"
   - Uncovered: Manual data entry (4 hours/day), audit log gaps, compliance anxiety

2. **Current State Audit (30 min)**: Mapped existing workflow
   - Discovered: Using 3 separate tools, no integration, data lives in spreadsheets

3. **Future State Design (30 min)**: Co-created solution vision
   - Aligned on: Automated pipeline, centralized audit logs, data residency requirements

## Solution
Applied structured discovery process instead of free-form conversation. Started with pain points before jumping to solutions.

## Patterns Applied
- **Structured Discovery Process** (from semantic memory)
  - 3-part structure kept conversation focused
  - "What's NOT working?" revealed 3 pain points client hadn't articulated
  - Time saved: ~60 min (no follow-up calls needed - client signed same day)

## Learnings Extracted
- **Reinforced pattern**: Structured Discovery Process (confidence: MEDIUM → MEDIUM, 3 examples)
- **New insight**: Healthcare clients respond extremely well to compliance-first framing
- **Timing**: 30 min per section is optimal (90 min total call length)

## Outcome
**Result:** SUCCESS
**Time saved:** 60 min (typically need 2-3 follow-up calls, none needed here)
**Quality:** 10/10 (client signed contract same day, rare outcome)

## Linked Patterns
→ Reinforced: memory/semantic/patterns/client-patterns.md#structured-discovery-process
→ Confidence: MEDIUM (3 examples, 2 more needed for HIGH)

## Next Time
- Always use 3-part structure for discovery calls
- Start with compliance/security concerns for healthcare clients
- Budget 30 min per section (90 min total)
- Record pain points in real-time (use Notion template)
  """
)
```

**Result**: Episodic memory created ✅

---

### Step 6: Update Brain Health Metrics

**Tool: Read**
```bash
Read("brain-health/growth-log.md")
```

**Tool: Edit**
```bash
Edit(
  file_path="brain-health/growth-log.md",
  old_string="### Patterns Learned\n- New: JWT refresh tokens for mobile (confidence: LOW)\n- New: PostgreSQL Foreign Key Indexing (confidence: LOW)",
  new_string="### Patterns Learned\n- New: JWT refresh tokens for mobile (confidence: LOW)\n- New: PostgreSQL Foreign Key Indexing (confidence: LOW)\n- Reinforced: Structured Discovery Process (confidence: MEDIUM, 3 examples)"
)

Edit(
  file_path="brain-health/growth-log.md",
  old_string="- Episodic memory: 32 experiences (+1)",
  new_string="- Episodic memory: 33 experiences (+2)"
)

Edit(
  file_path="brain-health/growth-log.md",
  old_string="### Time Savings This Week\n**Total saved:** 2.5 hours",
  new_string="### Time Savings This Week\n- Client work: 60 min (Structured Discovery Process)\n**Total saved:** 3.5 hours"
)
```

**Tool: Read**
```bash
Read("brain-health/pattern-confidence.md")
```

**Tool: Edit** (update MEDIUM confidence section)
```bash
Edit(
  file_path="brain-health/pattern-confidence.md",
  old_string="## Medium Confidence (2-4 examples)\n- Structured Discovery Process (2 examples, 2 hours saved, last: 2025-01-03)",
  new_string="## Medium Confidence (2-4 examples)\n- Structured Discovery Process (3 examples, 3 hours saved, last: 2025-01-09)"
)
```

**Result**: Brain health metrics updated ✅

---

### Step 7: Show Impact

**Output to User**:
```markdown
✅ Learning extracted and saved!

📊 Pattern Update:
**Reinforced:** "Structured Discovery Process"
- Confidence: MEDIUM → MEDIUM (still MEDIUM, moving toward HIGH)
- Now based on: 3 examples (was 2)
- Time saved today: ~60 min (no follow-up calls needed)

📝 Experience Logged:
memory/episodic/projects/2025-01-09-client-d-discovery.md

🧠 Brain Growth:
- Total patterns: 18 (unchanged - reinforcement, not new)
- Medium confidence patterns: 1 pattern closer to HIGH promotion
- Cumulative time saved from this pattern: 3 hours

💡 Impact Next Time:
When you have a client discovery call, I'll proactively suggest:
- Use 3-part structure: Pain Discovery → Current State Audit → Future State Design
- Start with "What's NOT working?" (not "What do you want?")
- Budget 30 min per section (90 min total)
- For healthcare clients: Lead with compliance/security framing

**Pattern promotion**: 2 more examples needed to reach HIGH confidence
**Estimated cumulative time savings:** 3 hours (3 × 60 min saved per application)
```

---

## Pattern Confidence Progression

### Current State (Week 3)
- **Examples**: 3 (Client C, Internal Product, Client D)
- **Confidence**: MEDIUM
- **Time saved**: 3 hours cumulative
- **Status**: 2 more examples needed for HIGH

### Next Milestone (Week 8 - Hypothetical)
- **Examples**: 5+ (add Client E, Client F)
- **Confidence**: MEDIUM → HIGH
- **Time saved**: 5+ hours cumulative
- **Status**: EXPERT-level knowledge achieved ✅

---

## Key Takeaways

**Process pattern extraction** (not just technical):
1. ✅ "Soft" patterns are just as valuable as technical ones
2. ✅ Time savings calculated (60 min per application = fewer follow-up calls)
3. ✅ Confidence progression tracked (MEDIUM, approaching HIGH)
4. ✅ Pattern applies across domains (clients + internal user research)

**Client-specific insights**:
- Healthcare clients respond to compliance-first framing
- 3-part structure creates urgency and clarity
- Starting with pain points reveals unarticulated needs

**ROI Demonstration**:
- **Week 1**: 2 hours spent (discovery call + prep)
- **Week 1**: 60 min saved (no follow-up calls)
- **Week 3**: 60 min saved (reinforcement)
- **Week 8** (projected): Pattern reaches HIGH confidence, saves 60 min every discovery call
- **Net ROI**: 5-10x return on time invested

**The magic**: By Week 8, the user has a repeatable discovery process that consistently produces same-day contract signings. The pattern compounds across all client work.
