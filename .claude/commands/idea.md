---
name: idea
description: Quick idea capture with automatic categorization
allowed-tools: Read, Write, Edit, Bash
---

# Idea Capture Command

Usage: `/idea [idea-text]`

Quickly capture an idea with automatic categorization and save to appropriate memory location.

## Execution Steps

### Step 1: Capture Idea Text and Timestamp

**Tool: Bash** (get timestamp)
```bash
Bash(command="date '+%Y-%m-%d %H:%M:%S'")
```

**Extract:**
```javascript
const ideaText = userInput
const timestamp = result_from_bash
const dateOnly = timestamp.split(' ')[0]
```

### Step 2: Categorize Idea (AI-Powered)

**Analyze idea text to determine:**
- **Category:** product, content, business, tech, client, process, personal
- **Priority:** high, medium, low
- **Domain:** dev, PM, marketing, operations, etc.
- **Related project:** (if applicable)

**Categorization logic:**
```javascript
// Keyword-based categorization
IF ideaText.includes("blog", "post", "article", "video", "social"):
  category = "content"
  domain = "marketing"

IF ideaText.includes("refactor", "code", "technical", "architecture"):
  category = "tech"
  domain = "dev"

IF ideaText.includes("feature", "product", "user", "UI", "dashboard"):
  category = "product"
  domain = "dev" or "PM"

IF ideaText.includes("pricing", "business model", "revenue", "strategy"):
  category = "business"
  domain = "operations"

IF ideaText.includes("process", "automation", "workflow", "efficiency"):
  category = "process"
  domain = "operations"

// Priority determination
IF ideaText.includes("urgent", "critical", "asap", "client requested"):
  priority = "high"

IF ideaText.includes("nice to have", "someday", "maybe"):
  priority = "low"

ELSE:
  priority = "medium"
```

**Check for related project:**
```javascript
// Extract project references
IF ideaText.mentions("client a", "client-a", "ecommerce"):
  relatedProject = "client-a"

IF ideaText.mentions("blog", "content"):
  relatedProject = "content-2025-q1"

IF ideaText.mentions("internal", "product"):
  relatedProject = "internal-product"
```

### Step 3: Generate Idea Metadata

**Create idea title:**
```javascript
// Extract first sentence or first 50 chars
const ideaTitle = ideaText.split('.')[0] || ideaText.substring(0, 50)
```

**Generate "Why This Matters":**
```javascript
// AI-generated context based on category and domain
// Relate to existing projects, patterns, or business goals
```

**Generate "Next Steps":**
```javascript
// AI-suggested 2-3 actionable steps to explore this idea
// Based on category and priority
```

### Step 4: Determine Save Location

**Mapping:**
```javascript
const saveLocation = {
  product: "memory/semantic/ideas/product-ideas.md",
  content: "memory/semantic/ideas/content-ideas.md",
  business: "memory/semantic/ideas/business-ideas.md",
  tech: "memory/semantic/ideas/tech-ideas.md",
  process: "memory/semantic/ideas/process-ideas.md",
  client: "memory/semantic/ideas/client-ideas.md",
  personal: "memory/semantic/ideas/personal-ideas.md"
}[category]
```

### Step 5: Read Existing Ideas File

**Tool: Read**
```bash
Read(saveLocation)
```

**Check if file exists:**
```javascript
IF file_not_found:
  // Create new file with header
  createNewIdeasFile(saveLocation, category)
```

### Step 6: Format and Append Idea

**Format idea entry:**
```markdown
## [Idea Title] (Added: YYYY-MM-DD)

**Category:** [product/content/business/tech/process]
**Priority:** [high/medium/low]
**Domain:** [dev/PM/marketing/operations]
**Status:** New

### Description
[Idea text from user]

### Why This Matters
[AI-generated context: Why this could be valuable]

### Related
[Links to related projects, patterns, or experiences]

### Next Steps
[AI-suggested first actions to explore this idea]

---
```

**Tool: Edit** (append to file)
```bash
Edit(
  file_path=saveLocation,
  old_string="# [Category] Ideas\n\n",
  new_string="# [Category] Ideas\n\n" + formattedIdea + "\n"
)
```

### Step 7: Link to Project (if applicable)

**If idea relates to existing project:**

**Tool: Read** (check if project exists)
```bash
Read("projects/<project-name>/context.md")
```

**Tool: Edit** (add idea reference to project)
```bash
Edit(
  file_path="projects/<project-name>/context.md",
  old_string="## Ideas to Explore\n",
  new_string="## Ideas to Explore\n- [Idea title] (captured: <date>)\n"
)
```

### Step 8: Update Brain Health Metrics

**Tool: Read**
```bash
Read("brain-health/metrics.md")
```

**Tool: Edit** (increment idea counter)
```bash
Edit(
  file_path="brain-health/metrics.md",
  old_string="Ideas captured: <N>",
  new_string="Ideas captured: <N+1>"
)

Edit(
  file_path="brain-health/metrics.md",
  old_string="Ideas this week: <N>",
  new_string="Ideas this week: <N+1>"
)
```

### Step 9: Output Confirmation

**Format output:**
```markdown
💡 Idea captured!

**Category:** [Category] idea
**Priority:** [Priority]
**Domain:** [Domain]

📝 Saved to: [file_path]

### Why This Matters
[AI-generated rationale]

### Next Steps
1. [Action 1]
2. [Action 2]
3. [Action 3]

<IF related_project exists:>
🔗 **Related project:** [project-name]
   Run: /add-task [project-name] "[suggested task]"

<IF related_patterns exist:>
📊 **Related patterns available:**
- [Pattern 1] (confidence level)
- [Pattern 2] (confidence level)

⏱️ **Time saved:** ~30 seconds (vs writing in notes + categorizing later)
```

## Example Execution

**Input:**
```
/idea "Add real-time collaboration to dashboard"
```

**Tool calls sequence:**
```bash
1. Bash(command="date '+%Y-%m-%d %H:%M:%S'")
   → Get: "2025-01-09 14:35:20"

2. Categorize idea (AI logic):
   → Category: product
   → Priority: medium
   → Domain: dev
   → Related project: internal-product

3. Read("memory/semantic/ideas/product-ideas.md")
   → Check if file exists

4. Edit(
     file_path="memory/semantic/ideas/product-ideas.md",
     old_string="# Product Ideas\n\n",
     new_string="# Product Ideas\n\n## Add real-time collaboration to dashboard (Added: 2025-01-09)...\n"
   )
   → Append formatted idea

5. Read("projects/internal-product/context.md")
   → Check project exists

6. Edit(
     file_path="projects/internal-product/context.md",
     old_string="## Ideas to Explore\n",
     new_string="## Ideas to Explore\n- Add real-time collaboration to dashboard (captured: 2025-01-09)\n"
   )

7. Read("brain-health/metrics.md")
   → Get current counts

8. Edit(
     file_path="brain-health/metrics.md",
     old_string="Ideas captured: 23",
     new_string="Ideas captured: 24"
   )
```

**Output:**
```
💡 Idea captured!

**Category:** Product idea
**Priority:** Medium
**Domain:** Dev

📝 Saved to: memory/semantic/ideas/product-ideas.md

### Why This Matters
Real-time collaboration would differentiate from competitors
and enable team-based workflows. Aligns with your SaaS vision.

### Next Steps
1. Research collaboration libraries (Socket.io, Yjs, etc.)
2. Prototype simple cursor-tracking
3. Add to internal-product backlog

🔗 **Related project:** internal-product
   Run: /add-task internal-product "Research real-time collab"

⏱️ **Time saved:** ~30 seconds (vs writing in notes + categorizing later)
```

## Advanced Features

### Quick Capture (Minimal Detail)

**Input:** `/idea "Dark mode"`

**Execution:**
- Minimal categorization (product, medium priority)
- Save quickly
- Suggest adding detail later

**Output:**
```
💡 Idea captured!

**Category:** Product idea (UI feature)
**Priority:** Medium
**Domain:** Dev

📝 Saved to: memory/semantic/ideas/product-ideas.md

💭 **Tip:** Add more detail later:
   - Who requested this?
   - Which projects need it?
   - Expected effort?

⏱️ **Time saved:** ~5 seconds (ultra-fast capture)
```

### Related Pattern Lookup

**After categorizing, search for related patterns:**

**Tool: Grep**
```bash
Grep(
  pattern="<idea_keyword>",
  path="memory/semantic/patterns/",
  output_mode="files_with_matches"
)
```

**If matches found:**
```markdown
📊 **Related patterns available:**
- JWT refresh tokens for mobile (HIGH confidence)
- Error logging with user context (MEDIUM confidence)

💡 **Tip:** Review these patterns before implementing
```

### Idea Aging Detection

**Check if similar idea already exists:**

**Tool: Grep**
```bash
Grep(
  pattern="<idea_keywords>",
  path="memory/semantic/ideas/<category>-ideas.md",
  output_mode="content"
)
```

**If duplicate found:**
```markdown
⚠️ **Similar idea exists:**
"Add notifications" (captured: 2024-11-15, 55 days ago)

**Options:**
1. Merge with existing idea (add details)
2. Create new idea (different approach)
3. Convert old idea to task (it's been 55 days!)

**Suggest:** /add-task internal-product "Implement notifications"
```

## Integration with Other Commands

### /idea → /add-task

**Workflow:**
```bash
# Capture idea
/idea "Add analytics dashboard"
→ Saved to product-ideas.md

# Later, convert to task
/add-task internal-product "Implement analytics dashboard"
```

### /idea → /recall

**Search for idea:**
```bash
/recall "dashboard idea"
→ Finds: "Add analytics dashboard" (captured 15 days ago)
```

### /idea → /learn

**Ideas inform patterns:**
```bash
# Multiple related ideas
/idea "Mobile UX improvement A"
/idea "Mobile UX improvement B"
/idea "Mobile UX improvement C"

# Later, recognize pattern
/learn → Pattern: "Mobile-first design matters for our users"
```

## Idea Management Best Practices

**Capture Everything:**
- Don't filter at capture time
- Low-friction = more ideas captured
- Review/filter weekly

**Add Context When Possible:**
- Why this idea matters
- Who would benefit
- Rough effort estimate

**Review Regularly:**
- Weekly: Convert high-priority to tasks
- Monthly: Archive low-value ideas
- Quarterly: Identify themes

**Don't Let Ideas Rot:**
- Idea > 90 days without action → Archive or promote
- "Someday/maybe" is okay, but review periodically

## Success Metrics

**Goal:** Save 2 hr/week on idea capture

**Metrics:**
- Capture time: < 30 seconds per idea
- Ideas captured: 10-15/week (vs 3-5 before)
- Ideas converted to tasks: 30%+
- Lost ideas: 0 (vs many before)

**ROI calculation:**
- Before: 10 ideas/week × 5 min each = 50 min/week
- After: 10 ideas/week × 30 sec each = 5 min/week
- **Time saved:** 45 min/week

**Plus:** No more lost ideas (value: immeasurable)

## Required Files

**Directory structure:**
```
memory/semantic/ideas/
├── product-ideas.md
├── content-ideas.md
├── business-ideas.md
├── tech-ideas.md
├── process-ideas.md
├── client-ideas.md
└── personal-ideas.md
```

**File format (example):**
```markdown
# Product Ideas

## Add real-time collaboration (Added: 2025-01-09)
**Category:** Product
**Priority:** Medium
**Domain:** Dev
**Status:** New

### Description
Add real-time collaboration to dashboard for team-based work

### Why This Matters
Differentiates from competitors, enables team workflows

### Next Steps
1. Research libraries
2. Prototype
3. Add to backlog

---

## Dark mode (Added: 2025-01-08)
...
```

## Edge Cases

### Empty Idea Text

**If user provides no text:**
```
❌ Error: No idea text provided

**Usage:** /idea "your idea text here"

**Example:** /idea "Add dark mode to app"
```

### File Not Found

**If ideas file doesn't exist, create it:**

**Tool: Write**
```bash
Write(
  file_path="memory/semantic/ideas/<category>-ideas.md",
  content="# [Category] Ideas\n\n[This file contains captured ideas for <category>]\n\n---\n\n"
)
```

### Very Long Idea

**If idea > 500 characters:**
```
⚠️ **Long idea detected** (750 characters)

**Suggestion:** This might be better as:
- A project proposal (create in projects/)
- A document (create in memory/semantic/)
- Multiple smaller ideas

**Still save?** (yes/no)
```

## Future Enhancements (Week 3)

### Voice Integration

**Setup:**
```
1. Google Drive watcher: Second-Brain-Ideas/
2. Auto-transcribe voice notes (Whisper API)
3. Run /idea [transcribed-text]
4. Push notification: "Idea captured"
5. Delete processed audio file
```

**User experience:**
- Speak idea (while driving)
- Get notification
- Done (zero manual work)

### Bulk Idea Capture

**Command:** `/idea-bulk`

**Input:**
```
/idea-bulk "
- Add analytics dashboard
- Improve error messages
- Client requested export feature
- Research competitor pricing
"
```

**Output:**
```
💡 Captured 4 ideas!
✅ Product: Analytics dashboard (medium)
✅ Product: Better error messages (low)
✅ Product: Export feature (high - client request)
✅ Business: Research competitor pricing (medium)

📝 All saved to appropriate memory locations
```

## Notes for the user

**The habit:**
- Any time idea pops up → `/idea [text]` → Done
- Don't think about categorization
- AI handles organization
- Review weekly

**Target:**
- Capture 10-15 ideas/week (vs 3-5 before)
- Convert 30% to tasks
- Zero lost ideas

**Time saved:**
- Per idea: 30 sec vs 5 min = 4.5 min saved
- Per week: 45 min saved
- Per year: 39 hours saved

**Value beyond time:**
- No more lost breakthrough ideas
- Pattern recognition across ideas
- Better decision-making with idea history
