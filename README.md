# Second Brain

Your AI-powered second brain that compounds knowledge across all your work.

## What This Is

A knowledge management system for Claude Code that:
- **Preserves context** across conversations (no more re-explaining)
- **Extracts patterns** from your work automatically
- **Compounds knowledge** - each task makes future tasks easier
- **Manages projects** with zero context-switching overhead

## Quick Start

### 1. Install Prerequisites

```bash
# Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Verify
claude --version
```

### 2. Clone/Copy This Repository

```bash
git clone [your-repo-url] second-brain
cd second-brain
```

### 3. Customize for Your Use Case

Edit `CLAUDE.md` → **User Profile** section with:
- Your role and context
- Your tech stack
- Your pain points
- Your goals

### 4. Start Using

```bash
# Open Claude Code in this directory
claude

# Load a project
/switch my-project

# Get your daily overview
/overview
```

## Core Concepts

### The Vibe Engineering Workflow

```
PLAN → DELEGATE → ASSESS → CODIFY
  ↓         ↓         ↓        ↓
/plan    /work    /review   /learn
```

Each unit of work makes subsequent work easier through pattern extraction.

### Memory Types

| Type | Purpose | Location |
|------|---------|----------|
| **Semantic** | Facts, patterns, tech decisions | `memory/semantic/` |
| **Episodic** | Completed work records | `memory/episodic/` |
| **Procedural** | Workflows and processes | `memory/procedural/` |

### Projects

Each project contains:
- `context.md` - Tech stack, architecture, constraints
- `tasks.md` - Prioritized task list
- `patterns.md` - Project-specific patterns
- `notes.md` - Decisions, meeting notes

## Daily Workflow

### Morning
```bash
/overview              # See all urgent tasks
/switch [project]      # Load project context
```

### During Work
```bash
/plan [complex task]   # Break down big tasks
/step                  # Execute incrementally
```

### End of Day
```bash
/learn                 # Extract patterns from today's work
```

## Essential Commands

| Command | Purpose |
|---------|---------|
| `/switch [project]` | Load project context instantly |
| `/overview` | Morning dashboard of all tasks |
| `/plan [goal]` | Break complex tasks into steps |
| `/step` | Execute next planned step |
| `/learn` | Extract patterns from work |
| `/recall [topic]` | Search all memories |
| `/grow` | Brain health metrics |
| `/idea [text]` | Quick idea capture |
| `/add-task [desc]` | Add task to project |

## Repository Structure

```
.claude/
├── commands/          # Slash commands (pre-built)
├── skills/            # Executable workflows
├── agents/            # Specialized AI agents
└── hooks/             # Event hooks

memory/
├── semantic/          # What you know
├── episodic/          # What you've done
└── procedural/        # How you do things

projects/
├── INDEX.md           # Project registry
├── _template/         # New project template
└── [your-projects]/   # Your actual projects

settings.local.json    # Permissions & safety
CLAUDE.md              # System instructions (CUSTOMIZE THIS)
```

## Customization Checklist

Before using, update these files:

- [ ] **CLAUDE.md** → User Profile section (required)
- [ ] **settings.local.json** → Add tools for your tech stack
- [ ] **projects/** → Create your first project
- [ ] **memory/semantic/tech/** → Document your architecture

## Safety Features

Built-in protections:
- Blocks destructive operations (`rm -rf`, etc.)
- Restricts network access to documentation sites
- Prevents privilege escalation
- Incremental checkpoints during complex tasks

## Key Documents

- **CLAUDE.md** - Complete system documentation
- **ONBOARDING.md** - Setup guide for new users
- **settings.local.json** - Safety permissions

## Getting Help

- First time? → Read `ONBOARDING.md`
- Complex feature? → Use `/plan [goal]` → `/step`
- Ending session? → Run `/learn`
- Check progress → Run `/grow`
