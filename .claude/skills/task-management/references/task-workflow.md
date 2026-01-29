# Task Management - Detailed Workflow

Full 10-step task addition with validation.

## Step 1: Parse Input

Extract project name and task description.

```javascript
// Input format: "/add-task project-name task description"
const [projectName, ...taskParts] = userInput.split(' ')
const taskDescription = taskParts.join(' ')
```

## Step 2: Validate Project Exists

**Tool: Read**
```bash
Read("projects/INDEX.md")
```

**Check**:
```javascript
if (!indexContent.includes(projectName)) {
  throw new Error(`Project '${projectName}' not found. Run /new-project first.`)
}
```

## Step 3: Get Current Date

**Tool: Bash**
```bash
Bash(command="date '+%Y-%m-%d'")
```

## Step 4: Read Project Tasks

**Tool: Read**
```bash
Read(`projects/${projectName}/tasks.md`)
```

## Step 5: Determine Priority

**Keyword Analysis**:
```javascript
const text = taskDescription.toLowerCase()
let priority = "NORMAL"  // default

// URGENT
if (text.includes("urgent") || text.includes("critical") || text.includes("blocking") ||
    text.includes("production") || text.includes("p0") || text.includes("asap")) {
  priority = "URGENT"
}
// HIGH  
else if (text.includes("important") || text.includes("needed") || text.includes("client-requested") ||
         text.includes("deadline") || text.includes("soon") || text.includes("priority")) {
  priority = "HIGH"
}
// LOW
else if (text.includes("nice-to-have") || text.includes("someday") || text.includes("backlog") ||
         text.includes("explore") || text.includes("consider")) {
  priority = "LOW"
}
```

## Step 6: Add to Correct Section

**Tool: Edit**
```bash
Edit(
  file_path=`projects/${projectName}/tasks.md`,
  old_string=`## ${prioritySection}\n`,
  new_string=`## ${prioritySection}\n- [ ] ${taskDescription}\n  Priority: ${priority} | Added: ${currentDate} | Est: ${estimatedTime}\n`
)
```

**Section mapping**:
```javascript
const sections = {
  URGENT: "## Urgent (Due Today)",
  HIGH: "## High Priority",
  NORMAL: "## Normal Priority",
  LOW: "## Low Priority / Backlog"
}
```

## Step 7: Count Total Tasks

**Tool: Grep**
```bash
Grep(
  pattern="^- \\[ \\]",
  path=`projects/${projectName}/tasks.md`,
  output_mode="count"
)
```

## Step 8: Update Project Context (If Significant)

For HIGH or URGENT tasks:

**Tool: Edit**
```bash
Edit(
  file_path=`projects/${projectName}/context.md`,
  old_string="## Latest Update",
  new_string=`## Latest Update (${currentDate})\nAdded ${priority} priority task: ${taskDescription}`
)
```

## Step 9: Check Capacity

```javascript
if (totalOpenTasks > 20) {
  console.warn("⚠️ Over-capacity: > 20 open tasks. Consider completing or deferring some tasks.")
} else if (totalOpenTasks > 15) {
  console.warn("⚠️ Approaching capacity: 15-20 tasks. Prioritize completion.")
}
```

## Step 10: Show Confirmation

```markdown
✅ Task added to ${projectName}!

📋 **Task:** ${taskDescription}
⭐ **Priority:** ${priority}
📅 **Added:** ${currentDate}

📊 **Project Status:**
- Urgent: ${urgentCount}
- High: ${highCount}  
- Normal: ${normalCount}
- Low: ${lowCount}
- **Total open:** ${totalOpenTasks}

${capacityWarning}

💡 **Next:** /overview to see all tasks, /switch ${projectName} to start work
```
