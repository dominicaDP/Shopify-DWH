# Task Management - Priority Assignment Logic

Automatic priority detection rules.

## Priority Levels

### URGENT (Due Today / Critical)

**Auto-assign when task includes**:
- urgent, critical, asap, now, today
- blocking, blocker, p0
- production, prod, live
- security, vulnerability
- client-critical

**Examples**:
- "Fix production payment bug" → URGENT
- "Critical security patch needed" → URGENT  
- "Blocking issue for client launch" → URGENT

**Time expectation**: Within 4 hours

### HIGH (Important, Needed Soon)

**Auto-assign when task includes**:
- important, priority, high
- client-requested, needed
- deadline, due soon
- required, must-have

**Examples**:
- "Client requested dashboard feature" → HIGH
- "Important: Complete API integration" → HIGH
- "Deadline: Friday" → HIGH

**Time expectation**: Within 2-3 days

### NORMAL (Standard Work)

**Default priority** when no indicators present.

**Examples**:
- "Add export feature" → NORMAL
- "Improve error messages" → NORMAL
- "Update documentation" → NORMAL

**Time expectation**: Within 1-2 weeks

### LOW (Nice-to-Have / Backlog)

**Auto-assign when task includes**:
- nice-to-have, nice to have
- someday, maybe, future
- backlog, explore, consider
- investigate, research
- low-priority, low priority

**Examples**:
- "Nice to have: dark mode" → LOW
- "Someday: mobile app" → LOW
- "Explore caching strategy" → LOW

**Time expectation**: No deadline, work when capacity available

## Override Priority

User can specify priority explicitly:

```
/add-task project "Complete feature" --priority HIGH
/add-task project "urgent: Fix bug" --priority URGENT
```

## Conflict Resolution

If multiple priority indicators:
1. URGENT beats all others
2. LOW explicit beats HIGH implied
3. Most recent indicator wins

**Example**: "Nice to have urgent fix" → URGENT (urgency overrides)
