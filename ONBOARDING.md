# Second Brain - Onboarding Guide

**Goal:** Get your second brain operational in 90 minutes

---

## What is the Second Brain?

A knowledge management system that:
1. **Preserves context** between conversations (no more re-explaining)
2. **Extracts patterns** from your work automatically
3. **Compounds knowledge** - each task makes future tasks easier
4. **Manages projects** with zero context-switching overhead

### The Vibe Engineering Workflow

```
PLAN → DELEGATE → ASSESS → CODIFY
  ↓         ↓         ↓        ↓
/plan    /work    /review   /learn
```

**Key Principle:** Each unit of work should make subsequent work easier.

---

## Phase 1: Prerequisites (10 minutes)

### Required Software

- [ ] **Claude Code CLI** - `npm install -g @anthropic-ai/claude-code`
- [ ] **Git** - For version control
- [ ] **Node.js** - v18+ (for Claude Code)
- [ ] **Your IDE** - VS Code, IntelliJ, etc.

### Verify Installation

```bash
claude --version
git --version
node --version
```

---

## Phase 2: Customize CLAUDE.md (20 minutes)

This is the most important file - it tells Claude who you are.

### Open CLAUDE.md and update the User Profile section:

**1. Role & Context**
```markdown
- [Your job title]
- [Company type and size]
- [Primary work focus]
- [How long using Claude]
```

**2. Work Domains**
```markdown
- [Your primary language/framework]
- [Secondary tools you use]
- [Types of work you do]
```

**3. Pain Points**
```markdown
- [What frustrates you most?]
- [What takes too long?]
- [What do you keep repeating?]
```

**4. Tech Stack**
```markdown
- IDE: [VS Code / IntelliJ / etc.]
- Language: [Python / TypeScript / Go / etc.]
- Framework: [React / Django / Rails / etc.]
- Database: [PostgreSQL / MongoDB / etc.]
- Platform: [Windows / macOS / Linux]
```

**5. Goals**
```markdown
- [What does success look like in 6 months?]
```

---

## Phase 3: Configure Permissions (10 minutes)

Edit `settings.local.json` to add tools for your tech stack.

### Example for Python developer:
```json
{
  "permissions": {
    "allow": [
      "Read", "Write", "Edit", "Grep", "Glob",
      "Bash(git *:*)",
      "Bash(python *:*)",
      "Bash(pip *:*)",
      "Bash(pytest *:*)",
      "Bash(poetry *:*)"
    ]
  }
}
```

### Example for TypeScript developer:
```json
{
  "permissions": {
    "allow": [
      "Read", "Write", "Edit", "Grep", "Glob",
      "Bash(git *:*)",
      "Bash(npm *:*)",
      "Bash(node *:*)",
      "Bash(npx *:*)",
      "Bash(yarn *:*)"
    ]
  }
}
```

### Example for Go developer:
```json
{
  "permissions": {
    "allow": [
      "Read", "Write", "Edit", "Grep", "Glob",
      "Bash(git *:*)",
      "Bash(go *:*)",
      "Bash(make *:*)"
    ]
  }
}
```

---

## Phase 4: Create Your First Project (15 minutes)

### 1. Create project directory

```bash
mkdir -p projects/my-first-project
```

### 2. Create context.md

```markdown
# [Project Name]

**Project Type:** [Personal / Work / Client]
**Status:** Active

## Overview
[What does this project do?]

## Tech Stack
- **Language:** [Your language]
- **Framework:** [Your framework]
- **Database:** [Your database]
- **Hosting:** [Where it runs]

## Architecture
[Key architectural decisions]

## Current Focus
[What are you working on right now?]
```

### 3. Create tasks.md

```markdown
# Tasks

**Project:** [project-name]
**Last Updated:** [today's date]

## Urgent (Due Today)

## High Priority

- [ ] [Your first high-priority task]
  **Priority:** HIGH | **Added:** [date] | **Est:** [hours]

## Normal

## Backlog

## Completed
```

### 4. Create patterns.md

```markdown
# Patterns

**Project:** [project-name]

## [Pattern Name]

**Confidence:** LOW
**Uses:** 0
**When to use:** [scenario]

### Implementation
```[language]
// Your code example
```

### Why it works
[Explanation]
```

### 5. Update projects/INDEX.md

Add your project to the registry.

---

## Phase 5: Initialize Memory (10 minutes)

### Create tech documentation

**memory/semantic/tech/architecture-decisions.md:**
```markdown
# Architecture Decisions

## Tech Stack
- **Language:** [Your language]
- **Framework:** [Your framework]
- **Database:** [Your database]

## Key Decisions

### [Decision 1]
**Date:** [when]
**Decision:** [what you decided]
**Reasoning:** [why]
```

### Create patterns file

**memory/semantic/patterns/dev-patterns.md:**
```markdown
# Development Patterns

## Overview
Patterns extracted from development work.

## Patterns

### [Pattern Name]
**Confidence:** LOW | MEDIUM | HIGH
**Uses:** [count]
**Category:** [code/architecture/process]

**Description:** [what it does]

**Implementation:**
```[language]
// code
```
```

---

## Phase 6: Test the System (15 minutes)

### 1. Start Claude Code

```bash
cd /path/to/second-brain
claude
```

### 2. Test context loading

```
/switch my-first-project
```

You should see:
- Project context loaded
- Current tasks displayed
- Recent activity shown

### 3. Test overview

```
/overview
```

You should see:
- Tasks across all projects
- Urgent items highlighted
- Deadlines shown

### 4. Test learning extraction

After doing some work:
```
/learn
```

Answer the questions:
- What was completed?
- Root cause of issues?
- Patterns identified?
- Confidence level?

---

## Phase 7: Daily Workflow Practice (10 minutes)

### Morning Routine

```bash
# 1. Start Claude Code
claude

# 2. Check all tasks
/overview

# 3. Load project context
/switch [project-name]

# 4. Plan complex work (if needed)
/plan [describe your task]
```

### During the Day

```bash
# For complex tasks
/step                  # Execute next planned step
/plan-status           # Check progress

# Quick captures
/idea [your idea]      # Capture ideas
/add-task [task]       # Add tasks
```

### End of Day

```bash
# CRITICAL: Extract learnings before closing
/learn
```

---

## Troubleshooting

### Commands not working?
1. Verify `.claude/commands/` directory exists
2. Check frontmatter YAML syntax in command files
3. Restart Claude Code

### Context not loading?
1. Check `projects/[name]/context.md` exists
2. Verify file permissions
3. Try reading the file directly: `Read projects/[name]/context.md`

### Memory not updating?
1. Run `/learn` after completing work
2. Check `memory/` directory structure
3. Verify Write permissions in settings.local.json

---

## Next Steps

### Week 1: Build the Habit
- [ ] Run `/overview` every morning
- [ ] Use `/switch` when changing projects
- [ ] Run `/learn` at end of each day
- [ ] Capture ideas with `/idea`

### Week 2: Extract Patterns
- [ ] Run `/learn` after completing features
- [ ] Document patterns in `patterns.md`
- [ ] Promote patterns: LOW → MEDIUM after 3 uses

### Week 3: Compound Knowledge
- [ ] Review patterns with `/recall`
- [ ] Check brain health with `/grow`
- [ ] Refine workflows based on experience

---

## Success Metrics

Track these to measure progress:

**Knowledge Compounding:**
- Patterns extracted: _____ (goal: 5+ in week 1)
- Pattern reuses: _____ (goal: start seeing in week 2)
- Confidence promotions: _____ (LOW → MEDIUM)

**Time Savings:**
- Context restoration: _____ min saved per session
- Pattern application: _____ min saved per feature

**Workflow Adoption:**
- `/learn` runs per week: _____
- `/switch` uses per day: _____
- Active projects managed: _____

---

## Key Commands Reference

| Command | When to Use |
|---------|-------------|
| `/overview` | Morning, to see all tasks |
| `/switch [project]` | When changing projects |
| `/plan [goal]` | Before complex tasks (>15 min) |
| `/step` | To execute planned work |
| `/learn` | After completing work |
| `/recall [topic]` | To find past patterns |
| `/grow` | Weekly, to check brain health |
| `/idea [text]` | When you have an idea |
| `/add-task [desc]` | To add new tasks |

---

**You're ready! Start with `/overview` to see your tasks.**
