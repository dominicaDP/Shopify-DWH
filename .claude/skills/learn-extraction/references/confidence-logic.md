# Pattern Confidence Logic

Understanding how pattern confidence levels work and when they promote.

---

## Confidence Levels

### LOW Confidence (1 example)
**What it means**: First time encountering this pattern
**When created**: When user extracts a new learning
**Status**: Hypothesis - "I think this might be a pattern"

**Example**:
```markdown
## PostgreSQL Foreign Key Indexing

### Confidence
- **Level:** LOW
- **Based on:** 1 example
- **Created:** 2025-01-09
```

**Time savings**: 0 min (first instance, no prior pattern to apply)

---

### MEDIUM Confidence (2-4 examples)
**What it means**: Pattern is reinforced, starting to be reliable
**When promoted**: After 2nd occurrence of same pattern
**Status**: Validated - "This is definitely a pattern"

**Example**:
```markdown
## PostgreSQL Foreign Key Indexing

### Confidence
- **Level:** MEDIUM
- **Based on:** 3 examples
- **Last reinforced:** 2025-01-15
```

**Time savings**: Starting to accumulate (2nd instance: ~30-60 min saved)

---

### HIGH Confidence (5+ examples)
**What it means**: Expert-level knowledge, highly reliable
**When promoted**: After 5th occurrence of same pattern
**Status**: Mastered - "I know exactly how to handle this"

**Example**:
```markdown
## PostgreSQL Foreign Key Indexing

### Confidence
- **Level:** HIGH
- **Based on:** 6 examples
- **Last reinforced:** 2025-02-03
```

**Time savings**: Maximum efficiency (5th+ instance: 80% time reduction)

---

## Promotion Rules

### Rule 1: Automatic Promotion Based on Example Count

```javascript
function determineConfidence(exampleCount) {
  if (exampleCount === 1) return "LOW"
  if (exampleCount >= 2 && exampleCount <= 4) return "MEDIUM"
  if (exampleCount >= 5) return "HIGH"
}
```

### Rule 2: Always Count Actual Examples

**Don't trust stated numbers** - Always count actual example entries:

```bash
# Count examples in pattern section
Grep(
  pattern="^- Example \\d+",
  path="memory/semantic/patterns/<domain>-patterns.md",
  output_mode="count"
)
```

### Rule 3: Bidirectional Updates

Confidence can go **UP or DOWN**:
- Add example → May promote (LOW → MEDIUM or MEDIUM → HIGH)
- Remove example → May demote (HIGH → MEDIUM or MEDIUM → LOW)

---

## Time Savings Correlation

### LOW → MEDIUM Transition (1 → 2 examples)
**Time saved on 2nd occurrence**: 30-60 min
**Why**: Instant recognition instead of rediscovering

**Example**: PostgreSQL indexing bug
- 1st time: 2.5 hours (debugging from scratch)
- 2nd time: 45 min (knew to check FK indexes)
- **Saved**: 105 min

### MEDIUM → HIGH Transition (4 → 5 examples)
**Time saved on 5th occurrence**: 60-120 min
**Why**: Expert-level speed, muscle memory

**Example**: Client discovery process
- 1st-2nd time: 2 hours each (learning structure)
- 5th time: 90 min (instant execution)
- **Cumulative saved**: 5+ hours

---

## Visual Progression

```
Week 1:  [LOW]     1 example   | 0 min saved    | "First time"
Week 2:  [MEDIUM]  2 examples  | 60 min saved   | "I've seen this"
Week 4:  [MEDIUM]  3 examples  | 120 min saved  | "Getting good"
Week 6:  [MEDIUM]  4 examples  | 180 min saved  | "Almost expert"
Week 8:  [HIGH]    5 examples  | 240 min saved  | "Expert mode"
Week 12: [HIGH]    8 examples  | 480 min saved  | "Teaching others"
```

---

## Edge Cases

### Case 1: Pattern Merging
**Scenario**: Realize two LOW patterns are actually same pattern

**Action**:
1. Merge examples into single pattern
2. Recalculate confidence based on total examples
3. May jump from LOW → MEDIUM or even MEDIUM → HIGH

### Case 2: Pattern Splitting
**Scenario**: HIGH confidence pattern is too broad, split into 2 specific patterns

**Action**:
1. Create 2 new patterns
2. Distribute examples
3. Both may demote to MEDIUM or LOW initially

### Case 3: Stale Patterns
**Scenario**: HIGH confidence pattern last used 6 months ago

**Action**: Consider confidence "decay" (optional feature)
- Not implemented in v1.0
- Future: Confidence degrades if not reinforced in 90+ days

---

## Validation Commands

**Check confidence matches example count**:
```bash
# Read pattern
Read("memory/semantic/patterns/dev-patterns.md")

# Count examples for specific pattern
Grep(
  pattern="## PostgreSQL Foreign Key Indexing.*?^## ",
  path="memory/semantic/patterns/dev-patterns.md",
  output_mode="content",
  multiline=true
)

# Verify:
# - 1 example = LOW
# - 2-4 examples = MEDIUM
# - 5+ examples = HIGH
```

**Sync pattern-confidence.md**:
```bash
Read("brain-health/pattern-confidence.md")

# Verify each pattern is in correct section:
# - LOW section: only patterns with 1 example
# - MEDIUM section: only patterns with 2-4 examples
# - HIGH section: only patterns with 5+ examples
```

---

## Best Practices

1. **Don't force patterns** - If something only happened once, LOW confidence is correct
2. **Trust the numbers** - Confidence should strictly follow example count
3. **Celebrate promotions** - MEDIUM → HIGH is a milestone (expert knowledge achieved)
4. **Track time savings** - Update cumulative time saved on each reinforcement
5. **Review quarterly** - Check if HIGH confidence patterns are still relevant

---

*Reference: tests/pattern-confidence-promotion.test.md for validation tests*
