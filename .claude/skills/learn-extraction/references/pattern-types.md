# Pattern Types & Memory Organization

Understanding the three memory types and how patterns flow between them.

---

## Three Memory Types

### 1. Semantic Memory (What You Know)

**Location**: `memory/semantic/`

**Purpose**: Abstracted, reusable knowledge and patterns

**Structure**:
```
memory/semantic/
├── patterns/
│   ├── dev-patterns.md        # Technical patterns
│   ├── client-patterns.md     # Client-specific patterns
│   ├── content-patterns.md    # Content creation patterns
│   └── pm-patterns.md         # Product/process patterns
├── tech/                       # Technical documentation
├── clients/                    # Client contexts
├── products/                   # Product knowledge
└── ideas/                      # Captured ideas
```

**Characteristics**:
- Timeless (patterns don't expire)
- Abstract (applies to multiple situations)
- Confidence-tracked (LOW/MEDIUM/HIGH)
- ROI-measured (time savings tracked)

**Example**:
```markdown
## PostgreSQL Foreign Key Indexing

### Description
Always add indexes on foreign key columns in PostgreSQL

### When to Use
- Any table with foreign key relationships
- Tables > 1000 rows that are frequently joined

### Confidence: HIGH (6 examples)
### Time Savings: 4 hours total
```

---

### 2. Episodic Memory (What You've Done)

**Location**: `memory/episodic/`

**Purpose**: Specific experiences with dates, context, and outcomes

**Structure**:
```
memory/episodic/
├── code/                # Development experiences
├── projects/            # Project milestones
├── content/             # Content created
└── learning/            # Learning experiences
```

**Characteristics**:
- Time-bound (specific dates)
- Concrete (real experiences)
- Outcome-tracked (SUCCESS/PARTIAL/BLOCKED)
- Pattern-linked (references semantic memory)

**Example**:
```markdown
# PostgreSQL Indexing Fix - Client A - 2025-01-09

## Context
**Project:** Client A Analytics Dashboard
**Duration:** 2.5 hours

## What Happened
Query taking 8.2s, added FK index, now 0.3s

## Patterns Applied
- **PostgreSQL Foreign Key Indexing** (reinforced)

## Outcome
**Result:** SUCCESS
**Time saved:** 105 min (vs first time)
```

---

### 3. Procedural Memory (How You Do Things)

**Location**: `memory/procedural/workflows/`

**Purpose**: Step-by-step processes and workflows

**Structure**:
```
memory/procedural/
└── workflows/
    ├── deployment-checklist.md
    ├── client-onboarding.md
    ├── bug-triage-process.md
    └── content-publishing.md
```

**Characteristics**:
- Sequential (step-by-step)
- Repeatable (checklists)
- Tool-specific (bash commands, tool configurations)

**Example**:
```markdown
# Deployment Checklist

1. Run tests: `npm test`
2. Build: `npm run build`
3. Deploy to staging: `vercel --env=staging`
4. QA check: [checklist]
5. Deploy to prod: `vercel --prod`
6. Monitor logs: [dashboard link]
```

---

## Pattern Flow

### From Experience → Pattern (Learning Extraction)

```
Episodic Memory          Semantic Memory
(What happened)    →     (Pattern extracted)

2025-01-09:             PostgreSQL FK Indexing
Client A bug fix   →    (LOW confidence, 1 example)

2025-01-15:             PostgreSQL FK Indexing
Client B optimization → (MEDIUM confidence, 2 examples)

2025-02-03:             PostgreSQL FK Indexing
Internal product   →    (HIGH confidence, 5 examples)
```

**Tool**: `/learn` command creates this flow

---

### From Pattern → Application (Memory Recall)

```
Semantic Memory         New Work
(Pattern library)  →    (Apply pattern)

PostgreSQL FK Indexing  Client D slow query
(HIGH confidence)  →    Immediately check FK indexes
                        (Save 90 min vs debugging)
```

**Tool**: `/recall` command surfaces patterns

---

## Pattern Categories

### Technical Patterns (dev-patterns.md)
- Code optimization techniques
- Database design patterns
- Architecture decisions
- Debugging workflows
- Performance optimizations

**Example topics**:
- PostgreSQL indexing
- React performance
- API design patterns
- Error handling strategies

---

### Client Patterns (client-patterns.md)
- Client communication strategies
- Discovery processes
- Project scoping approaches
- Requirement gathering techniques
- Stakeholder management

**Example topics**:
- Structured discovery calls
- Change management for AI projects
- Procurement navigation
- Client onboarding flows

---

### Content Patterns (content-patterns.md)
- Writing structures
- Content formats
- Distribution strategies
- Engagement tactics
- Production workflows

**Example topics**:
- Problem-first blog structure
- LinkedIn commenting playbooks
- Video script templates
- Newsletter formats

---

### Process Patterns (pm-patterns.md)
- Project management approaches
- Planning frameworks
- Prioritization methods
- Team coordination strategies
- Product development processes

**Example topics**:
- Agile sprint planning
- Feature prioritization
- Roadmap creation
- Stakeholder alignment

---

## Memory Interconnections

### Bidirectional Links

**Semantic → Episodic**:
```markdown
## PostgreSQL FK Indexing (semantic)

### Sources
- memory/episodic/code/2025-01-09-client-a-fix.md
- memory/episodic/code/2025-01-15-client-b-optimization.md
```

**Episodic → Semantic**:
```markdown
# Client A Fix (episodic)

## Linked Patterns
→ Reinforced: memory/semantic/patterns/dev-patterns.md#postgresql-fk-indexing
→ Confidence: LOW → MEDIUM (2 examples)
```

---

## When to Create Each Type

### Create Semantic Pattern When:
- ✅ You've solved the same problem 2+ times
- ✅ Solution is abstract enough to apply elsewhere
- ✅ Time savings are measurable
- ❌ Don't create for one-off situations

### Create Episodic Memory When:
- ✅ Completing significant work
- ✅ Milestone reached
- ✅ Learning extracted
- ✅ Pattern applied (track time saved)
- ❌ Don't create for trivial tasks

### Create Procedural Workflow When:
- ✅ Repeatable process exists
- ✅ Steps are sequential
- ✅ Team needs to follow same process
- ❌ Don't create for flexible creative work

---

## Example: Full Cycle

**Week 1**: Fix Client A bug (episodic)
→ Extract pattern (semantic, LOW confidence)

**Week 2**: Fix similar Client B issue (episodic)
→ Reinforce pattern (semantic, MEDIUM confidence)
→ Save 60 min vs Week 1

**Week 4**: Optimize Client C database (episodic)
→ Reinforce pattern (semantic, still MEDIUM)
→ Save 80 min

**Week 6**: Create deployment checklist (procedural)
→ Always check FK indexes before deployment

**Week 8**: Client D slow query (episodic)
→ Apply pattern instantly (semantic, HIGH confidence)
→ Save 120 min (expert-level speed)

**Result**: From 0 → Expert in 8 weeks, 4+ hours saved cumulatively

---

## Best Practices

1. **Episodic first, semantic later** - Capture experiences, extract patterns weekly
2. **Don't force abstraction** - Let patterns emerge naturally (2+ occurrences)
3. **Maintain bidirectional links** - Always link episodic ↔ semantic
4. **Track time savings** - Measure ROI on every pattern application
5. **Review quarterly** - Archive stale patterns, merge duplicates

---

*Reference: examples/ directory for concrete instances of each memory type*
