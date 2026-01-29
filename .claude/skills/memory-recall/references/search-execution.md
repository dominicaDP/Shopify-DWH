# Memory Recall - Detailed Search Execution

Full 8-step search workflow with tool calls.

## Step 1: Parse Search Query

Extract search terms and check for domain prefix.

**Tool: JavaScript Logic**
```javascript
const query = userInput.toLowerCase()
const searchTerms = query.split(' ')

// Check for domain prefix
let searchDomain = "all"
let cleanQuery = query

if (query.startsWith("dev:")) {
  searchDomain = "dev"
  cleanQuery = query.replace("dev:", "").trim()
} else if (query.startsWith("client:")) {
  searchDomain = "client"
  cleanQuery = query.replace("client:", "").trim()
} else if (query.startsWith("pattern:")) {
  searchDomain = "pattern"
  cleanQuery = query.replace("pattern:", "").trim()
}
```

## Step 2: Search Semantic Memory

**Domain-Specific Paths**:
```javascript
const searchPaths = {
  dev: ["memory/semantic/patterns/dev-patterns.md", "memory/semantic/tech/"],
  client: ["memory/semantic/clients/", "memory/semantic/patterns/client-patterns.md"],
  pattern: ["memory/semantic/patterns/"],
  all: ["memory/semantic/"]
}
```

**Tool: Grep** (file names)
```bash
Grep(
  pattern="<search_term>",
  path=searchPaths[searchDomain],
  output_mode="files_with_matches",
  -i=true
)
```

**Tool: Grep** (file contents)
```bash
Grep(
  pattern="<search_term>",
  path=searchPaths[searchDomain],
  output_mode="content",
  -i=true,
  -C=2
)
```

**For each match**:
```bash
Read("<matched_file_path>")
```

**Extract from semantic patterns**:
- Pattern confidence (HIGH/MEDIUM/LOW)
- Examples count
- Last updated date
- Time saved total
- When to use

## Step 3: Search Episodic Memory

**Tool: Grep**
```bash
Grep(
  pattern="<search_term>",
  path="memory/episodic/",
  output_mode="files_with_matches",
  -i=true
)
```

**Subdirectories**:
- `code/` - Development work
- `projects/` - Project milestones
- `content/` - Content created
- `learning/` - Learning experiences

**For each match**:
```bash
Read("<matched_episodic_file>")
```

**Extract**:
- Date (YYYY-MM-DD from filename)
- Outcome (SUCCESS/PARTIAL/BLOCKED)
- Patterns applied
- Time saved
- Project context

## Step 4: Search Procedural Memory

**Tool: Grep**
```bash
Grep(
  pattern="<search_term>",
  path="memory/procedural/workflows/",
  output_mode="files_with_matches",
  -i=true
)
```

**For each match**:
```bash
Read("<matched_workflow_file>")
```

**Extract**:
- Workflow name
- Steps count
- Estimated time
- Last used (from context or date)

## Step 5: Rank Results

**Tool: Bash** (get current date)
```bash
Bash(command="date '+%Y-%m-%d'")
```

**Prioritization algorithm**:
```javascript
results.sort((a, b) => {
  // Priority 1: Exact title match
  if (a.title.toLowerCase() === cleanQuery.toLowerCase() && 
      b.title.toLowerCase() !== cleanQuery.toLowerCase()) {
    return -1
  }
  
  // Priority 2: HIGH confidence patterns
  if (a.type === "pattern" && a.confidence === "HIGH" &&
      !(b.type === "pattern" && b.confidence === "HIGH")) {
    return -1
  }
  
  // Priority 3: Recent experiences (< 30 days)
  const daysSinceA = calculateDaysSince(a.date, currentDate)
  const daysSinceB = calculateDaysSince(b.date, currentDate)
  if (a.type === "episodic" && daysSinceA < 30 &&
      !(b.type === "episodic" && daysSinceB < 30)) {
    return -1
  }
  
  // Priority 4: Multiple term matches
  if (a.matchCount > b.matchCount) {
    return -1
  }
  
  return 0
})
```

## Step 6: Calculate Cross-References

**Tool: Grep** (count occurrences)
```bash
# Total pattern count
Grep(
  pattern="<search_term>",
  path="memory/semantic/patterns/",
  output_mode="count"
)

# Episodic experiences count
Grep(
  pattern="<search_term>",
  path="memory/episodic/",
  output_mode="count"
)

# Workflows count
Grep(
  pattern="<search_term>",
  path="memory/procedural/",
  output_mode="count"
)
```

**Build knowledge graph**:
```javascript
const knowledgeGraph = {
  totalPatterns: patternMatches.length,
  totalExperiences: episodicMatches.length,
  totalWorkflows: proceduralMatches.length,
  relatedProjects: extractUniqueProjects(episodicMatches),
  mostValuablePattern: findHighestTimeSaved(patternMatches)
}
```

## Step 7: Calculate Time Savings

```javascript
let totalTimeSaved = 0

for (const pattern of patternMatches) {
  if (pattern.timeSaved) {
    totalTimeSaved += pattern.timeSaved
  }
}
```

## Step 8: Format and Present Results

See `output-formatting.md` for display templates.
