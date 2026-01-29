---
name: grow
description: Show brain health report with growth metrics, patterns learned, and time savings
allowed-tools: Read, Bash, Grep
---

# Brain Growth Report Command

Usage: `/grow`

Show comprehensive report on how the user's second brain is growing and improving.

## Execution Steps

### Step 1: Count Files in Each Memory Type

**Tool: Bash** (count semantic memory files)
```bash
Bash(command="find memory/semantic/ -type f -name '*.md' | wc -l")
```

**Tool: Bash** (count episodic memory files)
```bash
Bash(command="find memory/episodic/ -type f -name '*.md' | wc -l")
```

**Tool: Bash** (count procedural memory files)
```bash
Bash(command="find memory/procedural/ -type f -name '*.md' | wc -l")
```

**Tool: Bash** (count total memory files)
```bash
Bash(command="find memory/ -type f -name '*.md' | wc -l")
```

**Store as:**
```javascript
const brainSize = {
  semantic: semanticCount,
  episodic: episodicCount,
  procedural: proceduralCount,
  total: totalCount
}
```

### Step 2: Read Pattern Confidence Data

**Tool: Read**
```bash
Read("brain-health/pattern-confidence.md")
```

**Parse content:**
```javascript
// Count patterns by confidence level
const highConfidencePatterns = countSections("## High Confidence")
const mediumConfidencePatterns = countSections("## Medium Confidence")
const lowConfidencePatterns = countSections("## Low Confidence")

const totalPatterns = highConfidencePatterns + mediumConfidencePatterns + lowConfidencePatterns
```

### Step 3: Read Growth Log for Weekly Comparison

**Tool: Read**
```bash
Read("brain-health/growth-log.md")
```

**Extract current week data:**
```javascript
// Find latest week entry
const currentWeek = parseLatestWeek(content)
const lastWeek = parsePreviousWeek(content)

const growth = {
  patternsAdded: currentWeek.patterns - lastWeek.patterns,
  filesAdded: currentWeek.files - lastWeek.files,
  semanticAdded: currentWeek.semantic - lastWeek.semantic,
  episodicAdded: currentWeek.episodic - lastWeek.episodic
}
```

### Step 4: Read Time Savings Metrics

**Tool: Read**
```bash
Read("brain-health/metrics.md")
```

**Extract:**
```javascript
// Parse metrics file for time savings
const timeSavings = {
  thisWeek: parseTimeSaved("this week"),
  total: parseTimeSaved("cumulative"),
  averagePerPattern: parseAverage("per pattern application")
}
```

### Step 5: Count Projects

**Tool: Read**
```bash
Read("projects/INDEX.md")
```

**Parse:**
```javascript
// Count active vs archived projects
const activeProjects = countProjects("## Active")
const archivedProjects = countProjects("## Archived")
```

### Step 6: Analyze Pattern Usage (Top Patterns)

**Tool: Grep** (search for pattern applications in episodic memory)
```bash
Grep(
  pattern="Pattern applied:",
  path="memory/episodic/",
  output_mode="content"
)
```

**Aggregate:**
```javascript
// Count how many times each pattern was applied
const patternUsage = aggregatePatternApplications(grepResults)

// Sort by frequency
const topPatterns = patternUsage.sort((a, b) => b.count - a.count).slice(0, 3)
```

### Step 7: Identify Domain Coverage

**Tool: Grep** (count patterns by domain)
```bash
Grep(
  pattern="dev-patterns",
  path="memory/semantic/patterns/",
  output_mode="count"
)

Grep(
  pattern="content-patterns",
  path="memory/semantic/patterns/",
  output_mode="count"
)

Grep(
  pattern="pm-patterns",
  path="memory/semantic/patterns/",
  output_mode="count"
)
```

**Build domain breakdown:**
```javascript
const domains = {
  dev: devPatternsCount,
  content: contentPatternsCount,
  pm: pmPatternsCount
}
```

### Step 8: Calculate Annual Projections

**Based on current metrics:**
```javascript
const weeksActive = calculateWeeksSinceStart()
const averageTimeSavedPerWeek = timeSavings.total / weeksActive
const projectedAnnualSavings = averageTimeSavedPerWeek * 52
```

### Step 9: Generate Recommendations

**Based on usage patterns:**
```javascript
// Check for opportunities
IF patternApplicationsThisWeek < 3:
  recommend("Run /learn more often after completing work")

IF similarIdeasCount > 3:
  recommend("Consolidate related ideas into one pattern")

IF projectsActive > 5:
  recommend("Consider archiving inactive projects")

IF timeSavingsGrowthRate < 0:
  recommend("Focus on applying existing patterns more consistently")
```

### Step 10: Format and Display Report

**Output structure:**
```markdown
# 🧠 Your Second Brain Health Report

## Brain Size
📊 **Total:** <total> files (+<growth> since last week)

**Breakdown:**
- Semantic memory: <N> files (+<growth>) - What you know
- Episodic memory: <N> files (+<growth>) - What you've done
- Procedural memory: <N> files (+<growth>) - How you do things

**Growth trend:** ↗️ Healthy growth | → Stable | ↘️ Declining

---

## Intelligence Metrics

🎯 **Patterns Identified:** <total> (+<growth> this week)

**Confidence breakdown:**
- 🔥 High confidence (5+ examples): <N> patterns (+<growth>)
- ⚡ Medium confidence (2-4 examples): <N> patterns (+<growth>)
- 💡 Low confidence (1 example): <N> patterns (+<growth>)

**Top patterns by impact:**
1. <pattern1> (HIGH) - Applied <N> times, saved ~<X> hours
2. <pattern2> (MEDIUM) - Applied <N> times, saved ~<X> hours
3. <pattern3> (HIGH) - Applied <N> times, saved ~<X> hours

---

## Domain Coverage

**Strongest domains:**
- 💻 Dev: <N> patterns (high confidence: <N>)
- 📝 Content: <N> patterns (high confidence: <N>)
- 📊 PM: <N> patterns (high confidence: <N>)

**Emerging domains:**
- 🎯 <domain>: <N> patterns (building expertise)

---

## Time Savings

⏱️ **This week:** <X> hours saved
- Dev work: <X> hours (pattern applications)
- Content: <X> hours (template reuse)
- Planning: <X> hours (/overview daily use)

📈 **Cumulative:** <X> hours saved (since Week 1)
- Average per pattern application: <X> minutes
- Most valuable pattern: <pattern> (<X> hours total saved)

**Projected annual savings:** <X> hours (<X> work weeks!)

---

## Usage Statistics

📅 **Active days:** <N> of last 21 days (<X>%)
🔄 **Commands used:** <N> total this week
- /overview: <N> times
- /switch: <N> times
- /learn: <N> times
- /idea: <N> times

🎯 **Projects tracked:** <N> active
- Most active: <project> (<X>% of work)
- <project2>: <X>%
- <project3>: <X>%

---

## Quality Trends

📊 **Code review findings:** Trending <up/down/stable>
⏰ **Time estimate accuracy:** <X>% accurate

---

## Recommendations

<IF recommendations exist:>
### 🎯 Create New Workflow
<recommendation with details>

### 📚 Consolidate Knowledge
<recommendation with details>

### ⭐ Promote Example
<recommendation with details>

### 🔌 Setup Integration
<recommendation with details>

---

## Knowledge Graph Highlights

🕸️ **Most connected pattern:**
"<pattern>" appears in:
- <N> code experiences
- <N> client projects
- <N> content pieces

**Impact:** This insight has influenced <N> subsequent decisions

---

## Next Milestone

🎯 **Current:** <N> patterns identified
🚀 **Next goal:** <N+X> patterns (<X> away)

**At <goal>, you'll unlock:**
- Expert-level domain knowledge
- Predictable time savings (<X>+ hr/month)
- Pattern-driven workflow

**Estimated time to milestone:** <X> weeks (current pace)

---

## Brain Health: ✅ EXCELLENT | ⚠️ GOOD | ❌ NEEDS ATTENTION

**Indicators:**
- ✅ Consistent usage
- ✅ Regular learning extraction
- ✅ Growing pattern confidence
- ✅ Measurable time savings
- ✅ Cross-project learning

**Keep doing:**
- Daily /overview
- /learn after significant work
- Multi-project switching

**Consider adding:**
- <suggestion 1>
- <suggestion 2>

---

💡 **Remember:** The more you use the system, the smarter it gets!

Run /overview to see today's priorities
Run /learn to extract patterns from recent work
```

## Example Execution

**Input:**
```
/grow
```

**Tool calls sequence:**
```bash
1. Bash(command="find memory/semantic/ -type f -name '*.md' | wc -l")
   → Result: 28

2. Bash(command="find memory/episodic/ -type f -name '*.md' | wc -l")
   → Result: 32

3. Bash(command="find memory/procedural/ -type f -name '*.md' | wc -l")
   → Result: 7

4. Bash(command="find memory/ -type f -name '*.md' | wc -l")
   → Result: 67

5. Read("brain-health/pattern-confidence.md")
   → Parse: 6 high, 8 medium, 4 low confidence patterns

6. Read("brain-health/growth-log.md")
   → Parse: Week 3 data (+3 patterns, +12 files since Week 2)

7. Read("brain-health/metrics.md")
   → Parse: 3.5 hours saved this week, 12.5 hours total

8. Read("projects/INDEX.md")
   → Parse: 5 active projects, 2 archived

9. Grep(pattern="Pattern applied:", path="memory/episodic/", output_mode="content")
   → Find: 23 pattern applications this week

10. Grep(pattern="dev-patterns", path="memory/semantic/patterns/", output_mode="count")
    → Result: 10

11. Grep(pattern="content-patterns", path="memory/semantic/patterns/", output_mode="count")
    → Result: 5

12. Grep(pattern="pm-patterns", path="memory/semantic/patterns/", output_mode="count")
    → Result: 3

13. Calculate projections:
    - Weeks active: 3
    - Avg per week: 4.17 hours
    - Annual projection: 217 hours
```

**Output:**
```
# 🧠 Your Second Brain Health Report

## Brain Size
📊 **Total:** 67 files (+12 since last week)

**Breakdown:**
- Semantic memory: 28 files (+5) - What you know
- Episodic memory: 32 files (+6) - What you've done
- Procedural memory: 7 files (+1) - How you do things

**Growth trend:** ↗️ Healthy growth (steady increase)

---

## Intelligence Metrics

🎯 **Patterns Identified:** 18 total (+3 this week)

**Confidence breakdown:**
- 🔥 High confidence (5+ examples): 6 patterns (+1)
- ⚡ Medium confidence (2-4 examples): 8 patterns (+2)
- 💡 Low confidence (1 example): 4 patterns (→)

**Top patterns by impact:**
1. PostgreSQL indexing strategy (HIGH) - Applied 12 times, saved ~6 hours
2. JWT refresh tokens for mobile (HIGH) - Applied 8 times, saved ~4 hours
3. Error logging with user context (MEDIUM) - Applied 5 times, saved ~2 hours

---

## Domain Coverage

**Strongest domains:**
- 💻 Dev: 10 patterns (high confidence: 4)
- 📝 Content: 5 patterns (high confidence: 2)
- 📊 PM: 3 patterns (high confidence: 0 - needs more data)

**Emerging domains:**
- 🎯 Client management: 2 patterns (building expertise)
- 🔧 DevOps: 1 pattern (just started tracking)

---

## Time Savings

⏱️ **This week:** 3.5 hours saved
- Dev work: 2 hours (pattern applications)
- Content: 1 hour (template reuse)
- Planning: 0.5 hours (/overview daily use)

📈 **Cumulative:** 12.5 hours saved (since Week 1)
- Average per pattern application: 35 minutes
- Most valuable pattern: PostgreSQL indexing (6 hours total saved)

**Projected annual savings:** 217 hours (5.4 work weeks!)

---

## Usage Statistics

📅 **Active days:** 18 of last 21 days (86%)
🔄 **Commands used:** 87 total this week
- /overview: 18 times (every morning ✅)
- /switch: 24 times (multi-project work)
- /learn: 6 times (good! keep it up)
- /idea: 12 times (idea capture working)

🎯 **Projects tracked:** 5 active
- Most active: client-a (35% of work)
- client-b: 25%
- internal-product: 20%
- content-2025-q1: 15%
- learning-projects: 5%

---

## Recommendations

### 🎯 Create New Workflow
You've done "competitive positioning" manually 4 times.
Consider creating: `skills/competitive-positioning/`
**Estimated benefit:** Save 1 hour per occurrence

### 📚 Consolidate Knowledge
You have 3 separate learnings about "pricing objections."
Consider merging into one pattern in: `memory/semantic/patterns/pm-patterns.md`
**Benefit:** Easier to recall and apply

### ⭐ Promote Example
Your recent one-pager for Acme Corp is excellent (9.5/10 quality).
Add to: `memory/examples/winning-one-pagers/`
**Benefit:** Future one-pagers will match this quality

---

## Knowledge Graph Highlights

🕸️ **Most connected pattern:**
"PostgreSQL indexing" appears in:
- 12 code experiences
- 3 client projects
- 2 content pieces (best practices blog)

**Impact:** This insight has influenced 17 subsequent decisions

---

## Next Milestone

🎯 **Current:** 18 patterns identified
🚀 **Next goal:** 25 patterns (7 away)

**At 25 patterns, you'll unlock:**
- Expert-level domain knowledge
- Predictable time savings (15+ hr/month)
- Pattern-driven workflow (less thinking, more doing)

**Estimated time to milestone:** 3-4 weeks (current pace)

---

## Brain Health: ✅ EXCELLENT

**Indicators:**
- ✅ Consistent usage (daily /overview)
- ✅ Regular learning extraction (6 times this week)
- ✅ Growing pattern confidence (6 high-confidence patterns)
- ✅ Measurable time savings (3.5 hr this week)
- ✅ Cross-project learning (patterns applied everywhere)

**Keep doing:**
- Daily /overview (saves 30 min/day)
- /learn after significant work (compounds knowledge)
- Multi-project switching (prevents context loss)

**Consider adding:**
- Voice capture integration (Week 3 goal)
- Fibery API sync (Week 2 goal)
- Weekly pattern review (every Friday)

---

💡 **Remember:** The more you use the system, the smarter it gets!

Run /overview to see today's priorities
Run /learn to extract patterns from recent work
```

## Success Metrics

**Goal:** Compound knowledge - make each project easier

**Metrics:**
- Report generation time: < 5 seconds
- Accuracy: 100% (based on actual files/data)
- Actionable insights: 3-5 recommendations per run

## When to Run /grow

**Weekly recommended:**
- Every Friday afternoon
- Review week's progress
- Celebrate wins
- Plan next week improvements

**Monthly recommended:**
- First day of new month
- Review cumulative progress
- Measure against 6-month goals
- Adjust strategy if needed

**Ad-hoc:**
- When feeling like "is this working?"
- Before meetings with boss (show ROI)
- After major milestones
- When deciding what to optimize next

## Required Files

**Structure:**
```
brain-health/
├── pattern-confidence.md    # Pattern confidence levels
├── growth-log.md            # Weekly growth tracking
└── metrics.md               # Time savings and other KPIs

memory/
├── semantic/
├── episodic/
└── procedural/

projects/
└── INDEX.md
```

## Edge Cases

### First Week (No Historical Data)

**If no previous week data:**
```markdown
📊 **Total:** 15 files (first week - no comparison)

**Note:** Run /grow next week to see growth trends!
```

### No Patterns Yet

**If zero patterns:**
```markdown
💡 **Get started:**
1. Complete work on a project
2. Run /learn to extract first pattern
3. Run /grow next week to see progress
```

## Notes for the user

**Use for motivation:**
- See tangible progress (patterns growing)
- Measure real time savings (not guesses)
- Celebrate milestones (25, 50, 100 patterns)

**Use for ROI proof:**
- Show boss: "Saved 217 hours this year"
- Justify time investment in setup
- Demonstrate system value

**Use for optimization:**
- Identify which patterns save most time
- See which domains need more patterns
- Know when to build integrations

**The magic:**
- Week 1: "Am I doing this right?" (feels manual)
- Week 4: "Oh, it's working!" (seeing savings)
- Week 12: "Can't imagine working without it" (addicted to growth)
