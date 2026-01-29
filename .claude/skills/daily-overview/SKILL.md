---
name: daily-overview
description: Generate daily planning dashboard with prioritized tasks across all projects, time estimates, and pattern suggestions
allowed-tools: "Read,Grep,Bash"
---

# Daily Overview Skill

## Skill Metadata
- **Version**: 1.0.0
- **Author**: the user's Second Brain Team
- **Category**: daily-planning
- **Tags**: overview, dashboard, planning, prioritization, daily-routine

**Dependencies**:
- **Files**: `projects/INDEX.md`, `projects/*/tasks.md`, `memory/semantic/patterns/*.md`

**Input Parameters**:
- `date` (string, optional): Defaults to today

**Output**:
- `urgent_tasks` (array): Tasks due today/overdue
- `high_priority_tasks` (array): Important tasks to tackle
- `time_estimate_total` (number): Total hours of planned work
- `suggested_patterns` (array): Patterns to apply today

**Success Metrics**:
- Generation time: < 10 seconds
- Accuracy: 95%+ task prioritization correct
- Time saved: 5-10 min vs manual planning
- Daily usage: 80%+ weekday adoption

---

## Executive Snapshot

**Automated Morning Planning Dashboard**: Aggregates tasks across all projects, calculates time estimates, identifies urgent work, suggests patterns to apply. Replaces manual planning with < 10 second automated dashboard.

**Core Philosophy**: Start every day with clarity. Know what's urgent, what's important, and what patterns to apply before opening your editor.

**Quality Standard**: 95%+ accurate prioritization, realistic time estimates, actionable next steps. Generated in < 10 seconds.

---

## When to Run

**Trigger moments**:
- Every morning (daily ritual before work)
- After `/switch` to see project status
- Before client meetings (see their project status)
- Mid-day check-in (re-prioritize if needed)

**Time investment**: < 10 seconds to generate

**ROI**: 30-60 min/day saved (clear priorities, no decision fatigue)

---

## Workflow Overview (12 Steps)

### 1. Get Current Date + Day of Week
Timestamp for context and weekend awareness.

### 2. Read All Active Projects
Load `projects/INDEX.md` to identify active projects.

### 3. Read All Project Tasks
Grep each project's tasks.md for open tasks.

### 4. Categorize by Priority
Group tasks: URGENT (due today), HIGH, NORMAL, LOW.

### 5. Calculate Time Estimates
Sum estimated time for planned work (capacity check).

### 6. Identify Urgent Tasks
Flag tasks with "today", "urgent", or past due dates.

### 7. Suggest High-Priority Tasks
Top 3-5 most important tasks to focus on today.

### 8. Load Relevant Patterns
Match today's tasks to available HIGH confidence patterns.

### 9. Check Recent Brain Growth
Show patterns learned this week (motivation).

### 10. Generate Recommendations
Suggest which tasks to tackle first based on priority + time available.

### 11. Format Dashboard
Create visual dashboard with sections: Urgent, High Priority, Suggested Patterns, Brain Growth.

### 12. Display Priorities
Output formatted dashboard with clear next actions.

📖 **For detailed execution with tool calls**: `Read {baseDir}/references/overview-workflow.md`

---

## Dashboard Structure

```
📅 Daily Overview - Friday, January 9, 2025

🔥 URGENT (Due Today)
1. [client-a] Fix production payment bug (Est: 2h)
2. [internal] Deploy staging environment (Est: 1h)

⭐ HIGH PRIORITY (Important)
1. [client-b] Implement dashboard auth (Est: 4h)
2. [client-a] Complete API integration (Est: 3h)
3. [internal] Update documentation (Est: 1h)

💡 SUGGESTED PATTERNS TO APPLY TODAY
- "PostgreSQL Indexing" (HIGH confidence) - client-b dashboard queries
- "Client Discovery Process" (MEDIUM) - client-c kickoff call at 2pm

📊 CAPACITY CHECK
- Total planned: 11 hours
- Available: 6-7 hours (realistic workday)
- ⚠️ OVER-CAPACITY: Defer 4-5 hours of NORMAL priority work

🧠 THIS WEEK'S BRAIN GROWTH
- 2 patterns reinforced (JWT Auth, API Design)
- 3.5 hours saved from pattern application
- 1 new HIGH confidence pattern achieved

🎯 RECOMMENDED FOCUS TODAY
1. Fix client-a production bug (URGENT, 2h)
2. Deploy staging (URGENT, 1h)
3. Client-b dashboard auth (HIGH, 4h) - APPLY "PostgreSQL Indexing" pattern

Total: 7h (realistic capacity)
Deferred: 4h to next week
```

---

## Time Estimation

**Default Estimates** (if not specified in task):
- Bug fixes: 2 hours
- Features: 4 hours
- Deployments: 1 hour
- Documentation: 1 hour
- Meetings: As scheduled

**Capacity Rules**:
- **Realistic day**: 6-7 focused hours
- **Over-capacity**: > 8 hours planned
- **Under-capacity**: < 4 hours (add stretch tasks)

📖 **For estimation logic**: `Read {baseDir}/references/time-estimation.md`

---

## Success Metrics

**Goal**: Start every day with perfect clarity

**Daily Targets**:
- Generated in < 10 seconds
- 95%+ prioritization accuracy
- Realistic time estimates (within 20% of actual)
- 80%+ weekday usage (become daily habit)

**Impact**:
- 30-60 min/day saved on planning
- Reduced decision fatigue
- Higher task completion rate
- Better capacity management

---

## Integration with Other Commands

### Morning Routine: `/overview`
First command of the day, sets priorities.

### Context Loading: `/switch [project]`
After overview, switch to first project to tackle.

### Pattern Application: See suggestions → `/recall [pattern]`
Overview suggests patterns, recall loads details.

### Evening Review: `/grow`
Weekly growth metrics shown in overview motivate daily progress.

---

## Progressive Disclosure

**Core operational workflow**: This file (~200 lines)

**Detailed execution**:
- 📖 `Read {baseDir}/references/overview-workflow.md` - Full 12-step dashboard generation
- 📖 `Read {baseDir}/references/time-estimation.md` - Estimation rules and capacity management

**Optimization**:
- 📖 `Read {baseDir}/references/prioritization-algorithm.md` - How tasks are ranked and suggested

---

*Last Updated: 2025-01-09*
*Version: 1.0.0*
*Lines: ~200 (entry point) + reference files (on-demand)*
