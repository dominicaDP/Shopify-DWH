---
name: task-management
description: Add tasks to project queues with automatic prioritization and time estimation
allowed-tools: "Read,Write,Edit,Grep,Bash"
---

# Task Management Skill

## Skill Metadata
- **Version**: 1.0.0
- **Author**: the user's Second Brain Team
- **Category**: productivity
- **Tags**: tasks, project-management, prioritization, time-tracking

**Dependencies**:
- **Files**: `projects/*/tasks.md`, `projects/INDEX.md`, `projects/CURRENT`

**Input Parameters**:
- `project_name` (string, required): Target project
- `task_description` (string, required): What needs to be done
- `priority` (enum, optional): urgent | high | normal | low

**Output**:
- `task_added` (boolean): Success status
- `task_count` (number): Total tasks in project
- `suggested_priority` (string): AI-determined priority

**Success Metrics**:
- Task add time: < 15 seconds
- Tasks completed: 70%+ completion rate
- Priority accuracy: 85%+ tasks in correct queue

---

## Executive Snapshot

**Autonomous Task Addition**: Adds tasks to project queues with validation, prioritization, and automatic queue management in < 15 seconds.

**Core Philosophy**: Capture tasks immediately without context-switching. The system handles validation, prioritization, and capacity warnings.

**Quality Standard**: Every task gets priority assignment, time estimate, and proper queue placement. System warns if project over-capacity.

---

## When to Run

**Trigger moments**:
- After meetings (capture action items)
- During code reviews (note improvements needed)
- Client requests (log immediately)
- Ideas → tasks conversion (from `/idea`)

**Time investment**: < 15 seconds per task

**ROI**: 30 min/week saved (vs manual task tracking)

---

## Workflow Overview (10 Steps)

### 1. Parse Input
Extract project name and task description from user input.

### 2. Validate Project Exists
Check `projects/INDEX.md` to ensure project is valid. Fail fast if not found.

### 3. Get Current Date
Timestamp for task creation tracking.

### 4. Read Project Tasks
Load existing `projects/<project>/tasks.md` to determine current state.

### 5. Determine Priority
Analyze task description for urgency keywords:
- **URGENT**: due today, critical, blocking
- **HIGH**: important, needed soon
- **NORMAL**: standard work
- **LOW**: nice-to-have, backlog

### 6. Add to Correct Section
Append task to appropriate priority queue in tasks.md.

### 7. Count Total Tasks
Grep to count total open tasks (capacity check).

### 8. Update Project Context
Add task reference to `projects/<project>/context.md` if significant.

### 9. Check Capacity
Warn if > 20 open tasks (over-capacity, need to prioritize/complete).

### 10. Show Confirmation
Display task added, current counts by priority, capacity status.

📖 **For detailed execution with tool calls**: `Read {baseDir}/references/task-workflow.md`

---

## Task File Structure

```markdown
# Project Tasks

## Urgent (Due Today)
- [ ] Fix production bug in payment flow
  Priority: URGENT | Added: 2025-01-09 | Est: 2h

## High Priority
- [ ] Implement user authentication
  Priority: HIGH | Added: 2025-01-08 | Est: 4h

## Normal Priority
- [ ] Add email notifications
  Priority: NORMAL | Added: 2025-01-07 | Est: 2h

## Low Priority / Backlog
- [ ] Improve loading animation
  Priority: LOW | Added: 2025-01-06 | Est: 1h

## Completed
- [x] Deploy to staging (2025-01-09)
```

---

## Priority Assignment Logic

**Automatic Priority Detection**:

| Keywords | Priority | Example |
|----------|----------|---------|
| critical, urgent, blocking, production, P0 | **URGENT** | "Fix critical auth bug" |
| important, needed, client-requested, deadline | **HIGH** | "Client needs dashboard by Friday" |
| (default) | **NORMAL** | "Add export feature" |
| nice-to-have, someday, backlog, explore | **LOW** | "Nice to have: dark mode" |

📖 **For prioritization rules**: `Read {baseDir}/references/priority-logic.md`

---

## Success Metrics

**Goal**: Never forget a task, always know what's next

**Weekly Targets**:
- 15-25 tasks added per week
- < 15 seconds average add time
- 70%+ task completion rate
- 85%+ priority accuracy (tasks in correct queue)

**Capacity Management**:
- **Healthy**: < 15 open tasks per project
- **Warning**: 15-20 open tasks (need to prioritize)
- **Over-capacity**: > 20 open tasks (stop adding, start completing)

---

## Integration with Other Commands

### Add Task: `/add-task [project] [task]`
Quick capture during work.

### View Tasks: `/overview`
See all tasks across projects, prioritized.

### Switch Context: `/switch [project]`
Load project with tasks visible.

### Complete Task: Manual
Check off in tasks.md, system auto-moves to Completed section.

---

## Task Lifecycle

```
Idea → `/idea` capture
  ↓
High-value idea → `/add-task` to project
  ↓
Daily planning → `/overview` shows prioritized tasks
  ↓
Work on task → `/switch [project]` loads context
  ↓
Complete task → Check off in tasks.md
  ↓
Learning extraction → `/learn` after significant tasks
```

---

## Progressive Disclosure

**Core operational workflow**: This file (~200 lines)

**Detailed execution**:
- 📖 `Read {baseDir}/references/task-workflow.md` - Full 10-step task addition with validation
- 📖 `Read {baseDir}/references/priority-logic.md` - Automatic priority assignment rules

**Best practices**:
- 📖 `Read {baseDir}/references/task-management-guide.md` - Capacity management and completion strategies

---

*Last Updated: 2025-01-09*
*Version: 1.0.0*
*Lines: ~200 (entry point) + reference files (on-demand)*
