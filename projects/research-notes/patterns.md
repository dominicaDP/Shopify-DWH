# Patterns

**Project:** research-notes
**Last Updated:** 2026-01-29

---

## Overview

Project-specific patterns discovered during research. These complement the global patterns in `memory/semantic/patterns/`.

---

## Code Patterns

<!-- Add patterns discovered during research here -->

### Example Pattern Template

**Confidence:** LOW | MEDIUM | HIGH
**Uses:** [count]
**Category:** [code / architecture / testing / deployment]

**When to use:**
[Describe the scenario where this pattern applies]

**Implementation:**
```[language]
// Your code example here
```

**Why it works:**
[Explain the reasoning behind this pattern]

**Related:**
- [Link to related pattern or documentation]

---

## Research Patterns

### Knowledge Capture Workflow

**Confidence:** LOW
**Uses:** 0
**Category:** workflow

**When to use:**
When discovering new information worth preserving

**Process:**
1. Capture raw finding in notes.md
2. Identify if it's a reusable pattern
3. If pattern, add to patterns.md with context
4. Run `/learn` to extract into semantic memory

**Why it works:**
Structured capture ensures knowledge is searchable and reusable

---

## Code Snippet Organization

### Template for Code Snippets

**Confidence:** LOW
**Uses:** 0
**Category:** documentation

**Structure:**
```markdown
### [Snippet Name]

**Language:** [language]
**Use Case:** [when to use this]
**Source:** [where you found it]

\```[language]
// code here
\```

**Notes:**
[Any important context or gotchas]
```

---

## Anti-Patterns (What NOT to Do)

### Uncontextualized Snippets

**Why it's bad:**
Saving code without context makes it hard to use later

**Instead, do:**
Always include: language, use case, source, and any important notes

---

## Pattern Confidence Levels

| Level | Meaning | Promotion Criteria |
|-------|---------|-------------------|
| **LOW** | First use, untested | Just discovered |
| **MEDIUM** | Proven useful | Used 3+ times successfully |
| **HIGH** | Standard practice | Used 5+ times, documented |

### Promotion Checklist
- [ ] Used in 3+ situations
- [ ] No significant issues encountered
- [ ] Documented with clear examples
- [ ] Consider moving to global patterns

---

## Global Patterns Reference

See `memory/semantic/patterns/dev-patterns.md` for patterns that apply across all projects.
