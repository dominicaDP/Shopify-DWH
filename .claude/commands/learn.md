---
name: learn
description: Extract learnings from recent work and update semantic memory with patterns
allowed-tools: Read, Write, Edit, Grep, Bash
---

# Learning Extraction Command

Extract patterns from the user's recent work and compound knowledge in semantic memory.

## Execution Steps

### Step 1: Identify Recent Work

**Action:** Ask user what they just completed
```
What did you just complete?

Options:
1. Code work (bug fix, feature, refactor)
2. Client project milestone
3. Content creation (blog, video, social)
4. Research/learning
5. Something else: ________
```

### Step 2: Extract Learning (Quick Questions)

**Action:** Based on work type, ask 3-4 targeted questions

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

### Step 3: Search for Similar Patterns

**Tool: Grep**
```bash
# Search semantic memory for similar patterns
Grep(
  pattern="<user's pattern keyword>",
  path="memory/semantic/patterns/",
  output_mode="files_with_matches"
)
```

**Decision:**
- If similar pattern exists → This is REINFORCEMENT (increase confidence)
- If no match → This is NEW pattern (create entry)

### Step 4: Update Semantic Memory

**Tool: Read** (if pattern exists)
```bash
Read("memory/semantic/patterns/<domain>-patterns.md")
```

**Tool: Edit** (if reinforcing existing pattern)
```markdown
# Add new example to existing pattern

Find section:
## Pattern Name
### Examples
- Example 1 (2024-12-15): ...
- Example 2 (2025-01-05): ...

Add:
- Example 3 (TODAY): <user's new experience> ✅

Update confidence:
### Confidence
- **Level:** MEDIUM → HIGH (was LOW)
- **Based on:** 3 examples (was 2)
- **Last reinforced:** <TODAY>

Add source link:
### Sources
- memory/episodic/<domain>/<TODAY>-<slug>.md ← NEW
```

**Tool: Write** (if creating new pattern)
```bash
# Create new pattern entry in appropriate domain file
Write(
  file_path="memory/semantic/patterns/<domain>-patterns.md",
  content="... append new pattern ..."
)
```

### Step 5: Create Episodic Memory Entry

**Tool: Write**
```bash
# Save the experience
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
**Quality:** <rating>

## Linked Patterns
→ Reinforced: memory/semantic/patterns/<domain>-patterns.md#<slug>
→ Confidence: <old> → <new>

## Next Time
- <what to do differently>
  """
)
```

### Step 6: Update Brain Health Metrics

**Tool: Read**
```bash
Read("brain-health/growth-log.md")
```

**Tool: Edit**
```markdown
# Update current week section

Find:
## Week <N> (<Date Range>)

Update:
### Patterns Learned
- Reinforced: <pattern name> (confidence: <old> → <new>)
- New: <pattern name> (confidence: LOW)

### Brain Stats
- Semantic memory: <N> files (+1 this week)
- Episodic memory: <N> experiences (+1 this week)
- Total patterns: <N> (+1 new OR +0 reinforced)

### Time Savings This Week
- <Work type>: <X> min (<pattern applied>)
**Total saved:** <X> hours
```

**Tool: Edit**
```bash
Edit("brain-health/pattern-confidence.md")

# Move pattern between confidence levels if promoted
# Example: Move from Medium → High confidence list
```

### Step 7: Show Impact

**Output to user:**
```
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

## Success Metrics

**Goal:** Compound knowledge - make each project easier

**Metrics:**
- Time cost: 2-3 min per extraction
- Time saved: 30-45 min per pattern application
- ROI: 10-15x return on time invested

## Required Files

This command expects:
- `memory/semantic/patterns/<domain>-patterns.md` (dev, pm, content, client)
- `memory/episodic/<domain>/` directories
- `brain-health/growth-log.md`
- `brain-health/pattern-confidence.md`

## Integration Notes

**Future: Automatic Triggers**
- on-commit hook: "Looks like you fixed a bug. Extract learning?"
- on-task-complete: "Task marked done. Extract learning?"
- on-session-end: "Before you go, any learnings to capture?"

**For now:**
- Manual `/learn` after significant work
- Set reminder: Run `/learn` at end of each work session

## Notes for the user

**When to run /learn:**
- After fixing a tricky bug
- After completing a significant feature
- After a client meeting with new insights
- After creating content that worked well
- End of work session

**Don't over-think it:**
- 2-3 minutes is enough
- Simple answers are fine
- Patterns emerge naturally over time

**The magic:**
- Week 1: Feels manual, "am I doing this right?"
- Week 4: Starts connecting - "oh, I've seen this before"
- Week 12: Patterns everywhere - "I know exactly what to do"
