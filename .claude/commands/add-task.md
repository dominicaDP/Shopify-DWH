---
name: add-task
description: Add a task to a project with priority, due date, and time estimate
allowed-tools: Read, Edit, Write, Grep
---

# Add Task Command

Usage: `/add-task [project-name] [task-description] [options]`

Add a task to any project with optional priority, due date, and time estimate.

## Execution Steps

### Step 1: Parse Command Arguments

**Extract from user input:**
- `project_name`: First argument or ask if missing
- `task_description`: Task text
- `priority`: high | medium | low (default: medium)
- `due_date`: YYYY-MM-DD format
- `estimated_time`: Xh or Xm (e.g., "2h", "30m")
- `quick_win`: true/false (< 30 min tasks)
- `blocked`: true/false (waiting on external)

**Example:**
```
/add-task client-a "Deploy OAuth hotfix" priority=high due=2025-01-11 estimated=2h
```

### Step 2: Validate Project Exists

**Tool: Read**
```bash
Read("projects/INDEX.md")
```

**Check:**
- If project-name NOT in INDEX.md → Error + list available projects
- If project exists → Continue

**Error Output (if not found):**
```
❌ Project 'client-a' not found.

Available projects:
1. client-a (Client A - E-commerce)
2. client-b (Client B - SaaS)
3. internal-product (Internal Tool)
4. content-2025-q1 (Content Calendar)

Use: /add-task <project-name> "<task>"
```

### Step 3: Read Current Tasks

**Tool: Read**
```bash
Read("projects/<project-name>/tasks.md")
```

### Step 4: Determine Section Based on Priority

**Logic:**
```
IF priority = "high" AND due_date = today:
  section = "## Urgent"

ELSE IF priority = "high":
  section = "## High Priority"

ELSE IF priority = "medium" OR no priority:
  section = "## Normal"

ELSE IF priority = "low":
  section = "## Low Priority"

IF blocked = true:
  section = "## Blocked"
```

### Step 5: Format Task Entry

**Create task markdown:**
```markdown
- [ ] <task-description>
  Priority: <HIGH/MEDIUM/LOW>
  Due: <date> (if specified)
  Estimated: <time> (if specified)
  Added: <TODAY>
  Quick win: <yes/no> (if quick_win=true)
  Blocked: <reason> (if blocked=true)
```

### Step 6: Add Task to File

**Tool: Edit**
```bash
# Find the appropriate section and append task

Edit(
  file_path="projects/<project-name>/tasks.md",
  old_string="## <Section Name>\n",
  new_string="## <Section Name>\n<formatted-task>\n"
)
```

**If section doesn't exist, create it:**
```bash
Write(
  file_path="projects/<project-name>/tasks.md",
  content="... add new section with task ..."
)
```

### Step 7: Update Project Index

**Tool: Read**
```bash
Read("projects/INDEX.md")
```

**Tool: Edit**
```bash
# Update "Last activity" date for this project

Edit(
  file_path="projects/INDEX.md",
  old_string="- <project-name> (...) - Last activity: <old-date>",
  new_string="- <project-name> (...) - Last activity: <TODAY>"
)
```

### Step 8: Count Open Tasks

**Tool: Grep**
```bash
# Count unchecked tasks in project
Grep(
  pattern="^- \\[ \\]",
  path="projects/<project-name>/tasks.md",
  output_mode="count"
)
```

### Step 9: Output Confirmation

**Success Output:**
```
✅ Task added to <project-name>:
- [ ] <task-description>
  Priority: <PRIORITY>
  Due: <date> (<X> days away) ⚠️ (if urgent)
  Estimated: <time>
  Added: <TODAY>

⚠️  This is URGENT (due in <X> days) (if applicable)
📊 Open tasks in <project-name>: <N> (<N> urgent)

💡 Run /overview to see all urgent tasks
```

**Example outputs:**

**Simple task:**
```
✅ Task added to client-a:
- [ ] Update documentation
  Priority: MEDIUM
  Added: 2025-01-09

📊 Open tasks in client-a: 4
```

**Urgent task:**
```
✅ Task added to client-a:
- [ ] Deploy OAuth hotfix
  Priority: HIGH
  Due: 2025-01-11 (2 days away) ⚠️
  Estimated: 2 hours
  Added: 2025-01-09

⚠️  This is URGENT (due in 2 days)
📊 Open tasks in client-a: 5 (2 urgent)

💡 Run /overview to see all urgent tasks
```

**Quick win:**
```
✅ Task added to internal-product:
- [ ] Fix typo in README
  Priority: MEDIUM
  Quick win: Yes (< 30 min)
  Estimated: 5 minutes
  Added: 2025-01-09

✨ This is a quick win - perfect for in-between time!
📊 Quick wins available: 3
```

**Blocked task:**
```
✅ Task added to client-b (BLOCKED):
- [ ] API integration
  Priority: MEDIUM
  Blocked: Waiting on client to provide API keys
  Added: 2025-01-09

⏸️  This task is blocked
💡 Add note about what you're waiting for
```

## Advanced Usage

### Add Multiple Tasks (Batch)

**Input:**
```
/add-task client-a "Task 1" "Task 2" "Task 3"
```

**Action:** Loop through tasks, create each one

**Tool: Edit** (called 3 times)
```bash
Edit(...) # Task 1
Edit(...) # Task 2
Edit(...) # Task 3
```

### Add Task to Current Project

**If user is already in a project context:**
```
/add-task "New task"
```

**Tool: Read**
```bash
# Check if .current-project file exists
Read(".current-project")
```

**If exists:** Use that project name
**If not:** Ask for project name

### Template Tasks (Future)

**For recurring workflows:**
```
/add-task client-a "Weekly status report" recurrence=weekly due=every-friday
```

## Integration with Other Commands

### With `/overview`
Tasks added via `/add-task` automatically appear in `/overview`:
- Urgent tasks → URGENT section
- Quick wins → QUICK WINS section

### With `/switch`
When switched to a project, `/add-task` defaults to that project

### With `/learn`
When task is completed, triggers learning extraction prompt

## File Structure Requirements

**Expected files:**
```
projects/
├── INDEX.md                 # List of all projects
├── <project-name>/
│   ├── tasks.md            # Tasks file (this command edits)
│   ├── notes.md            # Project notes
│   └── context.md          # Project context
```

**tasks.md format:**
```markdown
# <Project Name> Tasks

## Urgent
- [ ] Task 1...

## High Priority
- [ ] Task 2...

## Normal
- [ ] Task 3...

## Low Priority
- [ ] Task 4...

## Blocked
- [ ] Task 5...

## Completed
- [x] Task 6 (completed: 2025-01-08)
```

## Task Completion (Future Command)

**Mark task complete:**
```bash
# Future: /complete-task command
/complete-task client-a "Deploy OAuth hotfix"
```

**Action:**
1. Find task in tasks.md
2. Change `- [ ]` to `- [x]`
3. Move to "## Completed" section
4. Add completion date
5. Trigger `/learn` prompt

## Success Metrics

**Goal:** Save time on task management

**Metrics:**
- Time to add task: < 30 seconds (vs 2-3 min manual)
- Fibery sync time: 0 min (vs 5 min manual copy)
- Context switching: Minimal (stay in Claude Code)

**Time saved:** ~1 hour/week vs manual Fibery + notes + calendar updates

## Priority Guidelines

**HIGH priority:**
- Blocking other work
- Client deadline < 3 days
- Critical bugs
- Urgent client requests

**MEDIUM priority:**
- Important but not urgent
- Deadline > 3 days
- Regular feature work
- Planned improvements

**LOW priority:**
- Nice-to-have features
- Tech debt (not blocking)
- Future ideas
- Documentation improvements

## Due Date Strategy

**Set due dates for:**
- Client deliverables
- External deadlines
- Time-sensitive work

**Don't set due dates for:**
- Ongoing tasks
- Flexible improvements
- Research/learning

## Time Estimates

**Be realistic:**
- Include testing time
- Include code review time
- Add 20% buffer for unknowns

**Use estimates for:**
- Daily planning (/overview uses estimates)
- Capacity checking (am I overloaded?)
- Measuring improvement (estimates vs actuals)

## Notes for the user

**When to add tasks:**
- New work identified
- Client requests
- Ideas that become actionable
- Follow-ups from meetings

**Granularity:**
- Too small: "Fix typo" (unless quick win)
- Just right: "Implement OAuth integration"
- Too big: "Build entire feature" (break into smaller tasks)

**Fibery sync (Future Week 2):**
- After Fibery integration built: `/add-task` will auto-sync
- Bi-directional updates
- Single source of truth
