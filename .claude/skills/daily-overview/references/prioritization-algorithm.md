# Daily Overview - Prioritization Algorithm

How tasks are ranked and suggested for daily focus.

## Prioritization Hierarchy

Tasks are ranked using a multi-factor algorithm that considers priority, urgency, time estimates, and pattern opportunities.

### Level 1: Priority Category (Highest Weight)

**Ranking order**:
1. **URGENT** - Due today / critical
2. **HIGH** - Important / client-requested
3. **NORMAL** - Standard work
4. **LOW** - Nice-to-have / backlog

**Rule**: URGENT always comes first, regardless of other factors.

---

### Level 2: Due Date (Within Category)

**Ranking within same priority**:
1. **Overdue** (past due date)
2. **Due today**
3. **Due this week**
4. **No due date**

**Example**:
```javascript
// Both URGENT, sort by due date
Task A: URGENT, due yesterday → Rank 1
Task B: URGENT, due today → Rank 2
```

---

### Level 3: Time Estimate (Realistic Capacity)

**Prefer shorter tasks** when at capacity limit:

```javascript
if (remainingCapacity < 3 && task.estimate > remainingCapacity) {
  // Skip task that won't fit today
  task.deferred = true
} else if (remainingCapacity < 3) {
  // Prioritize tasks that fit in remaining time
  task.priority += 10  // bonus for fitting capacity
}
```

**Example**:
```
Remaining capacity: 2h

Task A: 4h → defer to tomorrow
Task B: 1.5h → fits today, prioritize
```

---

### Level 4: Pattern Opportunities (Efficiency Bonus)

**Boost tasks** that can leverage HIGH confidence patterns:

```javascript
if (taskMatchesHighConfidencePattern(task)) {
  task.priority += 5  // efficiency bonus
  task.patternSuggestion = pattern.name
}
```

**Rationale**: Tasks with applicable patterns complete faster, saving time.

**Example**:
```
Task A: Implement dashboard queries (HIGH priority)
→ Matches "PostgreSQL Indexing" pattern (HIGH confidence)
→ +5 priority bonus (use proven solution)

Task B: Implement dashboard queries (HIGH priority)
→ No matching pattern
→ No bonus
```

Result: Task A ranks higher (faster completion expected).

---

### Level 5: Age (Tie-Breaker)

**Older tasks rank higher** when all else equal:

```javascript
if (taskA.priority === taskB.priority) {
  // Both same priority, check age
  const ageA = Date.now() - new Date(taskA.added)
  const ageB = Date.now() - new Date(taskB.added)

  return ageB - ageA  // older task wins
}
```

**Prevents**: Tasks sitting in backlog forever.

---

## Complete Ranking Algorithm

```javascript
function rankTasks(tasks) {
  const priorityScores = {
    URGENT: 1000,
    HIGH: 100,
    NORMAL: 10,
    LOW: 1
  }

  for (const task of tasks) {
    let score = priorityScores[task.priority]

    // Factor 1: Due date urgency
    if (task.dueDate) {
      const daysUntilDue = (new Date(task.dueDate) - Date.now()) / (1000 * 60 * 60 * 24)

      if (daysUntilDue < 0) {
        score += 500  // overdue
      } else if (daysUntilDue < 1) {
        score += 300  // due today
      } else if (daysUntilDue < 7) {
        score += 100  // due this week
      }
    }

    // Factor 2: Capacity fit
    const remainingCapacity = 7 - hoursAlreadyPlanned
    if (task.estimate <= remainingCapacity && remainingCapacity < 3) {
      score += 50  // fits remaining time
    } else if (task.estimate > remainingCapacity) {
      score -= 100  // won't fit today
    }

    // Factor 3: Pattern opportunities
    if (hasHighConfidencePattern(task)) {
      score += 30  // efficiency bonus
    }

    // Factor 4: Age (small tie-breaker)
    const ageInDays = (Date.now() - new Date(task.added)) / (1000 * 60 * 60 * 24)
    score += Math.min(ageInDays * 0.1, 10)  // max 10 points for age

    task.score = score
  }

  // Sort by score (highest first)
  return tasks.sort((a, b) => b.score - a.score)
}
```

---

## Recommendation Generation

### Step 1: Rank All Tasks

Apply ranking algorithm to get ordered list.

---

### Step 2: Fill Capacity (Top-Down)

**Algorithm**:
```javascript
function generateRecommendations(rankedTasks) {
  const REALISTIC_CAPACITY = 7  // hours
  const recommendations = []
  let hoursPlanned = 0

  for (const task of rankedTasks) {
    if (task.priority === "URGENT") {
      // URGENT tasks always included (even if over-capacity)
      recommendations.push(task)
      hoursPlanned += task.estimate
    } else if (hoursPlanned + task.estimate <= REALISTIC_CAPACITY) {
      // HIGH/NORMAL tasks: only if fits capacity
      recommendations.push(task)
      hoursPlanned += task.estimate
    } else {
      // Defer tasks that don't fit
      task.deferred = true
    }
  }

  return {
    recommendations,
    hoursPlanned,
    deferred: rankedTasks.filter(t => t.deferred)
  }
}
```

---

### Step 3: Add Pattern Suggestions

**Match patterns to recommended tasks**:

```javascript
for (const task of recommendations) {
  const pattern = findBestMatchingPattern(task.description)

  if (pattern && pattern.confidence === "HIGH") {
    task.patternSuggestion = {
      name: pattern.name,
      confidence: pattern.confidence,
      timeSaved: pattern.avgTimeSaved
    }
  }
}
```

**Display**:
```markdown
3. [client-b] Implement dashboard auth (HIGH, 4h)
   💡 APPLY: "PostgreSQL Indexing" pattern (HIGH confidence)
   ⏱️ Estimated time saved: 1.5h
```

---

### Step 4: Generate Deferral Suggestions

**For tasks that don't fit**:

```javascript
const deferredTasks = rankedTasks.filter(t => t.deferred)
const deferredHours = deferredTasks.reduce((sum, t) => sum + t.estimate, 0)

console.log(`\n📅 DEFERRED TO LATER (${deferredHours}h)`)
for (const task of deferredTasks) {
  console.log(`- [${task.project}] ${task.description} (${task.priority}, ${task.estimate}h)`)
}
```

**Example**:
```markdown
📅 DEFERRED TO LATER (5h)
- [internal] Documentation update (NORMAL, 2h)
- [client-c] Research caching (LOW, 3h)
```

---

## Special Cases

### All URGENT Tasks > Capacity

**Scenario**: 3 urgent tasks totaling 10h (over 7h capacity)

**Action**: Include all URGENT, warn about over-capacity

```javascript
if (urgentHours > REALISTIC_CAPACITY) {
  console.warn(`⚠️ CRITICAL OVERLOAD: ${urgentHours}h of URGENT work`)
  console.warn(`Consider:`)
  console.warn(`- Delegate tasks`)
  console.warn(`- Request deadline extensions`)
  console.warn(`- Work extended hours (not sustainable)`)
}
```

---

### No HIGH Priority Tasks

**Scenario**: Only NORMAL/LOW priority tasks available

**Action**: Pick top 3-5 NORMAL tasks by score

```javascript
if (categorized.HIGH.length === 0 && categorized.URGENT.length === 0) {
  // Light day - opportunity for stretch goals
  const stretchTasks = categorized.NORMAL.slice(0, 5)

  console.log(`💡 LIGHT DAY: No urgent work, good time for:`)
  console.log(`- Strategic work (refactoring, optimization)`)
  console.log(`- Learning (explore new patterns)`)
  console.log(`- Clearing backlog (LOW priority items)`)
}
```

---

### Blocked Tasks

**Scenario**: High-priority task blocked by dependency

**Action**: Exclude from recommendations, suggest unblocking

```javascript
if (task.blocked) {
  console.log(`🚫 BLOCKED: ${task.description}`)
  console.log(`   Waiting for: ${task.blockingDependency}`)
  console.log(`   Action: ${task.unblockingAction}`)

  // Don't include in daily plan
  task.excluded = true
}
```

---

## Prioritization Examples

### Example 1: Typical Day

**Input tasks**:
```
1. [client-a] Fix payment bug (URGENT, due today, 2h)
2. [internal] Deploy staging (URGENT, 1h)
3. [client-b] Dashboard auth (HIGH, 4h) + pattern match
4. [client-c] Research caching (NORMAL, 3h)
5. [internal] Update docs (NORMAL, 1h)
```

**Ranking scores**:
```
1. Payment bug: 1000 (URGENT) + 300 (due today) = 1300
2. Deploy staging: 1000 (URGENT) = 1000
3. Dashboard auth: 100 (HIGH) + 30 (pattern) = 130
4. Update docs: 10 (NORMAL) + 50 (fits capacity) = 60
5. Research caching: 10 (NORMAL) = 10
```

**Recommendations** (7h capacity):
```
1. Payment bug (2h) → Total: 2h
2. Deploy staging (1h) → Total: 3h
3. Dashboard auth (4h) → Total: 7h ✅ at capacity

Deferred:
4. Update docs (1h)
5. Research caching (3h)
```

---

### Example 2: Over-Capacity with URGENT

**Input tasks**:
```
1. [client-a] Fix production bug (URGENT, 3h)
2. [client-a] Deploy hotfix (URGENT, 1h)
3. [client-b] Critical client meeting prep (URGENT, 2h)
4. [client-b] Dashboard feature (HIGH, 4h)
```

**Total URGENT**: 6h (fits capacity)

**Recommendations**:
```
1. Fix production bug (3h)
2. Deploy hotfix (1h)
3. Client meeting prep (2h)
→ Total: 6h

Deferred:
4. Dashboard feature (4h) - defer to tomorrow
```

---

## Success Metrics

**Target accuracy**: 95%+ prioritization correct

**Validation**:
- Ask user at end of day: "Did priorities match actual needs?"
- Track: % of recommended tasks actually completed
- Adjust algorithm weights based on feedback

**Performance**: < 3 seconds to rank all tasks
