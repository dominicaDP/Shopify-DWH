---
name: brain-health-reporting
description: Comprehensive brain growth report with metrics, patterns learned, time savings, and next milestones
allowed-tools: "Read,Bash,Grep"
---

# Brain Health Reporting Skill

## Skill Metadata
- **Version**: 1.0.0
- **Author**: the user's Second Brain Team
- **Category**: analytics
- **Tags**: metrics, growth, reporting, roi, motivation

**Dependencies**:
- **Files**: `brain-health/pattern-confidence.md`, `brain-health/growth-log.md`, `brain-health/metrics.md`, `memory/**/*.md`, `projects/INDEX.md`

**Input Parameters**:
- `report_period` (enum, optional): week | month | all-time

**Output**:
- `brain_size` (object): File counts by memory type
- `intelligence_metrics` (object): Patterns by confidence level
- `time_savings` (object): Weekly and cumulative savings
- `top_patterns` (array): Most valuable patterns
- `recommendations` (array): Suggested next actions
- `next_milestone` (object): Goals and ETA

**Success Metrics**:
- Generation time: < 5 seconds
- Accuracy: 100% (based on actual files/data)
- Actionable insights: 3-5 recommendations per run
- Weekly usage: 100% (Friday ritual)

---

## Executive Snapshot

**Motivational Growth Dashboard**: Comprehensive analytics showing brain growth, pattern development, time savings, and ROI. Generates weekly/monthly reports in < 5 seconds with 100% accuracy.

**Core Philosophy**: You can't manage what you don't measure. This skill makes growth visible, quantifiable, and motivating. Proof that your second brain is working.

**Quality Standard**: Accurate metrics, actionable insights, motivational tone. 3-5 concrete recommendations per report.

---

## When to Run

**Trigger moments**:
- Every Friday afternoon (weekly growth review)
- First of the month (monthly retrospective)
- When feeling "is this working?" (validation needed)
- Before 1-on-1 with boss (show productivity ROI)
- After major milestone (celebrate progress)

**Time investment**: < 5 seconds

**ROI**: 10-20 min/week (vs manual tracking), plus motivation boost

---

## Workflow Overview (13 Steps)

### 1. Count Files by Memory Type
**Tool: Bash**
```bash
find memory/semantic/patterns/ -name "*.md" | wc -l
find memory/episodic/ -name "*.md" | wc -l
find memory/procedural/ -name "*.md" | wc -l
```

**Output**: Brain size metrics

### 2. Read Pattern Confidence Data
**Tool: Read**
```bash
Read("brain-health/pattern-confidence.md")
```

**Parse**: Count patterns by confidence level (LOW/MEDIUM/HIGH)

### 3. Read Growth Log
**Tool: Read**
```bash
Read("brain-health/growth-log.md")
```

**Extract**: Weekly/monthly growth entries

### 4. Read Time Savings Metrics
**Tool: Read**
```bash
Read("brain-health/metrics.md")
```

**Calculate**:
- Time saved this week
- Time saved this month
- Cumulative time saved
- Annualized projection

### 5. Count Projects
**Tool: Read**
```bash
Read("projects/INDEX.md")
```

**Parse**: Active, paused, and completed projects

### 6. Analyze Pattern Usage
**Tool: Grep**

Search episodic memory for pattern applications:
```bash
Grep(
  pattern="Applied pattern:",
  path="memory/episodic/",
  output_mode="count"
)
```

**Calculate**: Usage frequency per pattern

### 7. Identify Domain Coverage
**Tool: Read**

Read all pattern files, extract domains:
- Development patterns (dev-patterns.md)
- Client patterns (client-patterns.md)
- Content patterns (content-patterns.md)
- Process patterns (process-patterns.md)

**Output**: Which domains are well-covered, which need growth

### 8. Calculate Annual Projections
**Math**:
```javascript
// Weekly time saved → annual projection
const weeklyTimeSaved = sumTimeSavingsThisWeek()
const annualProjection = weeklyTimeSaved * 52

// Pattern growth rate → annual projection
const patternsAddedThisMonth = countNewPatterns()
const annualPatternGrowth = patternsAddedThisMonth * 12
```

### 9. Generate Recommendations
**AI analysis** based on:
- Low confidence patterns (promote to MEDIUM/HIGH)
- Under-utilized patterns (apply more often)
- Domain gaps (missing pattern categories)
- Over-capacity projects (defer tasks)

**Output**: 3-5 actionable suggestions

### 10. Find Knowledge Graph Highlights
**Tool: Grep**

Search for interesting connections:
- Patterns applied across multiple projects
- Client patterns that became general patterns
- High-frequency pattern applications

### 11. Determine Next Milestone
**Milestones**:
1. First HIGH confidence pattern (proof of concept)
2. 10 patterns total (critical mass)
3. 10 hours saved (ROI validation)
4. 5 HIGH confidence patterns (expertise level)
5. 50 hours saved (senior efficiency)
6. 100 hours saved (mastery level)

**Calculate ETA** based on current growth rate

### 12. Assess Brain Health Score
**Formula**:
```javascript
const healthScore =
  (highConfidencePatterns * 10) +
  (mediumConfidencePatterns * 5) +
  (lowConfidencePatterns * 2) +
  (activeProjects * 3) +
  (weeklyTimeSaved * 2)

// Ratings:
// < 50: Just starting
// 50-100: Building momentum
// 100-200: Strong system
// 200+: Elite level
```

### 13. Display Comprehensive Report
Output 10-section dashboard with visualizations.

---

## Report Structure (10 Sections)

### Section 1: Brain Size
```markdown
🧠 BRAIN SIZE
- Semantic memory: 23 patterns
- Episodic memory: 67 experiences
- Procedural memory: 12 processes
- **Total knowledge**: 102 files
```

### Section 2: Intelligence Metrics
```markdown
🎓 INTELLIGENCE (Pattern Confidence)
- HIGH confidence: 8 patterns (proven, reliable)
- MEDIUM confidence: 11 patterns (working well)
- LOW confidence: 4 patterns (newly discovered)

**Expertise ratio**: 35% HIGH (target: 40%+)
```

### Section 3: Time Savings
```markdown
⏱️ TIME SAVINGS
- This week: 7.5 hours saved
- This month: 26 hours saved
- All-time: 143 hours saved

**Annual projection**: 390 hours/year (~10 full work weeks)
```

### Section 4: Top Performing Patterns
```markdown
🏆 TOP PATTERNS (By Time Saved)
1. PostgreSQL Indexing (HIGH) - 38h saved
2. Client Discovery Process (HIGH) - 22h saved
3. React Component Structure (MEDIUM) - 14h saved
4. API Error Handling (HIGH) - 11h saved
5. JWT Authentication (MEDIUM) - 8h saved
```

### Section 5: Domain Coverage
```markdown
📊 DOMAIN COVERAGE
✅ Development: 12 patterns (strong)
✅ Client Work: 8 patterns (strong)
⚠️ Content: 2 patterns (needs growth)
⚠️ Process: 1 pattern (needs growth)
```

### Section 6: Project Health
```markdown
📁 PROJECT HEALTH
- Active: 5 projects
- Paused: 2 projects
- Completed: 3 projects

**Average project load**: 3.2 open tasks per project (healthy)
```

### Section 7: Growth This Period
```markdown
📈 GROWTH (This Week)
- 2 patterns reinforced (→ MEDIUM confidence)
- 1 new pattern discovered
- 1 pattern promoted to HIGH
- 5 experiences logged

**Growth rate**: On track for 48 patterns/year
```

### Section 8: Knowledge Graph Highlights
```markdown
🔗 KNOWLEDGE GRAPH
- Most connected pattern: "PostgreSQL Indexing" (applied in 5 projects)
- Cross-domain insights: Client discovery patterns now informing internal product strategy
- Emerging cluster: Authentication patterns (JWT, OAuth, session management)
```

### Section 9: Recommendations
```markdown
💡 RECOMMENDATIONS (Next Actions)
1. **Promote "React Testing" to MEDIUM** (3 examples now, ready for promotion)
2. **Apply "Client Discovery" to new project** (proven HIGH confidence, haven't used in 2 weeks)
3. **Create content patterns** (only 2 patterns, opportunity for growth)
4. **Review paused projects** (2 projects idle for 3+ weeks, archive or reactivate?)
5. **Celebrate milestone**: First 5 HIGH confidence patterns achieved! 🎉
```

### Section 10: Next Milestone
```markdown
🎯 NEXT MILESTONE
**Goal**: 10 HIGH confidence patterns (Elite expertise level)

**Current**: 8 HIGH confidence patterns
**Progress**: 80% complete
**ETA**: 3-4 weeks (based on current growth rate)

**What this means**: Rare level of documented expertise. Top 5% of knowledge workers.
```

---

## Brain Health Score

**Calculation**:
```javascript
const score =
  (highConfidencePatterns * 10) +    // 8 × 10 = 80
  (mediumConfidencePatterns * 5) +   // 11 × 5 = 55
  (lowConfidencePatterns * 2) +      // 4 × 2 = 8
  (activeProjects * 3) +             // 5 × 3 = 15
  (weeklyTimeSaved * 2)              // 7.5 × 2 = 15

// Total: 173
```

**Score Ratings**:
- **< 50**: Just starting (weeks 1-4)
- **50-100**: Building momentum (months 2-3)
- **100-200**: Strong system (months 4-6)
- **200+**: Elite level (6+ months)

**Current example**: 173 (Strong system, approaching elite)

---

## Success Metrics

**Goal**: Measurable growth, visible ROI, sustained motivation

**Report Targets**:
- Generation time: < 5 seconds
- Accuracy: 100% (from actual data)
- Actionable insights: 3-5 recommendations
- Usage: Weekly ritual (100% adherence)

**Impact**:
- Motivation: Visible progress combats "is this working?" doubts
- ROI proof: Hard numbers for managers/clients
- Optimization: Data-driven growth strategy
- Celebration: Milestones create positive reinforcement

---

## Motivational Psychology

### Week 1: "Am I doing this right?"
**Feels**: Manual, overhead, unclear benefit

**Report shows**:
- 3 patterns (LOW confidence)
- 30 min saved
- Brain health score: 28

**Psychology**: Planting seeds, trust the process

---

### Week 4: "Oh, it's working!"
**Feels**: Starting to see patterns, occasional time savings

**Report shows**:
- 8 patterns (2 MEDIUM, 6 LOW)
- 2.5 hours saved this week
- Brain health score: 67

**Psychology**: Proof of concept, momentum building

---

### Week 12: "Can't imagine working without it"
**Feels**: Second nature, compound growth, obvious ROI

**Report shows**:
- 23 patterns (5 HIGH, 11 MEDIUM, 7 LOW)
- 7.5 hours saved this week
- 143 hours saved all-time
- Brain health score: 173

**Psychology**: Addicted to growth, system dependency (in a good way)

---

## Integration with Other Commands

### Weekly Ritual: Friday `/grow` Review
Standard end-of-week checkpoint.

### After Learning: `/grow` to See Progress
Run report after major learning sessions to see brain growth.

### Before Important Meetings: `/grow` for ROI Data
Show boss/client tangible productivity improvements.

### Milestone Celebrations: `/grow` to Validate Achievement
When reaching next milestone, run report to celebrate.

---

## Milestone Progression

### Milestone 1: First HIGH Confidence Pattern
**Requirement**: 5 examples, proven reliable

**Achievement**: Proof that system works

**Typical time**: Weeks 4-6

---

### Milestone 2: 10 Patterns Total
**Requirement**: Critical mass of knowledge

**Achievement**: System becomes useful daily

**Typical time**: Weeks 8-12

---

### Milestone 3: 10 Hours Saved
**Requirement**: ROI validation

**Achievement**: Undeniable time savings

**Typical time**: Weeks 10-14

---

### Milestone 4: 5 HIGH Confidence Patterns
**Requirement**: Expertise level

**Achievement**: Senior-level documented knowledge

**Typical time**: Weeks 12-16

---

### Milestone 5: 50 Hours Saved
**Requirement**: Compound efficiency gains

**Achievement**: Major productivity improvement

**Typical time**: Weeks 20-24

---

### Milestone 6: 100 Hours Saved
**Requirement**: Mastery level ROI

**Achievement**: Elite knowledge worker status

**Typical time**: Weeks 30-40

---

## Common Use Cases

### Use Case 1: Friday Ritual
```
Every Friday, 4:30 PM:
/grow

Review week's progress:
- 2 patterns reinforced
- 7.5 hours saved
- Next milestone: 80% to 10 HIGH patterns

Celebrate wins, plan next week
```

---

### Use Case 2: Quarterly Review with Manager
```
Before 1-on-1:
/grow month

Show boss tangible results:
- 26 hours saved this month
- 5 HIGH confidence patterns developed
- Annual projection: 312 hours saved

ROI justification: Time for raise/promotion
```

---

### Use Case 3: Motivation Boost
```
Feeling stuck, "is this working?"

Run: /grow

See proof:
- 143 hours saved (undeniable)
- 8 HIGH confidence patterns (documented expertise)
- Brain health score: 173 (strong system)

Doubts eliminated, motivation restored
```

---

*Last Updated: 2025-01-09*
*Version: 1.0.0*
*Lines: ~200 (complete skill, no references needed)*
