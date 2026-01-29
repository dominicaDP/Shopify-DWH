---
name: recall
description: Search all memories for relevant information by topic or keyword
allowed-tools: Read, Grep, Bash
---

# Recall Memory Command

Usage: `/recall [topic]`

Search across all memory types (semantic, episodic, procedural) to recall relevant information.

## Execution Steps

### Step 1: Parse Search Query

**Extract search terms:**
```javascript
const query = userInput.toLowerCase()
const searchTerms = query.split(' ')
```

**Check for domain prefix:**
```javascript
IF query starts with "dev:" → search_domain = "dev"
IF query starts with "client:" → search_domain = "client"
IF query starts with "pattern:" → search_domain = "pattern"
ELSE → search_domain = "all"
```

### Step 2: Search Semantic Memory

**Tool: Grep** (search file names)
```bash
Grep(
  pattern="<search_term>",
  path="memory/semantic/",
  output_mode="files_with_matches",
  -i=true
)
```

**Tool: Grep** (search file contents)
```bash
Grep(
  pattern="<search_term>",
  path="memory/semantic/",
  output_mode="content",
  -i=true,
  -C=2
)
```

**Directories to search:**
- `memory/semantic/tech/` - Technical knowledge
- `memory/semantic/clients/` - Client contexts
- `memory/semantic/patterns/` - Learned patterns
- `memory/semantic/products/` - Product knowledge
- `memory/semantic/ideas/` - Captured ideas

**For each match found:**
```bash
Read("<matched_file_path>")
```

**Extract:**
- Pattern confidence level (HIGH/MEDIUM/LOW)
- Last updated date
- Number of examples
- Key summary

### Step 3: Search Episodic Memory

**Tool: Grep** (search experiences)
```bash
Grep(
  pattern="<search_term>",
  path="memory/episodic/",
  output_mode="files_with_matches",
  -i=true
)
```

**Directories to search:**
- `memory/episodic/code/` - Past development work
- `memory/episodic/projects/` - Project milestones
- `memory/episodic/content/` - Content created
- `memory/episodic/learning/` - Learning experiences

**For each match:**
```bash
Read("<matched_episodic_file>")
```

**Extract:**
- Date of experience
- Pattern applied (if any)
- Outcome (SUCCESS/PARTIAL/BLOCKED)
- Time saved
- Key learnings

### Step 4: Search Procedural Memory

**Tool: Grep** (search workflows)
```bash
Grep(
  pattern="<search_term>",
  path="memory/procedural/workflows/",
  output_mode="files_with_matches",
  -i=true
)
```

**For each match:**
```bash
Read("<matched_workflow_file>")
```

**Extract:**
- Workflow steps
- Estimated time
- Last used date

### Step 5: Rank Results

**Prioritization logic:**
```javascript
results.sort((a, b) => {
  // 1. Exact title match (highest priority)
  IF a.title.exact_match && !b.title.exact_match:
    RETURN -1

  // 2. High confidence patterns
  IF a.type = "pattern" && a.confidence = "HIGH":
    RETURN -1

  // 3. Recent experiences (< 30 days)
  IF a.type = "episodic" && a.date within 30 days:
    RETURN -1

  // 4. Multiple search term matches
  IF a.match_count > b.match_count:
    RETURN -1

  RETURN 0
})
```

**Tool: Bash** (get current date for recency calculation)
```bash
Bash(command="date '+%Y-%m-%d'")
```

### Step 6: Calculate Cross-References

**Tool: Grep** (count total occurrences)
```bash
# Count how many times topic appears across all memory
Grep(
  pattern="<search_term>",
  path="memory/",
  output_mode="count"
)
```

**Build knowledge graph:**
```javascript
const graph = {
  total_patterns: count_matches_in("memory/semantic/patterns/"),
  total_experiences: count_matches_in("memory/episodic/"),
  total_workflows: count_matches_in("memory/procedural/"),
  related_projects: extract_projects_from(episodic_matches)
}
```

### Step 7: Calculate Time Savings

**For pattern matches:**
```javascript
IF pattern has time_saved field:
  total_time_saved = sum(all_applications.time_saved)
```

**For experience matches:**
```javascript
total_time_logged = sum(experiences.duration)
```

### Step 8: Format and Present Results

**Output structure:**
```markdown
# 🔍 Recall: "<search_query>"

## Semantic Memory (What You Know)

<IF high_confidence_patterns exist:>
### High Confidence Patterns
⭐ **<Pattern Name>** (HIGH confidence, <N> examples)
Location: <file_path>#<section>

Summary: <key takeaway>
When to use: <use case>
Last updated: <date>

<IF medium_confidence_patterns exist:>
### Medium Confidence Patterns
...

<IF technical_knowledge exists:>
### Technical Knowledge
📘 **<Knowledge Title>**
Location: <file_path>#<section>

Summary: <description>
Key points: <bullet points>

---

## Episodic Memory (What You've Done)

<IF recent_experiences exist:>
### Recent Experiences (Last 30 days)
📝 **<Experience Title>** (<date>)
Location: <file_path>

What: <description>
Pattern applied: <pattern_name>
Result: ✅/⚠️/❌ <outcome>
Time saved: <X> min

---

## Procedural Memory (How You Do Things)

<IF workflows exist:>
### Workflows
🔧 **<Workflow Name>**
Location: <file_path>

Steps: <summary of steps>
Estimated time: <duration>
Last used: <date or project>

---

## Cross-References

🕸️ **Knowledge Graph:**
- "<search_term>" appears in <N> patterns
- Used across <N> projects
- <N> related experiences in episodic memory
- <N> workflows reference this topic

<IF time_saved data exists:>
💡 **Most Valuable:**
"<pattern_name>" has saved ~<X> hours total
(applied <N> times, <Y> min saved each)

📊 **Confidence:**
<Topic> knowledge: STRONG/MEDIUM/EMERGING
<Confidence assessment>

---

**Found:** <N> results (<N> patterns, <N> experiences, <N> workflows)
**Most recent:** <X> days ago
**Next action:** <suggested action>
```

## Example Execution

**Input:**
```
/recall authentication
```

**Tool calls sequence:**
```bash
1. Grep(pattern="authentication", path="memory/semantic/", output_mode="files_with_matches")
   → Finds: dev-patterns.md, architecture-decisions.md

2. Read("memory/semantic/patterns/dev-patterns.md")
   → Extract: JWT refresh tokens pattern (HIGH confidence, 3 examples)

3. Read("memory/semantic/tech/architecture-decisions.md")
   → Extract: Auth strategy decisions

4. Grep(pattern="authentication", path="memory/episodic/", output_mode="files_with_matches")
   → Finds: 2025-01-09-oauth-fix.md, 2024-12-15-client-b-auth.md, 2024-11-20-auth-refactor.md

5. Read("memory/episodic/code/2025-01-09-oauth-fix.md")
   → Extract: Recent OAuth fix, 30 min saved

6. Read("memory/episodic/code/2024-12-15-client-b-auth.md")
   → Extract: Client B auth work

7. Grep(pattern="authentication", path="memory/procedural/", output_mode="files_with_matches")
   → Finds: oauth-setup.md

8. Read("memory/procedural/workflows/oauth-setup.md")
   → Extract: OAuth setup workflow

9. Bash(command="date '+%Y-%m-%d'")
   → Get: 2025-01-09 (for recency calculation)

10. Grep(pattern="authentication", path="memory/", output_mode="count")
    → Count: 23 total mentions
```

**Output:**
```
# 🔍 Recall: "authentication"

## Semantic Memory (What You Know)

### High Confidence Patterns
⭐ **JWT Refresh Tokens for Mobile Apps** (HIGH confidence, 3 examples)
Location: memory/semantic/patterns/dev-patterns.md#jwt-tokens-mobile

Summary: Mobile apps need 15-20 min token expiry (vs 5-10 min for web)
When to use: Any mobile app using JWT authentication
Last updated: 2025-01-09

⭐ **Error Logging with User Context** (MEDIUM confidence, 2 examples)
Location: memory/semantic/patterns/dev-patterns.md#error-logging

Summary: Always include user_id and request_id in auth error logs
When to use: Debugging authentication failures
Last updated: 2025-01-08

### Technical Knowledge
📘 **Architecture Decisions - Auth Strategy**
Location: memory/semantic/tech/architecture-decisions.md#auth-pattern

Summary: Using JWT tokens, refresh token strategy, OAuth 2.0 for client apps
Key decisions: Separate expiry for mobile/web, server-side refresh token storage

---

## Episodic Memory (What You've Done)

### Recent Experiences (Last 30 days)
📝 **Client A - OAuth Bug Fix** (2025-01-09)
Location: memory/episodic/code/2025-01-09-oauth-fix.md

What: Fixed mobile app logout issues (token expiry too short)
Pattern applied: JWT refresh tokens for mobile
Result: ✅ Success, saved 30 min (knew solution from past)
Time saved: 30 min

📝 **Client B - Authentication Module** (2024-12-15)
Location: memory/episodic/code/2024-12-15-client-b-auth.md

What: Implemented OAuth 2.0 for client's mobile app
Pattern applied: JWT refresh tokens for mobile
Result: ✅ Success, pattern originated here
Learning: Mobile tokens need longer expiry

---

## Procedural Memory (How You Do Things)

### Workflows
🔧 **Setting up OAuth 2.0**
Location: memory/procedural/workflows/oauth-setup.md

Steps: Configure provider → Implement token flow → Add refresh logic → Test
Estimated time: 2-3 hours
Last used: Client B project

---

## Cross-References

🕸️ **Knowledge Graph:**
- "authentication" appears in 3 patterns
- Used across 4 client projects
- 12 related experiences in episodic memory
- 2 workflows reference this topic

💡 **Most Valuable:**
"JWT refresh tokens for mobile" has saved ~1.5 hours total
(applied 3 times, 30 min saved each)

📊 **Confidence:**
Authentication knowledge: STRONG (high-confidence patterns exist)
You're an expert in this area!

---

**Found:** 8 results (3 patterns, 3 experiences, 2 workflows)
**Most recent:** 1 day ago
**Next action:** Apply JWT pattern to current work?
```

## Advanced Search Features

### Multi-Term Search
**Usage:** `/recall "mobile authentication jwt"`

**Tool: Grep** (all terms)
```bash
# Search for files containing ALL terms
Grep(pattern="mobile.*authentication.*jwt", path="memory/", output_mode="files_with_matches", -i=true)
```

### Domain-Specific Search
**Usage:** `/recall "dev:authentication"`

**Logic:**
```javascript
IF query.startsWith("dev:"):
  search_path = "memory/semantic/tech/" + "memory/semantic/patterns/"
  query = query.replace("dev:", "")

IF query.startsWith("client:"):
  search_path = "memory/semantic/clients/"
  query = query.replace("client:", "")

IF query.startsWith("pattern:"):
  search_path = "memory/semantic/patterns/"
  query = query.replace("pattern:", "")
```

### Time-Based Search
**Usage:** `/recall "authentication last-week"`

**Tool: Bash** (calculate date range)
```bash
Bash(command="date -d '7 days ago' '+%Y-%m-%d'")  # Start date
Bash(command="date '+%Y-%m-%d'")                   # End date
```

**Filter results:**
```javascript
results = results.filter(r => r.date >= start_date && r.date <= end_date)
```

## When to Use /recall

### Before Starting Work
```bash
/recall "<feature I'm about to build>"
# See: Past experiences, patterns, potential issues
```

### During Problem-Solving
```bash
/recall "<bug type I'm facing>"
# See: Similar past experiences, solutions that worked
```

### Before Client Meetings
```bash
/recall "<client name>"
# See: Past work, open issues, client preferences
```

### When Writing Content
```bash
/recall "<topic I'm writing about>"
# See: Past blog posts, patterns, examples
```

## Integration with Other Commands

### /recall → /switch
```bash
/recall "client a"
→ Shows client context
→ Suggest: /switch client-a to load full context
```

### /recall → /learn
```bash
/recall "authentication"
→ Shows 3 related experiences
→ Realize: This is a pattern! Run /learn to consolidate
```

### /recall → /add-task
```bash
/recall "feature idea"
→ Find idea from 2 months ago
→ Action: /add-task project "Implement [idea]"
```

## Search Tips

**Be Specific:**
- ❌ "code" (too broad, 100+ results)
- ✅ "authentication code" (focused, 10 results)

**Use Full Context:**
- ❌ "bug" (ambiguous)
- ✅ "payment processing bug" (clear)

**Try Variations:**
- "auth", "authentication", "login" (same concept, different terms)
- Search multiple ways if first doesn't find it

**Domain Prefixes:**
- "dev:topic" - Technical only
- "client:name" - Client-specific
- "pattern:term" - Patterns only

## Success Metrics

**Goal:** Find relevant information in < 30 seconds

**Metrics:**
- Search time: 5-10 seconds
- Relevance: 80%+ results useful
- Time saved: 5-10 min per search vs manual notes review

## Required Files

**Directory structure:**
```
memory/
├── semantic/
│   ├── tech/
│   ├── clients/
│   ├── patterns/
│   ├── products/
│   └── ideas/
├── episodic/
│   ├── code/
│   ├── projects/
│   ├── content/
│   └── learning/
└── procedural/
    └── workflows/
```

## Edge Cases

### No Results Found
**Output:**
```
# 🔍 Recall: "<search_query>"

❌ No results found for "<search_query>"

**Suggestions:**
- Try different search terms
- Check spelling
- Use broader terms
- Try domain prefix (dev:, client:, pattern:)

**Or:**
- This might be new knowledge - consider adding it!
```

### Too Many Results
**If > 20 results:**
```
⚠️ Found 45 results. Showing top 20.

**Narrow your search:**
- Add more specific terms
- Use domain prefix
- Add time filter (last-week, this-month)
```

## Notes for the user

**Use for:**
- "I've solved this before..." (recall solution)
- "What did I learn about..." (recall patterns)
- "What's the context for..." (recall project/client)
- "How do I..." (recall workflows)

**Time saved:**
- 5-10 min per search (vs manually digging through notes)
- Prevents rediscovering same solutions
- Surfaces connections you'd forget

**The magic:**
- Week 4: "Oh, I remember this!"
- Week 12: "I've solved this 3 times already!"
- Your brain becomes searchable, not forgettable
