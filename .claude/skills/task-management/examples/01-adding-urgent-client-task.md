# Task Management Example: Adding Urgent Client Task

## Scenario
Client emails: "Production payment processing is broken, users can't check out. Need fix ASAP!"

Need to add urgent task, see it prioritized correctly, get capacity warning if over-loaded.

## User Input
```
/add-task client-a "urgent: fix production payment processing bug"
```

## Execution

### Step 1: Parse Input
- **Project**: client-a
- **Task description**: "urgent: fix production payment processing bug"

### Step 2: Validate Project
**Tool: Read**
```bash
Read("projects/INDEX.md")
```

**Check**: client-a exists in Active Projects ✅

### Step 3: Get Current Date
**Tool: Bash**
```bash
date '+%Y-%m-%d'
```

**Output**: 2025-01-09

### Step 4: Read Project Tasks
**Tool: Read**
```bash
Read("projects/client-a/tasks.md")
```

**Current state**:
- URGENT: 0 tasks
- HIGH: 2 tasks
- NORMAL: 5 tasks
- LOW: 3 tasks

### Step 5: Determine Priority

**Keyword analysis**:
- "urgent" → URGENT ✅
- "production" → URGENT ✅
- "bug" → (could be normal, but context makes it urgent)

**Priority**: URGENT

### Step 6: Estimate Time
**Default estimate** for "bug fix": 2 hours

### Step 7: Add to Tasks File

**Tool: Edit**
```bash
Edit(
  file_path="projects/client-a/tasks.md",
  old_string="## Urgent (Due Today)\n\n*No urgent tasks yet*",
  new_string="## Urgent (Due Today)\n\n- [ ] Fix production payment processing bug\n  Priority: URGENT | Added: 2025-01-09 | Est: 2h\n"
)
```

### Step 8: Count Total Tasks

**Tool: Grep**
```bash
Grep(
  pattern="^- \\[ \\]",
  path="projects/client-a/tasks.md",
  output_mode="count"
)
```

**Result**: 11 open tasks (was 10, now 11)

### Step 9: Check Capacity

**Capacity check**:
- Total open: 11 tasks
- Capacity zone: < 15 (healthy) ✅

### Step 10: Update Project Context

**Tool: Edit**
```bash
Edit(
  file_path="projects/client-a/context.md",
  old_string="## Latest Update",
  new_string="## Latest Update (2025-01-09)\n\n⚠️ URGENT: Production payment bug reported. Added to top of task queue."
)
```

### Step 11: Show Confirmation

```markdown
✅ Task added to client-a!

🔥 **URGENT TASK**

📋 **Task**: Fix production payment processing bug
⭐ **Priority**: URGENT (detected from keywords: "urgent", "production")
📅 **Added**: 2025-01-09
⏱️ **Estimate**: 2h

📊 **Project Status**:
- 🔥 Urgent: 1 (NEW!)
- ⭐ High: 2
- 📌 Normal: 5
- 📦 Low: 3
- **Total open**: 11 tasks

✅ **Capacity**: Healthy (< 15 tasks)

💡 **Next Steps**:
1. /switch client-a - Load full project context
2. Start work immediately (production issue)
3. Update task when complete: check off `- [x]`

⚠️ **Production Issue**: This is blocking users. Recommend starting now.
```

## Outcome
- **Time**: 8 seconds to add task
- **Priority**: Correctly auto-detected as URGENT
- **Visibility**: Now at top of task queue
- **Context**: Project context.md updated with urgent note
- **Next action**: User runs `/switch client-a` to load context and start work

## Task Workflow After This

**Immediate**:
```
/switch client-a
→ Loads project context
→ Shows urgent task at top
→ Suggests starting immediately
```

**During Work**:
```
Working on fix...
(episodic memory will log the debugging session)
```

**After Completion**:
```
Edit tasks.md:
- [x] Fix production payment processing bug
  Priority: URGENT | Added: 2025-01-09 | Est: 2h | ✅ Completed: 2025-01-09 (Actual: 1.5h)

Move to ## Completed section
```

**Weekly Review** (`/overview` or `/grow`):
- Task completed ✅
- Time saved: 0.5h (under estimate, efficient fix)
- Pattern: If debugging payment issues becomes common → create "Payment Debugging" pattern

## Capacity Management Demonstration

**If user was over-capacity**, the confirmation would show:

```markdown
⚠️ OVER-CAPACITY WARNING

📊 **Project Status**: 23 open tasks (over 20 limit)

💡 **Recommendations**:
1. Complete this URGENT task first
2. Defer 3-5 NORMAL priority tasks
3. Consider moving LOW priority items to backlog
4. Run /overview to prioritize across all projects
```

## Why This Works
1. **Fast**: 8 seconds to add, no manual categorization
2. **Smart**: Auto-detected URGENT from keywords
3. **Visible**: Top of task queue, impossible to miss
4. **Contextual**: Project context updated with note
5. **Capacity-aware**: Warns if over-loading project
6. **Integrated**: Works with /switch and /overview for full workflow
