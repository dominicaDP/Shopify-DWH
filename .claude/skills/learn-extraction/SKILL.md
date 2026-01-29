---
name: learn-extraction
description: |
  Extract learnings from recent work and compound knowledge in semantic memory.
  Converts experiences into reusable patterns, tracking confidence levels and time savings.
  Uses interactive questioning to capture context, then updates semantic memory, creates episodic records, and measures brain growth.
allowed-tools: "Read,Write,Edit,Grep,Bash"
---

# Learning Extraction Skill

## Skill Metadata
- **Version**: 1.0.0
- **Author**: the user's Second Brain Team
- **Category**: knowledge-extraction
- **Tags**: learning, pattern-extraction, semantic-memory, knowledge-compounding, second-brain

**Dependencies**:
- **Files**: `memory/semantic/patterns/*.md`, `memory/episodic/*/*.md`, `brain-health/growth-log.md`, `brain-health/pattern-confidence.md`

**Input Parameters**:
- `work_completed` (string, required): Description of what user just finished
- `work_type` (enum, required): code | client | content | research | other
- `challenge` (string, optional): Key challenge or root cause
- `solution` (string, optional): How user solved it
- `pattern_insight` (string, required): The pattern to remember

**Output**:
- `pattern_updated` (object): {name, old_confidence, new_confidence, examples_count}
- `episodic_memory_file` (string): Path to created experience file
- `brain_growth` (object): {total_patterns, high_confidence_count, time_saved_estimate}
- `next_application` (string): Suggestion for when to apply pattern next

**Success Metrics**:
- Pattern identification rate: 80%+
- Time per extraction: < 3 minutes
- Pattern application ROI: 10-15x return on time invested
- High confidence patterns: 30%+ of total within 12 weeks

**Examples**: See `examples/` directory (01-code-fix, 02-client-work, 03-content-creation)

**Tests**: See `tests/` directory (pattern-confidence-promotion, episodic-memory-creation, brain-health-metrics-update)

---

## Executive Snapshot

**Knowledge Compounding System**: Converts raw work experiences into reusable patterns stored in semantic memory. Every significant work session contains patterns worth capturing. The goal: make each project easier than the last.

**Core Philosophy**: Your brain compounds. Pattern extraction takes 2-3 minutes but saves 30-45 minutes per future application (10-15x ROI).

**Quality Standard**: Patterns must include concrete examples, time savings estimates, and clear "when to apply" guidance. Confidence levels promote automatically (LOW → MEDIUM → HIGH) based on reinforcement frequency.

---

## When to Run

**Trigger moments**:
- After fixing a tricky bug
- After completing a significant feature
- After a client meeting with new insights
- After creating content that worked well
- End of work session (daily habit)

**Time investment**: 2-3 minutes per extraction

**ROI**: 30-45 min saved per pattern application (10-15x return)

---

## Workflow Overview (7 Steps)

### 1. Identify Recent Work
Ask user what they completed (code/client/content/research). Store work type for categorization.

### 2. Extract Learning
Ask 3-4 targeted questions based on work type:
- Code: Root cause? Solution? Pattern to remember?
- Client: What was unique? What worked well? What surprised you?
- Content: What resonated? What was your process?
- Research: Key insight? How will you apply it?

### 3. Search for Similar Patterns
Grep semantic memory for existing patterns. Decision: NEW pattern or REINFORCEMENT?

### 4. Update Semantic Memory
- **If NEW**: Create pattern entry (LOW confidence, 1 example)
- **If REINFORCEMENT**: Add example, update confidence (may promote LOW→MEDIUM or MEDIUM→HIGH)

### 5. Create Episodic Memory
Log the experience with context, solution, patterns applied, outcome, time saved, and bidirectional links to semantic patterns.

### 6. Update Brain Health Metrics
Update `growth-log.md` (weekly patterns learned, time saved) and `pattern-confidence.md` (confidence level tracking).

### 7. Show Impact
Display pattern update, confidence change, time saved, brain growth stats, and suggest when to apply pattern next.

📖 **For detailed execution with tool calls**: `Read {baseDir}/references/workflow-detailed.md`

---

## Pattern Confidence Levels

| Level | Examples | Status | Promotion |
|-------|----------|--------|-----------|
| **LOW** | 1 | Hypothesis | First occurrence |
| **MEDIUM** | 2-4 | Validated | After 2nd occurrence |
| **HIGH** | 5+ | Mastered | After 5th occurrence |

**Time savings correlation**:
- LOW → MEDIUM: Save 30-60 min on 2nd application
- MEDIUM → HIGH: Save 60-120 min by 5th application
- Expert mode: 80% time reduction

📖 **For confidence logic details**: `Read {baseDir}/references/confidence-logic.md`

---

## Memory Types

### Semantic Memory (What You Know)
Abstracted, reusable patterns with confidence levels:
- `dev-patterns.md` - Technical patterns
- `client-patterns.md` - Client-specific patterns
- `content-patterns.md` - Content creation patterns
- `pm-patterns.md` - Product/process patterns

### Episodic Memory (What You've Done)
Specific experiences with dates and outcomes:
- `code/` - Development experiences
- `projects/` - Project milestones
- `content/` - Content created
- `learning/` - Learning experiences

### Procedural Memory (How You Do Things)
Step-by-step workflows and checklists.

**Pattern Flow**: Experience (episodic) → Pattern extraction (semantic) → Future application

📖 **For memory organization details**: `Read {baseDir}/references/pattern-types.md`

---

## Success Metrics

**Goal**: Compound knowledge - make each project easier

**Weekly Targets** (Week 12):
- 1-3 new patterns captured
- 2-4 hours saved from pattern application
- 30%+ patterns at HIGH confidence
- 80%+ pattern application rate

**ROI Timeline**:
- **Week 1**: Setup (feels manual, "am I doing this right?")
- **Week 4**: Early wins (starts connecting, "oh, I've seen this before")
- **Week 12**: Expert mode (patterns everywhere, "I know exactly what to do")

---

## Integration with Other Commands

### Before: `/recall [topic]`
Search semantic memory before starting work: "Have I solved this before?"

### During: `/switch [project]`
Load project context and related patterns.

### After: `/learn`
Extract pattern from completed work.

### Weekly: `/grow`
Review brain health, celebrate pattern promotions, see cumulative time saved.

---

## Usage Tips

**Don't over-think it**:
- 2-3 minutes is enough
- Simple answers are fine
- Patterns emerge naturally over time

**Capture broadly, refine later**:
- Don't filter at capture time
- Week 1: Everything feels new
- Week 4: Connections start appearing
- Week 12: Patterns are obvious

**The magic**:
By Week 12, you have expert-level knowledge on 10-20 topics, saving 2-4 hours/week. The 3-minute learning extraction compounds into hours of savings.

---

## Progressive Disclosure

**Core operational workflow**: This file (~200 lines)

**Detailed execution**:
- 📖 `Read {baseDir}/references/workflow-detailed.md` - Full 7-step execution with tool calls
- 📖 `Read {baseDir}/references/confidence-logic.md` - Pattern confidence rules and promotion logic
- 📖 `Read {baseDir}/references/pattern-types.md` - Memory organization and pattern categories

**Concrete examples**:
- 📖 `Read {baseDir}/examples/01-code-fix-postgresql-indexing.md` - Technical pattern extraction
- 📖 `Read {baseDir}/examples/02-client-work-discovery-process.md` - Client work pattern reinforcement
- 📖 `Read {baseDir}/examples/03-content-creation-blog-structure.md` - Content process pattern

**Validation tests**:
- 📖 `Read {baseDir}/tests/pattern-confidence-promotion.test.md` - Confidence level transitions
- 📖 `Read {baseDir}/tests/episodic-memory-creation.test.md` - File structure and linking
- 📖 `Read {baseDir}/tests/brain-health-metrics-update.test.md` - Growth tracking validation

---

*Last Updated: 2025-01-09*
*Version: 1.0.0*
*Lines: ~200 (entry point) + 3 reference files (on-demand)*
