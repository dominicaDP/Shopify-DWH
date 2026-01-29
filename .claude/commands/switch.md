---
name: switch
description: Switch to a different project, loading its context and showing recent activity
allowed-tools: Read, Write, Grep, Bash
---

# Project Switch Command

Usage: `/switch [project-name]`

Switch the user's active project context, minimizing context-switching overhead.

## Execution Steps

### Step 1: Validate Project Exists

**Tool: Bash** (check if directory exists)
```bash
Bash(command="test -d 'projects/<project-name>' && echo 'exists' || echo 'not_exists'")
```

**If not exists:**
```bash
# List available projects
Read("projects/INDEX.md")
```

**Output error:**
```markdown
❌ Project '<project-name>' not found.

**Available projects:**
- client-a (Client A - E-commerce)
- client-b (Client B - Analytics)
- internal-product (SaaS Product)

**Did you mean:** <closest_match>?
```
**Exit if not found**

### Step 2: Get Current Date/Time

**Tool: Bash**
```bash
Bash(command="date '+%Y-%m-%d %H:%M:%S'")
```

**Store as:** `currentTimestamp`

### Step 3: Save Current Project Context (if any)

**Tool: Read** (check current project)
```bash
Read("projects/CURRENT")
```

**If file exists:**
```javascript
const currentProject = fileContent.trim()
```

**Tool: Read** (get current project context)
```bash
Read("projects/<currentProject>/context.md")
```

**Tool: Write** (update last worked timestamp)
```bash
Write(
  file_path="projects/<currentProject>/context.md",
  content=updatedContent  // Update "Last Worked" section with currentTimestamp
)
```

### Step 4: Switch to New Project

**Tool: Write** (update CURRENT file)
```bash
Write(
  file_path="projects/CURRENT",
  content="<project-name>"
)
```

### Step 5: Load New Project Context

**Tool: Read** (load context)
```bash
Read("projects/<project-name>/context.md")
```

**Extract:**
- Project type
- Tech stack
- Last worked date
- Key context
- Contacts

**Tool: Read** (load tasks)
```bash
Read("projects/<project-name>/tasks.md")
```

**Parse tasks:**
```javascript
// Extract urgent, high priority, and normal tasks
const urgentTasks = grep("## Urgent" section)
const highPriorityTasks = grep("## High Priority" section)
const normalTasks = grep("## Normal" section)
const completedTasks = grep("## Completed" section, limit=3) // Last 3
```

**Tool: Read** (load patterns if exists)
```bash
Read("projects/<project-name>/patterns.md")
```

### Step 6: Load Relevant Semantic Memory

**Check project type from context:**
```javascript
IF projectType === "client work":
  // Load client-specific memory
```

**Tool: Grep** (find client memory)
```bash
Grep(
  pattern="<client-name>",
  path="memory/semantic/clients/",
  output_mode="files_with_matches"
)
```

**Tool: Read** (if client memory found)
```bash
Read("memory/semantic/clients/<client-name>.md")
```

**Extract client preferences, patterns**

### Step 7: Find Past Experiences in This Project

**Tool: Grep** (search episodic memory)
```bash
Grep(
  pattern="<project-name>",
  path="memory/episodic/",
  output_mode="files_with_matches"
)
```

**Tool: Read** (read recent experiences)
```bash
// Read last 3 experiences related to this project
FOR EACH match (limit 3):
  Read("<experience_file>")
  Extract: date, pattern applied, time saved
```

### Step 8: Calculate Days Since Last Worked

**Tool: Bash**
```bash
Bash(command="date '+%Y-%m-%d'")  // Get today's date
```

**Calculate:**
```javascript
const daysSinceLastWorked = calculateDaysDifference(today, lastWorkedDate)
```

### Step 9: Identify Suggested Next Step

**Priority logic:**
```javascript
IF urgentTasks.length > 0:
  suggestedNext = urgentTasks[0]
  reason = "urgent (due soon)"
ELSE IF highPriorityTasks.length > 0:
  suggestedNext = highPriorityTasks[0]
  reason = "high priority"
ELSE IF normalTasks.length > 0:
  suggestedNext = normalTasks[0]
  reason = "next in queue"
ELSE:
  suggestedNext = "Add first task with /add-task"
```

### Step 10: Generate Context Summary

**Output structure:**
```markdown
🔄 Switching to: <Project Name>

## 📊 Project Context
**Type:** <type>
**Tech Stack:** <tech_stack>
**Last Worked:** <X> days ago (<date>)

## 📝 Recent Activity (Last 3 tasks)
✅ <task1> (<completion_date>)
✅ <task2> (<completion_date>)
✅ <task3> (<completion_date>)

## ⚠️  Open Tasks (<count>)
**Urgent:**
- <task> (due <date>)

**High Priority:**
- <task> (<details>)

**Normal:**
- <task> (<details>)

## 🧠 Relevant Patterns
**From semantic memory:**
- <pattern1>: <description>
- <pattern2>: <description>

**From past experiences:**
- <experience>: <link>

## 💡 Suggested Next Step
<suggestedTask> (<reason>)

---
**Ready to work on <Project Name>!**
```

## Example Execution

**Input:**
```
/switch client-b
```

**Tool calls sequence:**
```bash
1. Bash(command="test -d 'projects/client-b' && echo 'exists' || echo 'not_exists'")
   → Result: "exists"

2. Bash(command="date '+%Y-%m-%d %H:%M:%S'")
   → Result: "2025-01-09 15:30:00"

3. Read("projects/CURRENT")
   → Result: "client-a"

4. Read("projects/client-a/context.md")
   → Get current project context

5. Write(
     file_path="projects/client-a/context.md",
     content="... Last Worked: 2025-01-09 15:30:00 ..."
   )
   → Update last worked time

6. Write(file_path="projects/CURRENT", content="client-b")
   → Switch to client-b

7. Read("projects/client-b/context.md")
   → Load: type=client, tech=Python/PostgreSQL, last_worked=2025-01-06

8. Read("projects/client-b/tasks.md")
   → Parse: 1 urgent, 2 high priority, 2 normal tasks

9. Read("projects/client-b/patterns.md")
   → Load project-specific patterns

10. Grep(pattern="client-b", path="memory/semantic/clients/", output_mode="files_with_matches")
    → Find: client-b.md

11. Read("memory/semantic/clients/client-b.md")
    → Load: Client prefers detailed docs, weekly sync Thursdays

12. Grep(pattern="client-b", path="memory/episodic/", output_mode="files_with_matches")
    → Find: 3 recent experiences

13. Read("memory/episodic/code/2025-01-06-analytics-dashboard.md")
    → Extract: Implemented dashboard, 4 hours, success

14. Bash(command="date '+%Y-%m-%d'")
    → Result: "2025-01-09"

15. Calculate: 3 days since last worked (Jan 6 → Jan 9)
```

**Output:**
```
🔄 Switching to: Client B - Analytics Platform

## 📊 Project Context
**Type:** Client work
**Tech Stack:** Python (FastAPI), PostgreSQL, React
**Last Worked:** 3 days ago (Jan 6)

## 📝 Recent Activity (Last 3 tasks)
✅ Implemented user analytics dashboard (Jan 6)
✅ Fixed date range selector bug (Jan 4)
✅ Added user filters (Jan 2)

## ⚠️  Open Tasks (5)
**Urgent:**
- Feature spec review (due Jan 11) ← 2 days away

**High Priority:**
- Complete CSV export (estimated: 3h)
- API tests for analytics (due Jan 13, estimated: 2h)

**Normal:**
- Refactor DB queries for performance (estimated: 4h)
- Add caching layer (estimated: 5h)

## 🧠 Relevant Patterns
**From semantic memory:**
- Client B prefers detailed documentation (learned Jan 2025)
- PostgreSQL indexing strategy: Always index foreign keys (HIGH confidence)

**From past experiences:**
- Similar export feature in Client A (see memory/episodic/code/2024-11-20-csv-export.md)
- Analytics dashboard took 4 hours (reference for future estimates)

## 💡 Suggested Next Step
Priority: Review feature spec (urgent, due in 2 days, blocks client)

---
**Ready to work on Client B!**
```

## Success Metrics

**Goal:** Zero context-switching overhead

**Metrics:**
- Context load time: < 10 seconds
- Time saved: 5-10 min per switch
- Context accuracy: 100%

**How this helps:**
- Instant context load (vs 5-10 min manual ramp-up)
- Recent activity reminder (vs "what was I doing?")
- Pattern surfacing (vs rediscovering same solutions)
- Clear next step (vs analysis paralysis)

**Time saved:** 5-10 min per switch × 5-10 switches/day = 25-100 min/day

## Integration with Other Commands

**Works with:**
- `/overview` - Shows tasks across ALL projects
- `/add-task [project]` - Adds task to specific project
- `/learn` - Extracts patterns to current project
- `/recall` - Can search current project context

**Example flow:**
```bash
/overview                    # See all projects
/switch client-a            # Switch to urgent project
/add-task client-a "Fix OAuth bug"  # Add task
[complete work]
/learn                      # Extract patterns (saved to client-a/)
/switch client-b           # Switch to next priority
```

## Required Files

**Structure:**
```
projects/
├── CURRENT              # Contains current project name
├── INDEX.md             # List of all projects
├── client-a/
│   ├── context.md
│   ├── tasks.md
│   ├── patterns.md
│   └── notes.md
└── client-b/
    ├── context.md
    ├── tasks.md
    ├── patterns.md
    └── notes.md
```

## Edge Cases

### Project Not Found

**If project doesn't exist:**
```markdown
❌ Project 'client-c' not found.

**Available projects:**
- client-a (Client A - E-commerce)
- client-b (Client B - Analytics)
- internal-product (SaaS Product)

**Create new project:** /new-project "client-c"
```

### No Current Project

**If projects/CURRENT doesn't exist:**
```javascript
// Skip step 3 (saving current context)
// Proceed with loading new project
```

### Empty Project

**If project has no tasks:**
```markdown
✨ No open tasks!

**Add first task:** /add-task <project-name> "First task"
```

## Notes for the user

**Use `/switch` before starting work** on a different project

**Benefits:**
- projects/CURRENT is automatically read by other commands
- Past experiences are surfaced automatically
- Patterns accumulate over time
- Zero mental overhead when switching

**Workflow:** Work on 5 projects/day with zero context-switching cost
