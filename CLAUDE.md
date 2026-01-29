# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

**Second Brain** - Knowledge management system using three-layer architecture: Commands → Skills → Memory.

**Core Purpose:** Persistent second brain that extracts patterns from development work, preserves context across conversations, and compounds knowledge over time.

## User Profile

**Role & Context:**
- Researcher/Learner
- Focus: Research and learning with code snippets
- Building knowledge management system

**Work Domains:**
- Research documentation
- Code snippets and examples
- Learning notes

**Tech Stack:**
- Platform: Windows
- (Additional tools to be added later)

**Goals:**
- Build persistent knowledge base
- Extract patterns from research
- Organize code snippets effectively

## Architecture

### Three-Layer System

```
Commands (.claude/commands/*.md)
    ↓ invoke
Skills (.claude/skills/*/SKILL.md)
    ↓ use
Memory (memory/)
```

1. **Commands**: User-facing slash commands (`/learn`, `/switch`, `/overview`)
2. **Skills**: Executable workflows with progressive disclosure, examples, and tests
3. **Memory**: Knowledge storage (semantic, episodic, procedural)

**Key Principle:** Commands are the interface, Skills are the implementation, Memory is the storage.

### Directory Structure

```
.claude/
├── commands/          # Slash commands
├── skills/            # Executable skills with references/examples/tests
├── hooks/             # Context-aware micro-guidance
└── agents/            # Specialized AI agents

memory/
├── semantic/          # What you know (facts, patterns, tech stack)
├── episodic/          # What you've done (experiences, completed work)
└── procedural/        # How you do things (workflows, processes)

projects/              # Active projects
├── INDEX.md
└── [project-name]/
    ├── context.md
    ├── tasks.md
    └── patterns.md
```

## Core Workflows

### Daily Commands

```bash
/overview              # Morning dashboard: urgent tasks across all projects
/switch [project]      # Zero-overhead context switching with auto-load
/idea [text]           # Quick idea capture with auto-categorization
/add-task [desc]       # Add task to current project with auto-prioritization
/learn                 # Extract patterns from completed work
/grow                  # Brain health metrics and ROI tracking
```

### Planning System (For Complex Tasks)

```bash
/plan [goal]           # Break into small steps
/step                  # Execute next step incrementally
/plan-status           # Show progress, time tracking, blockers
```

**When to use planning:**
- Tasks that take >15 minutes
- Multi-file changes with dependencies
- Complex implementations requiring checkpoints

**When NOT to use planning:**
- Simple edits (<5 minutes)
- Single-file changes
- Straightforward bug fixes

### Memory Commands

```bash
/recall [topic]        # Search all memory types for relevant patterns
/new-project [name]    # Scaffold new project with standard structure
```

## How to Work in This Repository

### 1. Check Current Context

Before making any changes:

```bash
# Read current project
Read projects/CURRENT

# Load project context
Read projects/[name]/context.md
Read projects/[name]/tasks.md
Read projects/[name]/patterns.md
```

### 2. For Complex Tasks: Plan First

If task requires >15 minutes or multiple files:

```bash
/plan [your goal description]
/step
/step
/plan-status
```

### 3. After Completing Work: Extract Learnings

```bash
/learn
```

Questions to answer:
- What was completed?
- Root cause of issues?
- Patterns identified?
- Confidence level? (LOW/MEDIUM/HIGH)

## Skills Framework

### Progressive Disclosure Pattern

Skills use a modular structure:

```
skill-name/
├── SKILL.md                  # Core instructions (~200 lines)
├── references/               # Loaded on-demand
├── examples/                 # Real-world scenarios
└── tests/                    # Validation cases
```

**Pattern:** Read SKILL.md first (always), then load references/ only when needed.

### Skill Frontmatter Format

Only 3 fields are valid:

```yaml
---
name: skill-name
description: What it does and when to use it
allowed-tools: "Read,Write,Edit,Grep,Bash"
---
```

## Safety System

### Permissions (settings.local.json)

**Allowed Operations:**
- File operations: `Read`, `Write`, `Edit`, `Grep`, `Glob`
- Git operations: `Bash(git *:*)`
- Basic shell commands
- Development tools for your stack

**Blocked Operations:**
- Destructive file operations: `rm -rf`, etc.
- Privilege escalation: `sudo`, `su`
- Unrestricted network tools

## Memory System

### Semantic Memory (What You Know)

```
memory/semantic/
├── tech/
│   ├── architecture-decisions.md
│   └── tech-stack.md
├── patterns/
│   └── dev-patterns.md
└── ideas/
```

### Episodic Memory (What You've Done)

```
memory/episodic/
└── completed-work/
    └── YYYY-MM-DD-description.md
```

### Procedural Memory (How You Do Things)

```
memory/procedural/
└── workflows/
```

## Project Management

### Project Structure

Every project has:

```
projects/[name]/
├── context.md       # Tech stack, timeline, constraints
├── tasks.md         # Urgent/High/Normal/Completed sections
├── patterns.md      # Project-specific patterns learned
└── notes.md         # Meeting notes, decisions (optional)
```

### Task Format

```markdown
## Urgent (Due Today)
- [ ] Task description
  Priority: URGENT | Added: YYYY-MM-DD | Est: Xh | Due: YYYY-MM-DD

## High Priority
- [ ] Task description
  Priority: HIGH | Added: YYYY-MM-DD | Est: Xh

## Normal
- [ ] Task description
  Priority: NORMAL | Added: YYYY-MM-DD | Est: Xh

## Completed
- [x] Task description
  Priority: HIGH | Added: YYYY-MM-DD | Completed: YYYY-MM-DD
```

### Switching Projects

```bash
/switch project-name

# What it does:
# 1. Reads context.md
# 2. Loads open tasks
# 3. Shows recent activity
# 4. Loads relevant patterns from memory
# 5. Updates projects/CURRENT
```

## Daily/Weekly Rituals

### Morning Ritual

```bash
1. /overview              # Urgent tasks across all projects
2. /switch [project]      # Load first project context
3. /plan [task]           # If complex, plan first
```

### End-of-Day Ritual

```bash
/learn                    # Extract patterns before context fades
```

### Weekly Ritual

```bash
/grow                     # Brain health metrics
```

Review:
- Patterns extracted this week
- Projects needing attention
- Plan next week's priorities

## System Principles

1. **Knowledge Compounds** - Tasks add to semantic memory via `/learn`
2. **Zero Context Switching** - `/switch` loads full project context instantly
3. **Progressive Disclosure** - Read SKILL.md first, then references/ on-demand
4. **Incremental Execution** - `/plan` breaks tasks into small steps
5. **Safety First** - settings.local.json blocks destructive operations
6. **Pattern Reuse** - Extract patterns once, apply across all projects
7. **Evidence-Based Learning** - Patterns promoted LOW → MEDIUM → HIGH by repetition

## For Future Claude Instances

When you're instantiated to work in this repository:

### Startup Sequence

1. Read this file (CLAUDE.md)
2. Check current context (`projects/CURRENT`)
3. Load active project context
4. Check for active plans (`.claude-plan.json`)
5. Execute the user's request

### Decision Framework

**Simple task (<5 min)?** → Execute directly
**Complex task (>15 min)?** → Use `/plan` first
**Switching projects?** → Always use `/switch`
**Completed significant work?** → Run `/learn`

### Key Behaviors

**DO:**
- Use progressive disclosure
- Extract patterns via `/learn` after significant work
- Verify dependencies before executing plan steps
- Follow the small-step rule for plans

**DON'T:**
- Skip the `/learn` ritual
- Create plans for simple tasks
- Manually switch projects (use `/switch`)
- Execute destructive operations
