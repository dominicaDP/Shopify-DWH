---
name: project-switching
description: Context-switch between projects with zero overhead. Loads context, tasks, patterns, and recent activity automatically.
allowed-tools: "Read,Write,Grep,Bash"
---

# Project Switching Skill

## Skill Metadata
- **Version**: 1.0.0
- **Author**: the user's Second Brain Team
- **Category**: context-management
- **Tags**: context-switching, projects, focus, multi-tasking

**Dependencies**:
- **Files**: `projects/CURRENT`, `projects/*/context.md`, `projects/*/tasks.md`, `memory/episodic/**/*.md`

**Input Parameters**:
- `project_name` (string, required): Target project to switch to

**Output**:
- `context_loaded` (object): Project details, tech stack, key context
- `recent_tasks` (array): Last 3 completed tasks
- `open_tasks` (object): Categorized by priority
- `suggested_next_step` (string): AI-recommended next action
- `days_since_last_worked` (number): Time since last active

**Success Metrics**:
- Switch time: < 10 seconds
- Context accuracy: 100%
- Time saved: 5-10 min per switch (vs manual ramp-up)
- Switches per day: 5-10 with zero overhead

---

## Executive Snapshot

**Zero-Overhead Context Switching**: Instantly load complete project context in < 10 seconds. Eliminates "where was I?" mental overhead when switching between multiple projects.

**Core Philosophy**: Context switching is expensive. The brain needs 15-30 minutes to fully load project context manually. This skill does it in 10 seconds with perfect accuracy.

**Quality Standard**: 100% context accuracy, suggested next step always relevant, no manual ramp-up time.

---

## When to Run

**Trigger moments**:
- Starting workday (load today's first project)
- Switching between client projects (multi-client days)
- Returning after break (lunch, meeting, weekend)
- Context shift during day (urgent client request)
- Before standup/meeting (quickly load project state)

**Time investment**: < 10 seconds

**ROI**: 5-10 min saved per switch (25-100 min/day for 5-10 switches)

---

## Workflow Overview (15 Steps)

### 1. Validate Project Exists
**Tool: Read**
```bash
Read("projects/INDEX.md")
```

Check if target project listed in Active Projects.

**If not found**: Show error, list available projects.

### 2. Get Current Timestamp
**Tool: Bash**
```bash
date '+%Y-%m-%d %H:%M:%S'
```

**Purpose**: Track when you worked on each project.

### 3. Save Current Project State
**Tool: Read** + **Edit**

Read `projects/CURRENT` to get current project.

Update current project's context.md:
```markdown
## Latest Update ({timestamp})

*Last worked: {timestamp}*
```

### 4. Switch CURRENT Pointer
**Tool: Write**

Update `projects/CURRENT` file:
```
{new-project-name}
```

**Purpose**: Other commands (/overview, /add-task) default to this project.

### 5. Load New Project Context
**Tool: Read**
```bash
Read("projects/{project-name}/context.md")
```

**Extract**:
- Project type (client/internal/content/etc.)
- Status (active/paused/completed)
- Key stakeholders
- Technical stack
- Latest update

### 6. Load Tasks (Urgent/High/Normal)
**Tool: Read**
```bash
Read("projects/{project-name}/tasks.md")
```

**Parse**:
- Urgent tasks (due today)
- High priority tasks
- Normal priority tasks
- Last 3 completed tasks (to resume context)

### 7. Load Project Patterns
**Tool: Read**
```bash
Read("projects/{project-name}/patterns.md")
```

**Extract**:
- Patterns applied in this project
- New patterns discovered
- Confidence levels

### 8. Find Relevant Semantic Memory
**Tool: Grep**

Search semantic memory for patterns matching this project's domain:

```bash
Grep(
  pattern="{project-domain-keywords}",
  path="memory/semantic/patterns/",
  output_mode="files_with_matches"
)
```

**Example**: Client dashboard project → search for "dashboard", "UI", "auth" patterns.

### 9. Search Past Experiences (Episodic Memory)
**Tool: Grep**

Find recent work sessions on this project:

```bash
Grep(
  pattern="{project-name}",
  path="memory/episodic/",
  output_mode="content"
)
```

**Extract**: Last 3 experiences with this project.

### 10. Calculate Days Since Last Worked
**Parse timestamp** from context.md "Latest Update" section.

```javascript
const lastWorked = new Date(latestUpdate)
const now = new Date()
const daysSince = Math.floor((now - lastWorked) / (1000 * 60 * 60 * 24))

if (daysSince > 7) {
  console.warn(`⚠️ Last worked ${daysSince} days ago - context may be stale`)
}
```

### 11. Identify Suggested Next Step
**AI analysis** based on:
- Urgent tasks (if any → start here)
- Last completed task (what naturally follows?)
- Project context (any blockers or dependencies?)
- Available patterns (can we apply proven solution?)

**Logic**:
```javascript
let suggestedNext

if (urgentTasks.length > 0) {
  suggestedNext = urgentTasks[0]  // most urgent
} else if (lastCompletedTask) {
  suggestedNext = inferNextStepFrom(lastCompletedTask)
} else {
  suggestedNext = highPriorityTasks[0]  // highest priority
}

// Add pattern suggestion if applicable
if (hasMatchingPattern(suggestedNext)) {
  suggestedNext.pattern = findBestPattern(suggestedNext)
}
```

### 12. Format Context Summary
Build dashboard with sections:
- Project overview
- Recent activity (last 3 completed tasks)
- Open tasks by priority
- Suggested next step with rationale
- Relevant patterns to apply
- Days since last worked

### 13. Display Context Dashboard
Output formatted markdown with visual indicators.

### 14. Update Last-Worked Timestamp
**Tool: Edit**

Update new project's context.md:
```markdown
## Latest Update ({timestamp})

*Last worked: {timestamp}*
```

### 15. Ready to Work
User has full context, knows exactly what to do next.

---

## Context Dashboard

**Example output**:

```markdown
🔄 Switched to: client-acme-dashboard

📋 PROJECT OVERVIEW
- **Type**: Client
- **Status**: Active
- **Client**: Acme Corp
- **Tech Stack**: React, PostgreSQL, AWS
- **Last worked**: 2 days ago (2025-01-07)

📝 RECENT ACTIVITY (Last 3 completed)
✅ Implemented user authentication (Jan 7)
✅ Set up database schema (Jan 6)
✅ Initial project setup (Jan 5)

🔥 OPEN TASKS
**URGENT (0)**
*None*

**HIGH PRIORITY (2)**
- [ ] Implement dashboard queries (Est: 4h)
- [ ] Add export functionality (Est: 3h)

**NORMAL (3)**
- [ ] Write API documentation (Est: 2h)
- [ ] Add error logging (Est: 1h)
- [ ] Set up monitoring (Est: 2h)

🎯 SUGGESTED NEXT STEP
**Implement dashboard queries** (HIGH priority, 4h)

*Why this?* Natural progression from authentication setup. User login now works, next step is showing user their data.

💡 **PATTERN TO APPLY**: "PostgreSQL Indexing" (HIGH confidence)
*This pattern will help optimize query performance from the start*

📖 RELEVANT PATTERNS (From Semantic Memory)
- Database Query Optimization (HIGH confidence, 5 examples)
- React State Management (MEDIUM confidence, 3 examples)
- AWS Deployment Process (HIGH confidence, 8 examples)

---

⏱️ **Context loaded in 8 seconds**
🚀 **Ready to work!**
```

---

## Zero Context-Switching Overhead

**The Problem**: Manual context switching takes 15-30 minutes:
1. "What was I doing last?"
2. "What's the next task?"
3. "Where are the docs/notes?"
4. "What patterns can I reuse?"
5. Scrolling through files, git logs, messages...

**The Solution**: Automated context loading in < 10 seconds:
- Project overview: instantly refreshed
- Tasks: prioritized and visible
- Recent work: last 3 completed (to jog memory)
- Suggested next step: AI-recommended
- Relevant patterns: ready to apply

**Impact**: 5-10 switches/day × 10 min saved = **50-100 min/day recovered**

---

## Multi-Project Workflow

**Typical multi-project day**:

```
9:00 AM  - /switch client-a (urgent bug fix)
10:30 AM - /switch internal (feature development)
12:00 PM - Lunch
1:00 PM  - /switch client-b (code review + meeting)
2:30 PM  - /switch client-c (new project kickoff)
4:00 PM  - /switch client-a (deploy bug fix)
5:00 PM  - /switch internal (finish feature)
```

**6 switches/day × 10 min saved = 60 minutes recovered**

**Without this skill**: Each switch takes 15-30 min → 90-180 min lost to context loading

---

## Success Metrics

**Goal**: Make context switching instant and effortless

**Performance Targets**:
- Switch time: < 10 seconds
- Context accuracy: 100% (nothing missed)
- Time saved: 5-10 min per switch
- Suggested next step: 90%+ accurate

**Impact**:
- Higher productivity (less mental overhead)
- Better focus (full context instantly)
- More projects manageable (5-10/day vs 2-3)
- Reduced stress (no "where was I?" anxiety)

---

## Integration with Other Commands

### Morning Start: `/overview` → `/switch first-project`
Overview shows all tasks, switch loads specific project context.

### During Work: `/switch project-name` (as needed)
Quick switches between projects throughout day.

### After Switching: Context loaded, start executing
- `/add-task` - Add new tasks to current project
- `/recall [pattern]` - Load suggested patterns
- `/idea` - Capture ideas while working

### End of Day: Last `/switch` updates timestamp
Tracks when you last worked on each project.

---

## Common Use Cases

### Use Case 1: Multi-Client Consultant
```
Morning: /overview (see all client priorities)
        /switch client-a (most urgent)

Mid-day: /switch client-b (scheduled call)
        /switch client-a (finish urgent work)

Evening: /switch internal (personal project time)
```

**Result**: 4-5 context switches/day, zero overhead, full productivity

---

### Use Case 2: Returning After Weekend
```
Monday morning:
/switch client-project

Dashboard shows:
- Last worked: 3 days ago (Friday)
- Last completed: "Deploy hotfix to production"
- Suggested next: "Monitor production metrics" (HIGH)
- Relevant patterns: "Production Monitoring Setup"
```

**Result**: Instantly back in context, know exactly what to do

---

### Use Case 3: Urgent Context Switch
```
Working on internal feature...

Client Slack: "Production bug, urgent!"

Immediately: /switch client-name

Dashboard shows:
- Recent activity (what was last deployed)
- Open URGENT tasks
- Relevant error patterns from semantic memory
- Suggested next step: "Check production logs"
```

**Result**: Emergency response in 10 seconds, not 15 minutes

---

## Advanced Features

### Stale Context Warning
If project not worked on for 7+ days:
```
⚠️ Last worked 12 days ago - context may be stale

Suggested actions:
1. Review project context.md (may have changed)
2. Check for new tasks (client may have added)
3. Refresh technical context (deployments, changes)
```

### Pattern Recommendations
Automatically suggests HIGH confidence patterns relevant to project:
```
💡 RECOMMENDED PATTERNS FOR THIS PROJECT
- "API Error Handling" (HIGH, 5 examples)
- "PostgreSQL Indexing" (HIGH, 5 examples)
- "React Testing Strategy" (MEDIUM, 3 examples)
```

### Episodic Memory Integration
Shows past experiences with this project:
```
📖 PAST EXPERIENCES (Last 3)
1. Jan 7: "Debugging authentication flow" (2h saved using JWT pattern)
2. Jan 6: "Database schema design" (3h saved using proven schema)
3. Jan 5: "Project setup" (1h saved using setup checklist)
```

---

*Last Updated: 2025-01-09*
*Version: 1.0.0*
*Lines: ~200 (complete skill, no references needed)*
