---
name: new-project
description: Create a new project with standard structure and context files
allowed-tools: Read, Write, Bash
---

# New Project Command

Usage: `/new-project [project-name]`

Create a new project with all necessary structure for tracking tasks, context, and patterns.

## Execution Steps

### Step 1: Sanitize Project Name

**Process input:**
```javascript
// Sanitize name (lowercase, replace spaces with hyphens)
const sanitizedName = projectName
  .toLowerCase()
  .replace(/\s+/g, '-')
  .replace(/[^a-z0-9-]/g, '')
```

### Step 2: Check if Project Already Exists

**Tool: Bash**
```bash
Bash(command="test -d 'projects/<sanitized-name>' && echo 'exists' || echo 'not_exists'")
```

**If exists:**
```markdown
❌ Error: Project '<sanitized-name>' already exists.

**Use instead:** /switch <sanitized-name>

**Or rename:** /new-project "<different-name>"
```
**Exit if exists**

### Step 3: Get Current Date

**Tool: Bash**
```bash
Bash(command="date '+%Y-%m-%d'")
```

**Store as:** `currentDate`

### Step 4: Create Project Directory Structure

**Tool: Bash**
```bash
Bash(command="mkdir -p 'projects/<sanitized-name>'")
```

### Step 5: Create Context File

**Tool: Write**
```bash
Write(
  file_path="projects/<sanitized-name>/context.md",
  content="# <Project Name>\n\n## Overview\n- **Type:** [Client work / Internal product / Content / R&D / Personal]\n- **Started:** <currentDate>\n- **Status:** Active\n- **Tech Stack:** [To be filled]\n\n## Key Context\n[What's important to know about this project]\n\n## Constraints\n[Technical, business, or timeline constraints]\n\n## Contacts\n[Key people involved]\n\n## Last Worked\n- **Date:** <currentDate>\n- **Task:** Project setup\n- **Next:** [First task to tackle]\n\n## Ideas to Explore\n[Ideas related to this project will appear here]\n"
)
```

### Step 6: Create Tasks File

**Tool: Write**
```bash
Write(
  file_path="projects/<sanitized-name>/tasks.md",
  content="# Tasks - <Project Name>\n\n## Urgent\n[Tasks due today or overdue]\n\n## High Priority\n[Important tasks to do soon]\n\n## Normal\n[Regular tasks]\n\n## Low Priority\n[Nice-to-have tasks]\n\n## Blocked\n[Tasks waiting on external dependencies]\n\n## Completed\n- [x] Project setup (completed: <currentDate>)\n"
)
```

### Step 7: Create Patterns File

**Tool: Write**
```bash
Write(
  file_path="projects/<sanitized-name>/patterns.md",
  content="# Patterns - <Project Name>\n\n[Patterns specific to this project will accumulate here]\n\n## Technical Patterns\n[Technical solutions that worked well]\n\n## Process Patterns\n[Workflow patterns that were effective]\n\n## Client Patterns\n[If client project: client-specific patterns]\n"
)
```

### Step 8: Create Notes File

**Tool: Write**
```bash
Write(
  file_path="projects/<sanitized-name>/notes.md",
  content="# Notes - <Project Name>\n\n[General project notes, meeting notes, decisions]\n\n## Meeting Notes\n\n## Decisions\n\n## References\n"
)
```

### Step 9: Update Projects Index

**Tool: Read**
```bash
Read("projects/INDEX.md")
```

**Tool: Write** (if file doesn't exist, create it)
```bash
IF file_not_found:
  Write(
    file_path="projects/INDEX.md",
    content="# Projects Index\n\n## Active\n\n## Archived\n"
  )
```

**Tool: Bash** (append to index)
```bash
Bash(command="echo '\n- <sanitized-name> (<Project Name>) - Added <currentDate>' >> projects/INDEX.md")
```

### Step 10: Set as Current Project

**Tool: Write**
```bash
Write(
  file_path="projects/CURRENT",
  content="<sanitized-name>"
)
```

### Step 11: Output Confirmation

**Display success message:**
```markdown
✅ Created new project: <sanitized-name>

📁 Project structure:
projects/<sanitized-name>/
├── context.md          ← Fill in project details
├── tasks.md            ← Add your tasks here
├── patterns.md         ← Patterns will accumulate here
└── notes.md            ← Project notes

🔄 Set as current project

💡 Next steps:
1. Fill in: projects/<sanitized-name>/context.md (5 min)
2. Add first task: /add-task <sanitized-name> "First task"
3. Start working!
```

## Example Execution

**Input:**
```
/new-project "Client A - E-commerce Platform"
```

**Tool calls sequence:**
```bash
1. Sanitize: "Client A - E-commerce Platform" → "client-a-e-commerce-platform"

2. Bash(command="test -d 'projects/client-a-e-commerce-platform' && echo 'exists' || echo 'not_exists'")
   → Result: "not_exists"

3. Bash(command="date '+%Y-%m-%d'")
   → Result: "2025-01-09"

4. Bash(command="mkdir -p 'projects/client-a-e-commerce-platform'")
   → Directory created

5. Write(file_path="projects/client-a-e-commerce-platform/context.md", content="...")
   → Context file created

6. Write(file_path="projects/client-a-e-commerce-platform/tasks.md", content="...")
   → Tasks file created

7. Write(file_path="projects/client-a-e-commerce-platform/patterns.md", content="...")
   → Patterns file created

8. Write(file_path="projects/client-a-e-commerce-platform/notes.md", content="...")
   → Notes file created

9. Read("projects/INDEX.md")
   → Check if exists

10. Bash(command="echo '\n- client-a-e-commerce-platform (Client A - E-commerce Platform) - Added 2025-01-09' >> projects/INDEX.md")
    → Index updated

11. Write(file_path="projects/CURRENT", content="client-a-e-commerce-platform")
    → Set as current
```

**Output:**
```
✅ Created new project: client-a-e-commerce-platform

📁 Project structure:
projects/client-a-e-commerce-platform/
├── context.md          ← Fill in project details
├── tasks.md            ← Add your tasks here
├── patterns.md         ← Patterns will accumulate here
└── notes.md            ← Project notes

🔄 Set as current project

💡 Next steps:
1. Fill in: projects/client-a-e-commerce-platform/context.md (5 min)
2. Add first task: /add-task client-a-e-commerce-platform "Setup development environment"
3. Start working!
```

## Example Output

```bash
$ /new-project "Client A - E-commerce Platform"

✅ Created new project: client-a-e-commerce-platform

📁 Project structure:
projects/client-a-e-commerce-platform/
├── context.md          ← Fill in project details
├── tasks.md            ← Add your tasks here
├── patterns.md         ← Patterns will accumulate here
└── notes.md            ← Project notes

📝 Created client memory:
memory/semantic/clients/client-a.md ← Fill in client context

🔄 Set as current project
Run /switch client-a-e-commerce-platform to load context

💡 Next steps:
1. Fill in: projects/client-a-e-commerce-platform/context.md (5 min)
2. Fill in: memory/semantic/clients/client-a.md (5 min)
3. Add first task: /add-task client-a-e-commerce-platform "First task"
4. Start working!
```

## Integration with Other Commands

**After creating project:**
- `/switch [project-name]` - Load project context
- `/add-task [project-name] [task]` - Add tasks
- `/overview` - See this project in daily overview

**Memory connections:**
- Client projects → memory/semantic/clients/
- Dev projects → memory/semantic/tech/
- Content projects → memory/semantic/patterns/content-patterns.md

## Quick Project Types

**Client Project:**
```bash
/new-project "Client A - E-commerce" type=client tech="Python, React, PostgreSQL"
```

**Internal Product:**
```bash
/new-project "Internal SaaS" type=internal tech="FastAPI, React, Redis"
```

**Content Project:**
```bash
/new-project "Q1 2025 Content Calendar" type=content
```

**R&D Experiment:**
```bash
/new-project "AI Recommendations Research" type=research
```

## Project Naming Best Practices

**Good names:**
- "Client A - E-commerce Platform"
- "Internal Product - SaaS"
- "Q1 2025 Content"
- "React Migration R&D"

**Avoid:**
- Generic names: "Project 1", "Test"
- Too long: "Client A E-commerce Platform with React and Python Backend"
- Special characters: "Client A (New!)", "Project #2"

## Notes for the user

**When to create new projects:**
- New client engagement
- New internal product/feature
- New content initiative
- R&D experiment
- Learning project

**Don't over-create:**
- Small tasks within existing project → Use /add-task instead
- One-off tasks → Just do them, no project needed

**Organization tip:**
- Client work: One project per client
- Internal: One project per major product/feature
- Content: One project per quarter/campaign
- Learning: One project per course/tech

**Time to create:** 2-3 minutes
**Benefit:** Organized context, task tracking, pattern accumulation
