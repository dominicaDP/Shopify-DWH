# Example 1: Code Fix - PostgreSQL Indexing Pattern

## Scenario

**Context**: the user just finished fixing a slow database query for a client project. The analytics dashboard was taking 8+ seconds to load user data.

**Work completed**: Optimized PostgreSQL query by adding proper indexes on foreign key columns.

**Time spent**: 2 hours debugging + 30 minutes implementing fix

**Outcome**: Query time reduced from 8.2s to 0.3s ✅

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

**User Response**: `1. Code work` (bug fix)

**Stored**: `work_type = "code"`

---

### Step 2: Extract Learning (Quick Questions)

**Skill Questions** (for code work):

**Q1**: "What was the root cause / key challenge?"
**A1**: "Slow PostgreSQL query - missing index on foreign key (user_id) in analytics table"

**Q2**: "How did you solve it?"
**A2**: "Added index on user_id column, query plan changed from Seq Scan to Index Scan"

**Q3**: "Have you seen similar issues before?"
**A3**: "No, first time noticing this pattern"

**Q4**: "What's the pattern to remember?"
**A4**: "Always index foreign keys in PostgreSQL - especially on large tables with JOINs"

---

### Step 3: Search for Similar Patterns

**Tool: Grep**
```bash
Grep(
  pattern="postgresql.*index",
  path="memory/semantic/patterns/",
  output_mode="files_with_matches"
)
```

**Result**: No matches found

**Decision**: NEW pattern (create entry)

---

### Step 4: Update Semantic Memory

**Domain**: `dev-patterns.md` (work_type = code)

**Tool: Read**
```bash
Read("memory/semantic/patterns/dev-patterns.md")
```

**Current content**:
```markdown
# Development Patterns

[Other patterns...]
```

**Tool: Edit** (append new pattern)
```bash
Edit(
  file_path="memory/semantic/patterns/dev-patterns.md",
  old_string="# Development Patterns\n\n",
  new_string="# Development Patterns\n\n## PostgreSQL Foreign Key Indexing\n\n### Description\nAlways add indexes on foreign key columns in PostgreSQL, especially on large tables with JOINs. PostgreSQL does NOT automatically index foreign keys (unlike some other databases).\n\n### When to Use\n- Any table with foreign key relationships\n- Tables > 1000 rows that are frequently joined\n- Analytics queries with multiple table JOINs\n- Performance optimization of slow queries\n\n### Examples\n- Example 1 (2025-01-09): Client A analytics dashboard - added index on user_id, reduced query time from 8.2s to 0.3s\n\n### Confidence\n- **Level:** LOW\n- **Based on:** 1 example\n- **Created:** 2025-01-09\n\n### Time Savings\n- **Estimated:** ~30 min per application (vs 2 hours debugging)\n- **Total saved:** 0 min (first instance)\n\n### Sources\n- memory/episodic/code/2025-01-09-postgresql-indexing-fix.md\n\n---\n\n"
)
```

**Result**: NEW pattern created with LOW confidence ✅

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
  file_path="memory/episodic/code/2025-01-09-postgresql-indexing-fix.md",
  content="""
# PostgreSQL Indexing Fix - Client A Analytics Dashboard - 2025-01-09

## Context
**Project:** Client A - E-commerce Analytics
**Goal:** Fix slow analytics dashboard (8+ second load times)
**Duration:** 2.5 hours (2h debugging, 30min fix)

## What Happened
User analytics dashboard was taking 8.2 seconds to load. Traced issue to slow PostgreSQL query joining users table with analytics_events table (2.3M rows).

## Solution
Added index on foreign key column:
```sql
CREATE INDEX idx_analytics_events_user_id ON analytics_events(user_id);
```

Query plan changed:
- Before: Seq Scan on analytics_events (8.2s)
- After: Index Scan using idx_analytics_events_user_id (0.3s)

## Patterns Applied
- **None** (this was the first instance - pattern originated here)

## Learnings Extracted
- **New pattern**: PostgreSQL Foreign Key Indexing (confidence: LOW)
- PostgreSQL does NOT automatically index foreign keys
- Always check EXPLAIN ANALYZE for Seq Scan on large tables
- Foreign key indexes are critical for JOIN performance

## Outcome
**Result:** SUCCESS
**Time saved:** 0 min (first instance, but will save ~30 min on future occurrences)
**Quality:** 9/10 (works perfectly, slight delay in identifying root cause)

## Linked Patterns
→ Created: memory/semantic/patterns/dev-patterns.md#postgresql-foreign-key-indexing
→ Confidence: NEW → LOW (1 example)

## Next Time
- Check for missing FK indexes BEFORE debugging slow queries
- Run EXPLAIN ANALYZE as first debugging step
- Document all FK indexes in migration files
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

**Current content** (Week 3 section):
```markdown
## Week 3 (2025-01-06 to 2025-01-12)

### Patterns Learned
- New: JWT refresh tokens for mobile (confidence: LOW)

### Brain Stats
- Semantic memory: 28 files
- Episodic memory: 31 experiences
- Total patterns: 17

### Time Savings This Week
**Total saved:** 2.5 hours
```

**Tool: Edit**
```bash
Edit(
  file_path="brain-health/growth-log.md",
  old_string="### Patterns Learned\n- New: JWT refresh tokens for mobile (confidence: LOW)",
  new_string="### Patterns Learned\n- New: JWT refresh tokens for mobile (confidence: LOW)\n- New: PostgreSQL Foreign Key Indexing (confidence: LOW)"
)

Edit(
  file_path="brain-health/growth-log.md",
  old_string="- Episodic memory: 31 experiences",
  new_string="- Episodic memory: 32 experiences (+1)"
)

Edit(
  file_path="brain-health/growth-log.md",
  old_string="- Total patterns: 17",
  new_string="- Total patterns: 18 (+1 new)"
)
```

**Tool: Read**
```bash
Read("brain-health/pattern-confidence.md")
```

**Tool: Edit** (add to LOW confidence section)
```bash
Edit(
  file_path="brain-health/pattern-confidence.md",
  old_string="## Low Confidence (1 example)\n",
  new_string="## Low Confidence (1 example)\n- PostgreSQL Foreign Key Indexing (1 example, 0 min saved, created: 2025-01-09)\n"
)
```

**Result**: Brain health metrics updated ✅

---

### Step 7: Show Impact

**Output to User**:
```markdown
✅ Learning extracted and saved!

📊 Pattern Update:
**Created NEW pattern:** "PostgreSQL Foreign Key Indexing"
- Confidence: NEW → LOW
- Based on: 1 example
- Estimated time savings: ~30 min per future application

📝 Experience Logged:
memory/episodic/code/2025-01-09-postgresql-indexing-fix.md

🧠 Brain Growth:
- Total patterns: 17 → 18 (+1 new this week)
- High confidence patterns: 6 (unchanged)
- Low confidence patterns: 4 → 5 (+1)

💡 Impact Next Time:
When you encounter slow PostgreSQL queries with JOINs, I'll proactively suggest:
- Check for missing foreign key indexes
- Run EXPLAIN ANALYZE to identify Seq Scans
- Add indexes on FK columns for large tables

**Estimated future time savings:** ~30 min per occurrence (vs 2 hours debugging)
**Pattern will promote to MEDIUM after 1 more example**
```

---

## Pattern Confidence Progression (Hypothetical Future)

### Second Occurrence (Week 5)

**Scenario**: Client B project has slow user dashboard query

**User runs**: `/learn` after fixing similar issue

**Result**: Pattern promoted from LOW → MEDIUM
- Examples: 2 (Client A + Client B)
- Time saved this occurrence: ~45 min (knew to check FK indexes immediately)
- Cumulative time saved: 45 min

### Fifth Occurrence (Week 10)

**Scenario**: Internal product optimization

**Result**: Pattern promoted from MEDIUM → HIGH
- Examples: 5 (Client A, B, C + Internal Product × 2)
- Time saved this occurrence: ~50 min (instant recognition)
- Cumulative time saved: 3.5 hours
- **Expert-level knowledge achieved** ✅

---

## Key Takeaways

**Pattern extraction in action**:
1. ✅ Concrete example captured (not abstract)
2. ✅ Time savings estimated and tracked
3. ✅ Confidence level set appropriately (LOW for first instance)
4. ✅ Episodic memory links to semantic pattern
5. ✅ Brain health metrics updated automatically

**ROI Demonstration**:
- **Week 3**: 2.5 hours spent (debugging + fix)
- **Week 5**: 45 min saved (pattern applied)
- **Week 10**: 50 min saved × 3 more occurrences = 2.5 hours saved
- **Net ROI**: Break-even by Week 10, then pure savings

**The magic**: By Week 10, the user has EXPERT-level knowledge on PostgreSQL FK indexing, saving 30-50 min every time this comes up. The 3-minute learning extraction compounds into hours of savings.
