# Daily Overview - Time Estimation

Estimation rules and capacity management.

## Default Time Estimates

When tasks don't specify `Est: Xh`, use these defaults based on task type:

### Bug Fixes
**Default: 2 hours**

**Detection keywords**: fix, bug, issue, error, broken

**Examples**:
- "Fix payment processing bug" → 2h
- "Resolve login error" → 2h
- "Debug API timeout issue" → 2h

**Rationale**: Bugs require investigation, fix, testing. Average 2h covers most cases.

---

### Feature Development
**Default: 4 hours**

**Detection keywords**: add, implement, create, build, develop, feature

**Examples**:
- "Add export functionality" → 4h
- "Implement user authentication" → 4h
- "Create dashboard widget" → 4h

**Rationale**: Features involve design, implementation, testing, documentation.

---

### Deployments
**Default: 1 hour**

**Detection keywords**: deploy, release, ship, push to production

**Examples**:
- "Deploy staging environment" → 1h
- "Release v2.0 to production" → 1h
- "Ship hotfix to prod" → 1h

**Rationale**: Deployment includes prep, execution, monitoring. Well-practiced process.

---

### Documentation
**Default: 1 hour**

**Detection keywords**: document, docs, readme, write, update docs

**Examples**:
- "Update API documentation" → 1h
- "Write README for project" → 1h
- "Document deployment process" → 1h

**Rationale**: Documentation writing typically 1-2h for most tasks.

---

### Meetings
**Default: As scheduled**

**Detection keywords**: meeting, call, sync, standup, review

**Examples**:
- "Client discovery call at 2pm" → Check calendar for duration
- "Team standup" → 30m
- "Sprint planning" → 2h

**Rationale**: Use actual scheduled duration from calendar.

---

### Refactoring
**Default: 3 hours**

**Detection keywords**: refactor, cleanup, improve, optimize, restructure

**Examples**:
- "Refactor authentication module" → 3h
- "Optimize database queries" → 3h
- "Cleanup legacy code" → 3h

**Rationale**: Refactoring requires understanding, careful changes, testing.

---

### Research / Investigation
**Default: 2 hours**

**Detection keywords**: research, investigate, explore, evaluate, assess

**Examples**:
- "Research caching strategies" → 2h
- "Evaluate new framework" → 2h
- "Investigate performance issues" → 2h

**Rationale**: Time-boxed research prevents endless rabbit holes.

---

## Capacity Management

### Realistic Daily Capacity

**Standard workday**: 6-7 focused hours

**Why not 8 hours?**
- Meetings, emails, Slack interruptions: 1-2h
- Context switching overhead: 30-60m
- Breaks, lunch: 1h
- Realistic estimate accounts for real workday

---

### Capacity Zones

#### ✅ Good Capacity (4-7 hours)
**Status**: Healthy workload

**Action**: No adjustments needed

**Example**:
```
Total planned: 6.5 hours
Available: 6-7 hours
✅ GOOD CAPACITY
```

---

#### ⚠️ Over-Capacity (> 8 hours)
**Status**: Unrealistic plan

**Action**: Defer NORMAL and LOW priority tasks

**Algorithm**:
```javascript
if (totalPlanned > 8) {
  const hoursToDefer = totalPlanned - 7

  // Defer NORMAL tasks first
  let deferred = deferTasksFromCategory("NORMAL", hoursToDefer)

  // If still over, defer LOW priority
  if (deferred < hoursToDefer) {
    deferred += deferTasksFromCategory("LOW", hoursToDefer - deferred)
  }

  console.warn(`⚠️ OVER-CAPACITY: Defer ${hoursToDefer}h of work`)
}
```

**Example**:
```
Total planned: 11 hours
Available: 6-7 hours
⚠️ OVER-CAPACITY: Defer 4-5 hours of NORMAL priority work
```

---

#### 📉 Under-Capacity (< 4 hours)
**Status**: Light day (opportunity for stretch goals)

**Action**: Add NORMAL or LOW priority stretch tasks

**Algorithm**:
```javascript
if (totalPlanned < 4) {
  const availableHours = 6 - totalPlanned

  // Suggest stretch tasks from NORMAL backlog
  const stretchTasks = selectTasksUpTo(normalTasks, availableHours)

  console.info(`💡 STRETCH: ${availableHours}h available for additional work`)
  console.info(`Suggested: ${stretchTasks.map(t => t.name).join(', ')}`)
}
```

**Example**:
```
Total planned: 3 hours
Available: 6-7 hours
💡 STRETCH: 3-4h available for additional work
Suggested: Refactor auth module (3h), Update docs (1h)
```

---

## Time Estimation Accuracy

### Tracking Accuracy

**Method**: Compare estimated vs actual time

```javascript
// After task completion
const accuracy = (estimatedHours / actualHours) * 100

if (accuracy >= 80 && accuracy <= 120) {
  // Within 20% = good estimate
  console.log("✅ Accurate estimate")
} else if (accuracy < 80) {
  console.log("⚠️ Over-estimated")
} else {
  console.log("⚠️ Under-estimated")
}
```

**Target**: 80-120% accuracy (within 20% of actual)

---

### Improving Estimates

**Over-estimating (consistently < 80%)**:
- Tasks completing faster than planned
- Action: Reduce defaults by 20-30%

**Under-estimating (consistently > 120%)**:
- Tasks taking longer than planned
- Action: Increase defaults by 20-30%
- Check for hidden complexity (legacy code, tech debt)

---

## Special Cases

### Blocked Tasks
**Estimate**: 0 hours (don't plan until unblocked)

**Detection**: Task description includes "blocked", "waiting for"

**Example**: "Implement API (blocked on client approval)" → 0h planned

---

### Recurring Tasks
**Estimate**: Use historical average

**Example**:
- "Weekly standup" → 30m (based on past weeks)
- "Monthly reports" → 2h (average of last 3 months)

---

### Uncertainty Factor

**High uncertainty** (new tech, unclear requirements):
- **Multiply estimate by 1.5x**

**Examples**:
- "Explore new framework" → 2h base × 1.5 = 3h
- "Research unfamiliar API" → 2h base × 1.5 = 3h

**Low uncertainty** (done before, clear scope):
- **Use standard estimate**

**Examples**:
- "Add similar feature as last time" → 4h (standard)
- "Deploy using established process" → 1h (standard)

---

## Daily Capacity Planning Formula

```javascript
function planDay(tasks) {
  const REALISTIC_CAPACITY = 7  // hours

  // Step 1: Calculate total estimated time
  const totalEstimated = tasks.reduce((sum, t) => sum + t.estimate, 0)

  // Step 2: Prioritize (URGENT → HIGH → NORMAL → LOW)
  const prioritized = prioritizeTasks(tasks)

  // Step 3: Fill capacity with highest priority tasks
  let planned = []
  let hoursPlanned = 0

  for (const task of prioritized) {
    if (hoursPlanned + task.estimate <= REALISTIC_CAPACITY) {
      planned.push(task)
      hoursPlanned += task.estimate
    } else {
      task.deferred = true
    }
  }

  // Step 4: Check capacity zone
  if (hoursPlanned > 8) {
    return { status: "OVER-CAPACITY", planned, hoursPlanned }
  } else if (hoursPlanned < 4) {
    return { status: "UNDER-CAPACITY", planned, hoursPlanned }
  } else {
    return { status: "GOOD", planned, hoursPlanned }
  }
}
```

---

## Integration with Dashboard

**Display format**:
```markdown
📊 CAPACITY CHECK
- Total planned: 7h
- Available: 6-7 hours (realistic workday)
- ✅ GOOD CAPACITY

Tasks in plan:
1. [client-a] Fix bug (URGENT, 2h)
2. [internal] Deploy staging (URGENT, 1h)
3. [client-b] Dashboard auth (HIGH, 4h)

Deferred to tomorrow/next week:
4. [internal] Documentation (NORMAL, 2h)
5. [client-c] Research caching (LOW, 3h)
```

**Visualization**:
```
[████████████░░░░░░░░░░] 7h / 7h capacity used
```
