# Daily Overview - Detailed Workflow

Full 12-step dashboard generation with tool calls.

## Step 1: Get Current Date + Day of Week

**Tool: Bash**
```bash
Bash(command="date '+%Y-%m-%d (%A)'")
```

**Output**: `2025-01-09 (Friday)`

**Purpose**:
- Weekend awareness (don't over-plan on Friday)
- Context for time-sensitive tasks
- Date stamp for dashboard

---

## Step 2: Read All Active Projects

**Tool: Read**
```bash
Read("projects/INDEX.md")
```

**Parse**: Extract project names from active section

```javascript
// Example INDEX.md content:
// ## Active Projects
// - client-a: E-commerce platform
// - client-b: Dashboard analytics
// - internal: Second brain development

const activeProjects = ["client-a", "client-b", "internal"]
```

---

## Step 3: Read All Project Tasks

**Tool: Read** (for each project)
```bash
Read("projects/client-a/tasks.md")
Read("projects/client-b/tasks.md")
Read("projects/internal/tasks.md")
```

**Parse open tasks**:
```javascript
// Look for: - [ ] Task description
// Ignore: - [x] Completed tasks
```

---

## Step 4: Categorize by Priority

**Parse each task** for priority indicators:

```javascript
const categorized = {
  URGENT: [],
  HIGH: [],
  NORMAL: [],
  LOW: []
}

// Check task metadata lines:
// Priority: URGENT | Added: 2025-01-09 | Est: 2h
for (const task of allTasks) {
  const priorityLine = task.split('\n')[1]  // Metadata on 2nd line
  const priority = priorityLine.match(/Priority: (\w+)/)[1]

  categorized[priority].push({
    project: task.project,
    description: task.description,
    estimate: task.estimate || "not specified",
    added: task.added
  })
}
```

---

## Step 5: Calculate Time Estimates

**Sum estimated time** for all open tasks:

```javascript
let totalHours = 0

for (const task of allTasks) {
  // Parse estimate: "Est: 2h" or "Est: 30m"
  const estMatch = task.match(/Est: (\d+)([hm])/)

  if (estMatch) {
    const value = parseInt(estMatch[1])
    const unit = estMatch[2]

    if (unit === 'h') {
      totalHours += value
    } else if (unit === 'm') {
      totalHours += value / 60
    }
  } else {
    // Default estimates (see time-estimation.md)
    totalHours += getDefaultEstimate(task.description)
  }
}

const capacityCheck = totalHours > 8 ? "OVER-CAPACITY" :
                      totalHours < 4 ? "UNDER-CAPACITY" : "GOOD"
```

---

## Step 6: Identify Urgent Tasks

**Keyword detection** for urgency:

```javascript
const urgentKeywords = ["urgent", "critical", "today", "asap", "blocking", "production"]
const urgentTasks = []

for (const task of categorized.URGENT) {
  urgentTasks.push(task)
}

// Also check for past due dates
for (const task of allTasks) {
  if (task.dueDate && new Date(task.dueDate) < new Date()) {
    urgentTasks.push(task)
  }
}
```

---

## Step 7: Suggest High-Priority Tasks

**Select top 3-5 tasks** to focus on today:

```javascript
const suggestedFocus = []

// Priority 1: All URGENT tasks
suggestedFocus.push(...categorized.URGENT)

// Priority 2: HIGH priority tasks (limit to 3-5 total)
const highTasks = categorized.HIGH.slice(0, 5 - suggestedFocus.length)
suggestedFocus.push(...highTasks)

// Calculate total time for suggested tasks
const suggestedHours = suggestedFocus.reduce((sum, task) => sum + task.estimate, 0)

if (suggestedHours > 7) {
  // Over realistic capacity - mark for deferral
  const toDefer = suggestedHours - 7
  suggestedFocus.deferralWarning = `⚠️ ${toDefer}h over capacity - defer NORMAL tasks`
}
```

---

## Step 8: Load Relevant Patterns

**Tool: Grep** + **Read**

```bash
# Find HIGH confidence patterns
Grep(
  pattern="Level: HIGH",
  path="memory/semantic/patterns/",
  output_mode="files_with_matches"
)

# Read pattern files
Read("memory/semantic/patterns/dev-patterns.md")
Read("memory/semantic/patterns/client-patterns.md")
```

**Match patterns to tasks**:

```javascript
// Example: Task mentions "database" or "queries"
// → Suggest "PostgreSQL Indexing" pattern

const patternSuggestions = []

for (const pattern of highConfidencePatterns) {
  for (const task of suggestedFocus) {
    if (taskMatchesPattern(task.description, pattern.keywords)) {
      patternSuggestions.push({
        pattern: pattern.name,
        confidence: pattern.level,
        relevantTo: task.description
      })
    }
  }
}
```

---

## Step 9: Check Recent Brain Growth

**Tool: Read**
```bash
Read("memory/episodic/growth-log.md")
```

**Parse this week's entries**:

```javascript
// Find entries from current week
const thisWeek = entries.filter(e => isThisWeek(e.date))

const weeklyStats = {
  patternsReinforced: thisWeek.filter(e => e.type === "reinforcement").length,
  newPatterns: thisWeek.filter(e => e.type === "new_pattern").length,
  timeSaved: thisWeek.reduce((sum, e) => sum + (e.timeSaved || 0), 0),
  highConfidenceAchieved: thisWeek.filter(e => e.confidence === "HIGH").length
}
```

---

## Step 10: Generate Recommendations

**Algorithm**:

1. **Start with URGENT** (must do today)
2. **Add HIGH tasks** until reaching 6-7h capacity
3. **Match patterns** to tasks for efficiency gains
4. **Flag deferral** if over-capacity

```javascript
const recommendations = []
let plannedHours = 0
const REALISTIC_CAPACITY = 7

// Add all URGENT (non-negotiable)
for (const task of categorized.URGENT) {
  recommendations.push({
    ...task,
    reason: "URGENT - due today",
    applyPattern: findMatchingPattern(task)
  })
  plannedHours += task.estimate
}

// Add HIGH until capacity reached
for (const task of categorized.HIGH) {
  if (plannedHours + task.estimate <= REALISTIC_CAPACITY) {
    recommendations.push({
      ...task,
      reason: "HIGH priority, fits capacity",
      applyPattern: findMatchingPattern(task)
    })
    plannedHours += task.estimate
  } else {
    recommendations.deferred = recommendations.deferred || []
    recommendations.deferred.push(task)
  }
}
```

---

## Step 11: Format Dashboard

**Build visual sections**:

```markdown
📅 Daily Overview - {date}

🔥 URGENT (Due Today)
{urgentTasks formatted}

⭐ HIGH PRIORITY (Important)
{highTasks formatted}

💡 SUGGESTED PATTERNS TO APPLY TODAY
{patternSuggestions formatted}

📊 CAPACITY CHECK
- Total planned: {totalHours} hours
- Available: 6-7 hours (realistic workday)
- {capacityWarning if applicable}

🧠 THIS WEEK'S BRAIN GROWTH
{weeklyStats formatted}

🎯 RECOMMENDED FOCUS TODAY
{recommendations formatted with time estimates}
```

---

## Step 12: Display Dashboard

**Output formatted markdown** with clear sections and visual indicators.

**Key formatting rules**:
- ✅ Use emojis for visual scanning
- ✅ Show time estimates for capacity planning
- ✅ Highlight pattern application opportunities
- ✅ Include deferral suggestions if over-capacity
- ✅ Link patterns to tasks explicitly

**Example output**:
```
🎯 RECOMMENDED FOCUS TODAY
1. [client-a] Fix production payment bug (URGENT, 2h)
2. [internal] Deploy staging environment (URGENT, 1h)
3. [client-b] Implement dashboard auth (HIGH, 4h)
   💡 APPLY: "PostgreSQL Indexing" pattern (HIGH confidence)

Total: 7h (realistic capacity ✅)
Deferred: 4h of NORMAL priority work to next week
```

---

## Performance Targets

- **Total execution**: < 10 seconds
- **File reads**: ~10-15 files (projects + patterns)
- **Accuracy**: 95%+ correct prioritization
- **User action**: Zero input required (fully automated)
