---
name: memory-recall
description: |
  Search across all memory types (semantic, episodic, procedural) to recall relevant information by topic or keyword.
  Provides ranked results with confidence levels, cross-references, and knowledge graph connections.
  Surfaces patterns, past experiences, and workflows to apply existing knowledge to current work.
allowed-tools: "Read,Grep,Bash"
---

# Memory Recall Skill

## Skill Metadata
- **Version**: 1.0.0
- **Author**: the user's Second Brain Team
- **Category**: knowledge-retrieval
- **Tags**: search, memory, recall, semantic-search, knowledge-graph, pattern-retrieval

**Dependencies**:
- **Files**: `memory/semantic/**/*.md`, `memory/episodic/**/*.md`, `memory/procedural/**/*.md`, `brain-health/pattern-confidence.md`

**Input Parameters**:
- `search_query` (string, required): Topic or keyword to search for
- `search_domain` (enum, optional): all | dev | client | pattern | content
- `time_filter` (enum, optional): all | last-week | this-month | last-30-days

**Output**:
- `semantic_results` (array): Patterns and knowledge with confidence levels
- `episodic_results` (array): Past experiences with dates and outcomes
- `procedural_results` (array): Workflows and processes
- `knowledge_graph` (object): Cross-references and connection counts
- `time_saved_total` (number): Cumulative time saved from patterns found
- `suggested_action` (string): Next step recommendation

**Success Metrics**:
- Search time: < 30 seconds
- Result relevance: 80%+ results useful
- Time saved vs manual: 5-10 min per search
- Pattern application rate: 60%+ of searches lead to application

---

## Executive Snapshot

**Knowledge Retrieval System**: Searches across all three memory types (semantic, episodic, procedural) to find relevant information by topic or keyword. Ranks results by confidence level, recency, and relevance.

**Core Philosophy**: Your brain should be searchable, not forgettable. Every search surfaces not just what you know, but when you learned it, how you applied it, and what time it saved.

**Quality Standard**: Results ranked by relevance (exact matches > high confidence patterns > recent experiences). Cross-references show knowledge connections.

---

## When to Run

**Trigger moments**:
- Before starting work: "Have I done this before?"
- During problem-solving: "How did I solve this last time?"
- Before client meetings: "What do I know about this client?"
- When writing content: "What have I written about this topic?"

**Time investment**: 5-10 seconds per search

**ROI**: 5-10 min saved per search (vs manual notes review)

---

## Workflow Overview (8 Steps)

### 1. Parse Search Query
Extract search terms and check for domain prefixes (dev:/client:/pattern:). Defaults to searching all memory types.

### 2. Search Semantic Memory
Grep semantic patterns, technical knowledge, client contexts. For each match, extract confidence level, examples count, time saved.

### 3. Search Episodic Memory
Grep past experiences (code/projects/content/learning). Extract dates, outcomes, patterns applied, time saved.

### 4. Search Procedural Memory
Grep workflows and checklists. Extract steps, estimated time, last used.

### 5. Rank Results
Prioritize: exact matches > HIGH confidence patterns > recent experiences (< 30 days) > multiple term matches.

### 6. Calculate Cross-References
Count topic occurrences across all memory, build knowledge graph showing connections between patterns, experiences, and projects.

### 7. Calculate Time Savings
Aggregate cumulative time saved from all pattern applications found.

### 8. Format and Present Results
Display semantic/episodic/procedural results, knowledge graph, top patterns by time saved, suggested next actions.

📖 **For detailed execution with tool calls**: `Read {baseDir}/references/search-execution.md`

---

## Search Features

### Domain-Specific Search
**Prefixes**:
- `dev:topic` - Technical knowledge only
- `client:name` - Client-specific information only
- `pattern:term` - Patterns only
- No prefix - Search all domains

**Example**: `/recall dev:authentication` searches only technical patterns

### Result Ranking

| Priority | Type | Criteria |
|----------|------|----------|
| **1** | Exact match | Title exactly matches query |
| **2** | HIGH confidence | Patterns with 5+ examples |
| **3** | Recent | Episodic memory < 30 days old |
| **4** | Multi-match | Multiple search terms found |

📖 **For ranking algorithm details**: `Read {baseDir}/references/ranking-logic.md`

---

## Output Structure

### Semantic Memory Section
- HIGH confidence patterns (5+ examples, most reliable)
- MEDIUM confidence patterns (2-4 examples)
- Technical knowledge and documentation

### Episodic Memory Section
- Recent experiences (last 30 days)
- All experiences (chronological)
- Outcomes and time saved

### Procedural Memory Section
- Workflows and checklists
- Steps and estimated time

### Knowledge Graph
- Total pattern count for topic
- Number of projects using this knowledge
- Related experiences count
- Most valuable pattern (by time saved)

---

## Success Metrics

**Goal**: Find relevant information in < 30 seconds

**Weekly Targets**:
- 10-15 searches performed
- 80%+ result relevance (useful information found)
- 5-10 min saved per search (vs manual review)
- 60%+ searches lead to pattern application

**Integration Flow**:
- `/recall` → Find pattern
- `/switch` → Load project context
- Apply pattern → Save time
- `/learn` → Reinforce pattern

---

## Search Tips

**Be Specific**:
- ❌ "code" (too broad, 100+ results)
- ✅ "authentication code" (focused, 10 results)

**Use Full Context**:
- ❌ "bug" (ambiguous)
- ✅ "payment processing bug" (clear)

**Try Variations**:
- Search "auth", "authentication", "login" (same concept, different terms)

**Domain Prefixes Save Time**:
- `dev:` when you know it's technical
- `client:` when looking for client info
- `pattern:` when specifically seeking patterns

---

## Integration with Other Commands

### Before Work: `/recall` → `/switch`
Search for relevant patterns, then load project context with those patterns available.

### After Work: `/learn` → Creates Searchable Knowledge
Learning extraction makes future `/recall` searches more valuable.

### Weekly Review: `/grow` → Shows Most-Used Searches
Identifies knowledge gaps and high-value patterns.

---

## Knowledge Graph Insights

**Cross-References Show**:
- How many times you've applied a pattern
- Which projects use similar knowledge
- Connections between different topics
- Your expertise areas (HIGH confidence topics)

**Example Output**:
```
🕸️ Knowledge Graph:
- "authentication" appears in 5 patterns
- Used across 3 projects (client-a, client-b, internal)
- 7 related experiences in episodic memory
- 2 workflows reference this topic

💡 Most Valuable:
"JWT Authentication" saved ~4 hours total (6 applications)
```

---

## Progressive Disclosure

**Core operational workflow**: This file (~200 lines)

**Detailed execution**:
- 📖 `Read {baseDir}/references/search-execution.md` - Full 8-step search with tool calls
- 📖 `Read {baseDir}/references/ranking-logic.md` - Result prioritization algorithm
- 📖 `Read {baseDir}/references/output-formatting.md` - Display templates and formatting rules

**Search optimization**:
- 📖 `Read {baseDir}/references/search-tips.md` - Advanced search techniques and query optimization

---

*Last Updated: 2025-01-09*
*Version: 1.0.0*
*Lines: ~200 (entry point) + reference files (on-demand)*
