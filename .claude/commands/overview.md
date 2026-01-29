---
name: overview
description: Daily overview of all tasks, deadlines, and priorities across all projects
allowed-tools: Read, Grep, Bash
---

# Daily Overview Command

Show the user a comprehensive overview of all work across all projects.

## Execution Steps

### Step 1: Get List of Active Projects

**Tool: Read**
```bash
Read("projects/INDEX.md")
```

**Parse output:**
- Extract all project names
- Filter only active projects (not archived)

### Step 2: Read Tasks from Each Project

**Tool: Read** (loop for each project)
```bash
For each project in active_projects:
  Read("projects/<project-name>/tasks.md")
```

**Collect:**
- All unchecked tasks: `- [ ] ...`
- Task metadata: priority, due_date, estimated_time, quick_win, blocked

### Step 3: Categorize Tasks

**URGENT (Due Today or Overdue):**
```bash
For each task:
  IF task.due_date <= TODAY:
    add to urgent_tasks[]
  IF task.priority = "CRITICAL":
    add to urgent_tasks[]
```

**IMPORTANT (Due This Week):**
```bash
For each task:
  IF task.due_date within 7 days AND NOT urgent:
    add to important_tasks[]
  IF task.priority = "HIGH" AND no due_date:
    add to important_tasks[]
```

**BLOCKED (Waiting on Others):**
```bash
For each task:
  IF task.blocked = true:
    add to blocked_tasks[]
  IF task.status = "blocked":
    add to blocked_tasks[]
```

**QUICK WINS (< 30 minutes):**
```bash
For each task:
  IF task.quick_win = true:
    add to quick_wins[]
  IF task.estimated_time <= 30:
    add to quick_wins[]
```

### Step 4: Calculate Time Estimates

**Tool: Grep** (to extract time estimates)
```bash
# For each task, extract estimated_time field
Grep(
  pattern="Estimated: (\\d+)",
  path="projects/*/tasks.md",
  output_mode="content"
)
```

**Calculate:**
```javascript
total_time = sum(all_tasks.estimated_time)
today_time = sum(urgent_tasks.estimated_time) + sum(quick_wins[0:4].estimated_time)
week_time = sum(important_tasks.estimated_time) + today_time
```

### Step 5: Generate Focus Suggestion

**Logic:**
```javascript
focus_suggestion = ""

IF urgent_tasks.length > 0:
  focus_suggestion += "1. Morning: Urgent items (${urgent_time} hours)\n"

IF quick_wins.length > 3:
  focus_suggestion += "2. Afternoon: Quick wins (knock out 4-5 small items)\n"

IF important_tasks.length > 0:
  focus_suggestion += "3. Tomorrow: Start with ${important_tasks[0].name}\n"
```

### Step 6: Format Output

**Output Structure:**
```markdown
📅 <Day of Week>, <Date>

## ⚠️  URGENT (<count>)

<For each urgent task:>
**<Project>** → <Task description> (due <time>)
  Priority: <PRIORITY> | Est: <time>
  Context: <additional context if available>

## 📌 IMPORTANT THIS WEEK (<count>)

<For each important task:>
**<Project>** → <Task description> (due <date>)
  Priority: <PRIORITY> | Est: <time>

## ⏸️  BLOCKED (<count>)

<For each blocked task:>
**<Project>** → <Task description> (waiting on <reason>)
  Blocked since: <date>
  Next action: <action>

## ✨ QUICK WINS (<30 min) (<count>)

<For each quick win:>
**<Project>** → <Task description> (<time>)

---
**Total:** <count> tasks across <count> projects
**Est. time today:** <hours> hours
**Est. time this week:** <hours> hours

💡 **Focus suggestion:**
<generated_focus_suggestion>
```

### Step 7: Check for Overload

**Warning logic:**
```javascript
IF today_time > 8:
  warn("⚠️  You have ${today_time} hours of work estimated for today. Consider rescheduling some tasks.")

IF week_time > 40:
  warn("⚠️  You have ${week_time} hours estimated this week. You may be overcommitted.")
```

## Example Execution

**Input:**
```
/overview
```

**Tool calls sequence:**
```bash
1. Read("projects/INDEX.md")
2. Read("projects/client-a/tasks.md")
3. Read("projects/client-b/tasks.md")
4. Read("projects/internal-product/tasks.md")
5. Read("projects/content-2025-q1/tasks.md")
6. Grep(pattern="Estimated:", path="projects/*/tasks.md")
7. Bash(command="date '+%A, %B %d, %Y'")  # Get today's date
```

**Output:**
```
📅 Thursday, January 9, 2025

## ⚠️  URGENT (3)

**Client A** → Deploy OAuth hotfix (due today 5pm)
  Priority: CRITICAL | Est: 2 hours
  Context: Blocks QA testing

**Blog** → Final review before publish (due today)
  Priority: HIGH | Est: 30 min
  Context: Scheduled for tomorrow morning

**Pipedrive** → Follow up with prospect (overdue 1 day)
  Priority: MEDIUM | Est: 15 min
  Context: Lead cooling off

## 📌 IMPORTANT THIS WEEK (5)

**Client B** → Feature spec review (due Jan 11)
  Priority: HIGH | Est: 3 hours

**Content** → Record LinkedIn video (due Jan 12)
  Priority: MEDIUM | Est: 1 hour

**Client A** → Update documentation (due Jan 12)
  Priority: MEDIUM | Est: 2 hours

**Internal** → Refactor auth module (due Jan 13)
  Priority: MEDIUM | Est: 4 hours

**Learning** → Complete React course module (due Jan 14)
  Priority: LOW | Est: 2 hours

## ⏸️  BLOCKED (2)

**Client C** → API integration (waiting on client to provide keys)
  Blocked since: Jan 7
  Next action: Send reminder email

**Support** → Ticket #45 (escalated to dev team)
  Blocked since: Jan 8
  Next action: Check with team tomorrow

## ✨ QUICK WINS (<30 min) (4)

**Client A** → Update README with new setup steps (15 min)
**Internal** → Reply to prospect inquiry email (10 min)
**Content** → Schedule next week's LinkedIn posts (20 min)
**Client B** → Fix typo in docs (5 min)

---
**Total:** 14 tasks across 6 projects
**Est. time today:** 4.5 hours
**Est. time this week:** 16 hours

💡 **Focus suggestion:**
1. Morning: Urgent items (3 hours) - Deploy hotfix, publish blog, follow up
2. Afternoon: Quick wins (1 hour) - Knock out 4 small items
3. Tomorrow: Important items - Start with Client B spec review
```

## Advanced Features

### Filter by Project

**Usage:**
```
/overview client-a
```

**Action:** Only show tasks from client-a project

### Filter by Priority

**Usage:**
```
/overview priority=high
```

**Action:** Only show high priority tasks

### Time-Boxed View

**Usage:**
```
/overview today
```

**Action:** Only show tasks due today

## Integration with Other Commands

### With `/add-task`
- New tasks automatically appear in next `/overview` run
- Urgent tasks trigger warning

### With `/switch`
- After switching projects, `/overview` shows context for that project
- Can run `/overview` to see if switching makes sense

### With `/learn`
- Completed tasks from overview trigger learning extraction

## Success Metrics

**Goal:** Save the user 30 min/day on manual planning/review

**Metrics:**
- Instant visibility across all projects (vs manual checking)
- Smart prioritization (urgent → important → quick wins)
- Time estimates (know if day is overloaded)
- Focus suggestions (reduce decision fatigue)

**Time saved:** 30 min/day vs manually reviewing Fibery + calendar + notes

## Fibery Integration (Future)

**When `integrations/fibery/` is built:**
```javascript
// Pull tasks from Fibery API instead of local files
const tasks = await fibery.getTasks({
  status: 'open',
  assigned_to: 'the user'
})
```

**Benefits:**
- Real-time sync
- No manual file updates
- Single source of truth

## Required Files

**Directory structure:**
```
projects/
├── INDEX.md                    # List of projects
├── client-a/
│   └── tasks.md               # Tasks with metadata
├── client-b/
│   └── tasks.md
└── internal-product/
    └── tasks.md
```

**tasks.md format:**
```markdown
# Project Tasks

## Urgent
- [ ] Task 1
  Priority: CRITICAL
  Due: 2025-01-09
  Estimated: 2h

## Normal
- [ ] Task 2
  Priority: MEDIUM
  Estimated: 1h
```

## Edge Cases

### No Tasks
**Output:**
```
📅 Thursday, January 9, 2025

✅ No open tasks!

🎉 Great job staying on top of your work.

💡 Consider:
- Planning next week's priorities
- Reviewing completed tasks with /grow
- Capturing ideas with /idea
```

### Only Blocked Tasks
**Output:**
```
⏸️  All current tasks are BLOCKED.

**What you can do:**
- Follow up on blockers
- Start quick wins
- Plan ahead for next week
```

### Overloaded Day
**Output:**
```
⚠️  WARNING: 12 hours estimated for today
This is more than a typical workday.

**Suggestions:**
1. Reschedule non-urgent tasks
2. Delegate if possible
3. Adjust time estimates (might be overestimated)
```

## Notes for the user

**When to run:**
- **Every morning** to plan your day
- After `/add-task` to see updated priorities
- Mid-day to check progress
- Before calling it a day

**How to use the output:**
- Start with URGENT (knock these out first)
- Fill gaps with QUICK WINS (high ROI)
- Plan tomorrow using IMPORTANT THIS WEEK
- Follow up on BLOCKED items

**Focus suggestion:**
- Use it to avoid analysis paralysis
- Trust the prioritization algorithm
- Adjust as context changes during the day

**Time saved:** 30 min/day vs manually reviewing all project sources
