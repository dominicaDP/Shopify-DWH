# Idea Capture - Detailed Workflow

Full 8-step capture with tool calls.

## Step 1: Capture Text + Timestamp

**Tool: Bash** (get timestamp)
```bash
Bash(command="date '+%Y-%m-%d %H:%M:%S'")
```

**Store**:
```javascript
const ideaText = userInput
const timestamp = bashResult
const dateOnly = timestamp.split(' ')[0]
```

## Step 2: Categorize Idea

**Keyword Analysis**:
```javascript
const text = ideaText.toLowerCase()

let category = "general"

if (text.includes("blog") || text.includes("post") || text.includes("article") || 
    text.includes("video") || text.includes("social") || text.includes("content")) {
  category = "content"
}
else if (text.includes("refactor") || text.includes("code") || text.includes("technical") || 
         text.includes("architecture") || text.includes("bug") || text.includes("api")) {
  category = "tech"
}
else if (text.includes("feature") || text.includes("product") || text.includes("user") || 
         text.includes("ui") || text.includes("dashboard") || text.includes("ux")) {
  category = "product"
}
else if (text.includes("pricing") || text.includes("business model") || text.includes("revenue") || 
         text.includes("strategy") || text.includes("sales")) {
  category = "business"
}
else if (text.includes("process") || text.includes("automation") || text.includes("workflow") || 
         text.includes("efficiency") || text.includes("optimize")) {
  category = "process"
}
else if (text.includes("client") || detectClientMention(text)) {
  category = "client"
}
```

## Step 3: Determine Priority

**Priority Keywords**:
```javascript
let priority = "medium"  // default

// HIGH priority indicators
if (text.includes("urgent") || text.includes("critical") || text.includes("asap") ||
    text.includes("client requested") || text.includes("blocking") || 
    text.includes("important")) {
  priority = "high"
}

// LOW priority indicators  
if (text.includes("nice to have") || text.includes("someday") || text.includes("maybe") ||
    text.includes("explore") || text.includes("consider")) {
  priority = "low"
}
```

## Step 4: Check for Related Project

**Tool: Grep** (find project mentions)
```bash
Grep(
  pattern="<detected_project_name>",
  path="projects/INDEX.md",
  output_mode="files_with_matches"
)
```

**Project Detection**:
```javascript
// Check for explicit project mentions
const projectMentions = [
  /client[- ]?a/i,
  /client[- ]?b/i,
  /internal/i,
  /product/i,
  // Extract from projects/INDEX.md
]

let relatedProject = null
for (const pattern of projectMentions) {
  if (pattern.test(ideaText)) {
    relatedProject = extractProjectName(ideaText, pattern)
    break
  }
}
```

## Step 5: Generate Metadata

**Create Title**:
```javascript
// Use first sentence or first 50 chars
let ideaTitle = ideaText.split('.')[0].trim()
if (ideaTitle.length > 50) {
  ideaTitle = ideaText.substring(0, 50).trim() + "..."
}
```

**Generate "Why This Matters"** (AI):
```javascript
const whyItMatters = generateContext(ideaText, category, relatedProject)
// AI analyzes: business value, technical feasibility, strategic alignment
```

**Generate "Next Steps"** (AI):
```javascript
const nextSteps = generateActionItems(ideaText, category)
// AI suggests: research, validation, prototyping steps
```

## Step 6: Save to Category File

**Tool: Read** (existing ideas)
```bash
Read("memory/semantic/ideas/<category>-ideas.md")
```

**Tool: Edit** (append new idea)
```markdown
## [IDEA TITLE] (Added: 2025-01-09)

**Category:** Product  
**Priority:** HIGH  
**Related Project:** client-a

### Why This Matters
[AI-generated context about business value and relevance]

### Next Steps
1. [AI-suggested action item 1]
2. [AI-suggested action item 2]
3. [AI-suggested action item 3]

### Original Note
[User's raw idea text]

---
```

## Step 7: Link to Project

**If relatedProject detected**:

**Tool: Write** (or Edit if exists)
```bash
Write(
  file_path="projects/<project>/ideas.md",
  content="[link to idea in semantic memory]"
)
```

## Step 8: Show Confirmation

```markdown
✅ Idea captured!

📂 **Saved to:** memory/semantic/ideas/<category>-ideas.md
🏷️ **Category:** <category>
⭐ **Priority:** <priority>
🔗 **Linked to:** <project> (if applicable)

💡 **Review:** Run weekly idea review (Friday, 30 min)
```
