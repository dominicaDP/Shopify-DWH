# Learning Extraction - Detailed Workflow

Complete step-by-step execution guide with tool calls and decision logic.

---

## Step 1: Identify Recent Work

**Action**: Ask user what they just completed

**Tool: Interactive Question**
```
What did you just complete?

Options:
1. Code work (bug fix, feature, refactor)
2. Client project milestone
3. Content creation (blog, video, social)
4. Research/learning
5. Something else: ________
```

**Store**: `work_type` (code | client | content | research | other)

---

## Step 2: Extract Learning (Quick Questions)

**Action**: Based on work type, ask 3-4 targeted questions

**For Code Work:**
1. "What was the root cause / key challenge?"
2. "How did you solve it?"
3. "Have you seen similar issues before?"
4. "What's the pattern to remember?"

**For Client Work:**
1. "What was unique about this client's needs?"
2. "What worked particularly well?"
3. "What surprised you?"

**For Content:**
1. "What topic/format resonated most?"
2. "What was your process?"

**For Research/Learning:**
1. "What's the key insight to remember?"
2. "How will you apply this?"

**Store**: User responses for pattern creation

---

## Step 3: Search for Similar Patterns

**Tool: Grep** (search semantic memory for similar patterns)
```bash
Grep(
  pattern="<user's pattern keyword>",
  path="memory/semantic/patterns/",
  output_mode="files_with_matches"
)
```

**Decision Logic**:
- **If similar pattern exists** → This is REINFORCEMENT (increase confidence)
- **If no match** → This is NEW pattern (create entry)

**Domain mapping**:
```javascript
const domain = {
  code: "dev-patterns.md",
  client: "client-patterns.md",
  content: "content-patterns.md",
  research: "pm-patterns.md"
}[work_type]
```

---

## Step 4: Update Semantic Memory

### Option A: Reinforcing Existing Pattern

**Tool: Read**
```bash
Read("memory/semantic/patterns/<domain>-patterns.md")
```

**Tool: Edit** (add new example to existing pattern)
```markdown
Find section:
## Pattern Name
### Examples
- Example 1 (2024-12-15): ...
- Example 2 (2025-01-05): ...

Add:
- Example 3 (<TODAY>): <user's new experience> ✅

Update confidence:
### Confidence
- **Level:** MEDIUM → HIGH (was LOW)
- **Based on:** 3 examples (was 2)
- **Last reinforced:** <TODAY>

Add source link:
### Sources
- memory/episodic/<domain>/<TODAY>-<slug>.md ← NEW
```

**Confidence promotion rules**:
- **LOW**: 1 example
- **MEDIUM**: 2-4 examples
- **HIGH**: 5+ examples

### Option B: Creating New Pattern

**Tool: Write** (append to domain patterns file)
```bash
Write(
  file_path="memory/semantic/patterns/<domain>-patterns.md",
  content="<existing_content>

## <Pattern Name>

### Description
<pattern insight>

### When to Use
<use case description>

### Examples
- Example 1 (<TODAY>): <user's experience>

### Confidence
- **Level:** LOW
- **Based on:** 1 example
- **Created:** <TODAY>

### Time Savings
- **Estimated:** ~<X> min per application
- **Total saved:** 0 min (first instance)

### Sources
- memory/episodic/<domain>/<TODAY>-<slug>.md
"
)
```

---

## Step 5: Create Episodic Memory Entry

**Tool: Bash** (get current date)
```bash
Bash(command="date '+%Y-%m-%d'")
```

**Tool: Write** (save the experience)
```bash
Write(
  file_path="memory/episodic/<domain>/<TODAY>-<slug>.md",
  content="""
# <Title> - <Date>

## Context
**Project:** <project name>
**Goal:** <what you were trying to achieve>
**Duration:** <time spent>

## What Happened
<description of work>

## Solution
<how you solved it>

## Patterns Applied
- **<Pattern name>** (from semantic memory)
  - <how it helped>
  - Time saved: ~<X> min

## Learnings Extracted
- Reinforced: <pattern> (confidence: <old> → <new>)
- New: <new insight>

## Outcome
**Result:** SUCCESS | PARTIAL | BLOCKED
**Time saved:** <X> min (from pattern application)
**Quality:** <rating>/10

## Linked Patterns
→ Reinforced: memory/semantic/patterns/<domain>-patterns.md#<slug>
→ Confidence: <old> → <new>

## Next Time
- <what to do differently>
  """
)
```

**Slug generation**:
```javascript
const slug = pattern_name
  .toLowerCase()
  .replace(/\s+/g, '-')
  .replace(/[^a-z0-9-]/g, '')
```

---

## Step 6: Update Brain Health Metrics

**Tool: Read** (get current metrics)
```bash
Read("brain-health/growth-log.md")
```

**Tool: Edit** (update current week section)
```markdown
Find:
## Week <N> (<Date Range>)

Update:
### Patterns Learned
- Reinforced: <pattern name> (confidence: <old> → <new>)
- New: <pattern name> (confidence: LOW)

### Brain Stats
- Semantic memory: <N> files (+1 this week OR +0)
- Episodic memory: <N> experiences (+1 this week)
- Total patterns: <N> (+1 new OR +0 reinforced)

### Time Savings This Week
- <Work type>: <X> min (<pattern applied>)
**Total saved:** <X> hours
```

**Tool: Edit** (update pattern confidence tracking)
```bash
Edit("brain-health/pattern-confidence.md")

# Move pattern between confidence levels if promoted
# Example: Move from Medium → High confidence list
```

**Confidence level sections**:
```markdown
## High Confidence (5+ examples)
- <pattern name> (N examples, <X> hours saved)

## Medium Confidence (2-4 examples)
- <pattern name> (N examples, <X> hours saved)

## Low Confidence (1 example)
- <pattern name> (1 example, <X> hours estimated)
```

---

## Step 7: Show Impact

**Output to user:**
```markdown
✅ Learning extracted and saved!

📊 Pattern Update:
**Reinforced:** "<pattern name>"
- Confidence: <old> → <new>
- Now based on: <N> examples (was <N-1>)
- Time saved today: ~<X> min

📝 Experience Logged:
memory/episodic/<domain>/<TODAY>-<slug>.md

🧠 Brain Growth:
- Total patterns: <N-1> → <N> (+1 new this week)
- High confidence patterns: <N-1> → <N> (+1)
- Avg time savings per pattern: <X> min

💡 Impact Next Time:
When you work on <similar task> again, I'll proactively suggest:
- <pattern application 1>
- <pattern application 2>
- <pattern application 3>

**Estimated cumulative time savings:** <X> hours this week
```

---

## Required Files Structure

```
memory/
├── semantic/
│   └── patterns/
│       ├── dev-patterns.md        # Technical patterns
│       ├── client-patterns.md     # Client-specific patterns
│       ├── content-patterns.md    # Content creation patterns
│       └── pm-patterns.md         # Product/process patterns
├── episodic/
│   ├── code/                      # Development experiences
│   ├── projects/                  # Project milestones
│   ├── content/                   # Content created
│   └── learning/                  # Learning experiences
└── procedural/
    └── workflows/                 # How-to workflows

brain-health/
├── growth-log.md                  # Weekly growth tracking
├── pattern-confidence.md          # Pattern confidence levels
└── metrics.md                     # Time savings and KPIs

projects/
├── CURRENT                        # Current active project
└── <project-name>/
    └── context.md                 # Project context
```

---

## Integration Notes

### Future: Automatic Triggers

**On-commit hook**: "Looks like you fixed a bug. Extract learning?"

**On-task-complete**: "Task marked done. Extract learning?"

**On-session-end**: "Before you go, any learnings to capture?"

### Current Manual Workflow

**For now**:
- Manual `/learn` after significant work
- Set reminder: Run `/learn` at end of each work session
- Daily habit: Review `/grow` weekly to see impact
