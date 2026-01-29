---
name: project-creation
description: Create new project with standard structure (context, tasks, patterns, notes) and automatic indexing
allowed-tools: "Read,Write,Bash"
---

# Project Creation Skill

## Skill Metadata
- **Version**: 1.0.0
- **Author**: the user's Second Brain Team
- **Category**: project-management
- **Tags**: projects, setup, scaffolding, organization

**Dependencies**:
- **Files**: `projects/INDEX.md`, `projects/CURRENT`

**Input Parameters**:
- `project_name` (string, required): Name of new project
- `project_type` (enum, optional): client | internal | content | research | personal

**Output**:
- `project_directory` (string): Created directory path
- `files_created` (array): List of initialized files

**Success Metrics**:
- Creation time: < 3 minutes (vs 10-15 min manual)
- Structure compliance: 100% (all required files present)
- Abandonment rate: < 10% (projects actually used)

---

## Executive Snapshot

**Automated Project Scaffolding**: Creates standardized project structure in < 3 minutes. Ensures every project starts with context tracking, task management, pattern accumulation, and notes organization.

**Core Philosophy**: Consistent structure = faster context loading. Every project should have the same predictable layout for efficient /switch and /recall operations.

**Quality Standard**: 100% structure compliance, all files initialized with templates, automatically indexed for discovery.

---

## When to Run

**Trigger moments**:
- New client engagement (discovery call scheduled)
- New internal product/feature (starting development)
- New content initiative (blog series, course, video project)
- R&D experiment (trying new technology)
- Personal project (side hustle, learning project)

**Time investment**: 2-3 minutes

**ROI**: 10-15 min saved vs manual setup, guaranteed consistency

---

## Workflow Overview (11 Steps)

### 1. Sanitize Project Name
Convert to lowercase, replace spaces with hyphens, remove special chars.

**Example**: "Client A - Dashboard" → `client-a-dashboard`

### 2. Check if Project Exists
Read `projects/INDEX.md` to prevent duplicates.

**If exists**: Warn user, offer to /switch instead.

### 3. Get Current Date
Timestamp for "Created" metadata.

**Tool: Bash**
```bash
date '+%Y-%m-%d'
```

### 4. Create Project Directory
**Tool: Bash**
```bash
mkdir -p projects/{project-name}
```

### 5. Create context.md
**Tool: Write**

Initialize with template:
```markdown
# {Project Name} - Context

**Created**: {date}
**Type**: {client | internal | content | research | personal}
**Status**: Active

## Project Overview

*Brief description of project goals and scope.*

## Key Stakeholders

- **Client/Owner**: [Name]
- **Point of Contact**: [Email/Slack]
- **Timeline**: [Start date - End date]

## Technical Context

- **Stack**: [Technologies used]
- **Repository**: [GitHub URL]
- **Deployment**: [Production URL]

## Latest Update

*Most recent work and current state.*
```

### 6. Create tasks.md
**Tool: Write**

Initialize with priority sections:
```markdown
# {Project Name} - Tasks

## Urgent (Due Today)

*No urgent tasks yet*

## High Priority

- [ ] Initial project setup

## Normal Priority

*No normal priority tasks yet*

## Low Priority / Backlog

*No backlog items yet*

## Completed

*Completed tasks will be moved here*
```

### 7. Create patterns.md
**Tool: Write**

Initialize with pattern tracking template:
```markdown
# {Project Name} - Patterns Applied

Track which patterns from semantic memory were used in this project.

## Applied Patterns

*No patterns applied yet. Run /recall to find relevant patterns.*

## New Patterns Discovered

*Patterns discovered during this project that should be added to semantic memory.*
```

### 8. Create notes.md
**Tool: Write**

Initialize with notes template:
```markdown
# {Project Name} - Notes

Quick capture for ideas, decisions, blockers.

## Meeting Notes

*Add notes from client/team meetings here*

## Technical Notes

*Code decisions, architecture choices, gotchas*

## Ideas

*Quick captures from /idea specific to this project*

## Blockers

*Current blockers and dependencies*
```

### 9. Update projects/INDEX.md
**Tool: Edit**

Add to "Active Projects" section:
```markdown
## Active Projects

- **{project-name}**: {One-line description} (Created: {date})
```

### 10. Set as CURRENT Project
**Tool: Write**

Update `projects/CURRENT` file:
```
{project-name}
```

**Purpose**: Commands like /overview know which project to default to.

### 11. Show Confirmation + Next Steps
Display success message:
```markdown
✅ Project created: {project-name}

📁 **Directory**: projects/{project-name}/
📄 **Files created**:
- context.md (project overview)
- tasks.md (task tracking)
- patterns.md (pattern application log)
- notes.md (quick capture)

📍 **Status**: Active + set as CURRENT project

🎯 **Next Steps**:
1. /switch {project-name} - Load full context
2. Update context.md with project details
3. /add-task {project-name} "Initial setup tasks"
4. /recall [topic] - Find relevant patterns to apply
```

---

## Standard Project Structure

Every project follows this layout:

```
projects/{project-name}/
├── context.md          # Project overview, stakeholders, tech stack
├── tasks.md            # Task queue with priority sections
├── patterns.md         # Patterns applied + new discoveries
└── notes.md            # Meeting notes, decisions, ideas, blockers
```

**Why this structure?**
- **context.md**: Rapid onboarding when /switch
- **tasks.md**: Clear priorities, no hunting for "what's next?"
- **patterns.md**: Track proven solutions used in this project
- **notes.md**: Quick capture without disrupting flow

---

## Project Types

### Client Projects
**Type**: `client`

**Context template includes**:
- Client name and contact
- Project scope and deliverables
- Timeline and milestones
- Billing details (if applicable)

**Example**: `client-acme-dashboard`

---

### Internal Projects
**Type**: `internal`

**Context template includes**:
- Product/feature description
- Team members involved
- Technical requirements
- Launch goals

**Example**: `internal-second-brain`

---

### Content Projects
**Type**: `content`

**Context template includes**:
- Content type (blog series, course, videos)
- Target audience
- Publishing schedule
- Promotion strategy

**Example**: `content-ai-patterns-course`

---

### Research Projects
**Type**: `research`

**Context template includes**:
- Research question
- Hypothesis
- Experiments planned
- Success criteria

**Example**: `research-vector-databases`

---

### Personal Projects
**Type**: `personal`

**Context template includes**:
- Personal goals
- Learning objectives
- Time commitment
- Fun factor 🎉

**Example**: `personal-side-hustle`

---

## Success Metrics

**Goal**: Make project creation effortless and consistent

**Creation Targets**:
- Time: < 3 minutes (vs 10-15 manual)
- Structure: 100% compliance (all files present)
- Abandonment: < 10% (projects actually used)

**Impact**:
- Faster context switching (/switch loads predictably)
- Better pattern tracking (patterns.md captures learning)
- Reduced setup overhead (templates vs blank files)

---

## Integration with Other Commands

### After Creation: `/switch {project}`
Load full context for new project, start working.

### Add Tasks: `/add-task {project} "task description"`
Populate tasks.md with initial work.

### Find Patterns: `/recall [topic]`
Search semantic memory for relevant patterns to apply.

### Capture Ideas: `/idea "project-specific idea"`
Quick capture during work, later review in notes.md.

---

## Common Use Cases

### Use Case 1: New Client Onboarding
```
1. /new-project client-name
2. Update context.md with client details
3. /add-task client-name "Discovery call - understand requirements"
4. /add-task client-name "Technical assessment"
5. /add-task client-name "Create proposal"
6. /switch client-name (start work)
```

### Use Case 2: Internal Feature Development
```
1. /new-project internal-feature-name
2. Update context.md with feature requirements
3. /add-task internal-feature-name "Design architecture"
4. /add-task internal-feature-name "Implement backend"
5. /add-task internal-feature-name "Write tests"
6. /recall [related-pattern] (find proven solutions)
```

### Use Case 3: Content Series
```
1. /new-project content-series-name
2. Update context.md with outline and schedule
3. /add-task content-series-name "Research episode 1"
4. /add-task content-series-name "Write script"
5. /add-task content-series-name "Record and edit"
```

---

*Last Updated: 2025-01-09*
*Version: 1.0.0*
*Lines: ~200 (complete skill, no references needed for simple scaffolding)*
