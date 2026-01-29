# Memory Recall - Result Ranking Logic

Algorithm for prioritizing search results.

## Ranking Priorities

### 1. Exact Title Match (Highest Priority)

```javascript
if (result.title.toLowerCase() === query.toLowerCase()) {
  priority = 1000  // Highest
}
```

**Example**: Query "JWT Authentication" matches pattern titled "JWT Authentication" exactly.

### 2. HIGH Confidence Patterns

```javascript
if (result.type === "pattern" && result.confidence === "HIGH") {
  priority = 900
}
```

**Why**: Patterns with 5+ examples are most reliable and actionable.

### 3. Recent Episodic Experiences (< 30 days)

```javascript
const daysSince = (currentDate - result.date) / (1000 * 60 * 60 * 24)
if (result.type === "episodic" && daysSince < 30) {
  priority = 800
}
```

**Why**: Recent experiences are most relevant to current work context.

### 4. MEDIUM Confidence Patterns

```javascript
if (result.type === "pattern" && result.confidence === "MEDIUM") {
  priority = 700
}
```

### 5. Multiple Search Term Matches

```javascript
const matchCount = countTermMatches(result.content, searchTerms)
priority = 600 + (matchCount * 10)
```

**Why**: More matches = more relevant content.

### 6. LOW Confidence Patterns

```javascript
if (result.type === "pattern" && result.confidence === "LOW") {
  priority = 500
}
```

### 7. Older Episodic Experiences (> 30 days)

```javascript
if (result.type === "episodic" && daysSince >= 30) {
  priority = 400
}
```

### 8. Procedural Workflows

```javascript
if (result.type === "workflow") {
  priority = 300
}
```

### 9. General Knowledge/Documentation

```javascript
if (result.type === "knowledge") {
  priority = 200
}
```

## Tie-Breaking

When priorities are equal:

1. **More recent** (by date)
2. **More examples** (for patterns)
3. **Longer content** (more detailed)
4. **Alphabetical** (stable sort)

## Example Ranking

**Query**: "authentication"

**Results sorted by priority**:
1. "JWT Authentication" pattern (HIGH, exact match) - Priority 1900
2. "API Authentication" pattern (HIGH) - Priority 900
3. "Client A Auth Implementation" episodic (15 days ago) - Priority 800
4. "OAuth 2.0 Setup" pattern (MEDIUM) - Priority 700
5. "Authentication Bug Fix" episodic (45 days ago) - Priority 400
6. "Auth Workflow Checklist" procedural - Priority 300
