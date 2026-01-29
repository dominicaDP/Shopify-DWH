---
name: idea-capture
description: Quick idea capture with automatic categorization and intelligent linking to related projects and patterns
allowed-tools: "Read,Write,Edit,Bash"
---

# Idea Capture Skill

## Skill Metadata
- **Version**: 1.0.0
- **Author**: the user's Second Brain Team
- **Category**: knowledge-capture
- **Tags**: ideas, capture, categorization, quick-entry, inbox-zero

**Dependencies**:
- **Files**: `memory/semantic/ideas/*.md`, `projects/*/context.md`, `brain-health/metrics.md`

**Input Parameters**:
- `idea_text` (string, required): The idea to capture

**Output**:
- `category` (string): product | content | business | tech | client | process
- `priority` (string): high | medium | low
- `file_path` (string): Where idea was saved
- `related_project` (string, optional): Linked project if detected

**Success Metrics**:
- Capture time: < 30 seconds per idea
- Ideas captured: 10-15/week (vs 3-5 before)
- Conversion rate: 30%+ ideas → tasks
- Lost ideas: 0

---

## Executive Snapshot

**Quick Capture System**: Captures ideas in < 30 seconds with automatic categorization (product/content/business/tech/client/process). Saves to appropriate memory location and links to related projects.

**Core Philosophy**: Lower the barrier for idea capture to zero. Don't filter at capture time - capture everything, review weekly.

**Quality Standard**: Every idea gets a timestamp, category, priority, and optional project link. Review weekly to convert high-value ideas to tasks.

---

## When to Run

**Trigger moments**:
- Any time an idea pops up (don't lose it!)
- During meetings (quick capture without disrupting flow)
- Before bed (capture for tomorrow)
- Reading/research (save insights immediately)

**Time investment**: < 30 seconds per idea

**ROI**: 45 min/week saved (vs manual note-taking + organizing)

---

## Workflow Overview (8 Steps)

### 1. Capture Text + Timestamp
User provides idea text. Get current timestamp automatically.

### 2. Categorize Idea (AI-Powered)
Analyze text for keywords. Determine category: product/content/business/tech/client/process/personal.

### 3. Determine Priority
Scan for urgency indicators (urgent/critical/asap → HIGH, nice-to-have/someday → LOW, else MEDIUM).

### 4. Check for Related Project
Extract project references from idea text. Link if mentioned.

### 5. Generate Metadata
Create idea title (first sentence), "Why This Matters" context, "Next Steps" suggestions.

### 6. Save to Category File
Append to appropriate `memory/semantic/ideas/<category>-ideas.md` file with metadata.

### 7. Link to Project (If Applicable)
If project detected, add reference in `projects/<project>/ideas.md`.

### 8. Show Confirmation
Display saved location, category, priority, and suggest review frequency.

📖 **For detailed execution with tool calls**: `Read {baseDir}/references/capture-workflow.md`

---

## Categorization Logic

| Category | Keywords | File Location |
|----------|----------|---------------|
| **Product** | feature, UI, dashboard, user, product | product-ideas.md |
| **Content** | blog, post, article, video, social | content-ideas.md |
| **Business** | pricing, revenue, strategy, model | business-ideas.md |
| **Tech** | refactor, code, technical, architecture | tech-ideas.md |
| **Client** | client, project-specific names | client-ideas.md |
| **Process** | process, automation, workflow, efficiency | process-ideas.md |

**Priority Determination**:
- **HIGH**: urgent, critical, asap, client-requested
- **LOW**: nice-to-have, someday, maybe
- **MEDIUM**: everything else

📖 **For categorization rules**: `Read {baseDir}/references/categorization-logic.md`

---

## Idea File Structure

```markdown
## [IDEA TITLE] (Added: 2025-01-09)

**Category:** Product  
**Priority:** HIGH  
**Related Project:** client-a

### Why This Matters
AI-generated context explaining relevance and potential impact.

### Next Steps
1. Research similar features
2. Validate with users
3. Create spec document

### Original Note
[User's raw idea text]

---
```

---

## Success Metrics

**Goal**: Never lose an idea again

**Weekly Targets**:
- 10-15 ideas captured (vs 3-5 manually)
- < 30 seconds average capture time
- 30%+ conversion rate (ideas → tasks)
- 100% capture rate (0 lost ideas)

**Review Cadence**:
- Weekly: Review all ideas, convert high-priority to tasks
- Monthly: Archive completed/obsolete ideas

---

## Integration with Other Commands

### Capture: `/idea`
Quick capture without overthinking.

### Review: Read idea files
Weekly review session to prioritize and convert.

### Convert: `/add-task [project] [idea]`
Turn high-value ideas into actionable tasks.

### Track: `/grow`
See idea capture trends and conversion rates.

---

## Idea Review Workflow

**Weekly Review** (Friday, 30 min):
1. Read all idea files
2. Sort by priority (HIGH first)
3. For HIGH priority:
   - Convert to task: `/add-task [project] [idea]`
   - Archive if completed
   - Keep if still relevant
4. For MEDIUM priority:
   - Promote to HIGH if now urgent
   - Archive if no longer relevant
5. For LOW priority:
   - Keep for inspiration
   - Archive after 3 months if not promoted

---

## Progressive Disclosure

**Core operational workflow**: This file (~200 lines)

**Detailed execution**:
- 📖 `Read {baseDir}/references/capture-workflow.md` - Full 8-step capture with tool calls
- 📖 `Read {baseDir}/references/categorization-logic.md` - AI categorization rules and keyword matching

**Best practices**:
- 📖 `Read {baseDir}/references/idea-review-guide.md` - Weekly review process and conversion strategies

---

*Last Updated: 2025-01-09*
*Version: 1.0.0*
*Lines: ~200 (entry point) + reference files (on-demand)*
