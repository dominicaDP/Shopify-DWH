# Memory Recall - Search Tips & Optimization

Advanced search techniques.

## Query Optimization

### Be Specific

❌ **Too broad**: "code"
- Returns 100+ results across all projects
- Most irrelevant

✅ **Specific**: "authentication code"
- Returns 10 focused results
- All relevant

### Use Full Context

❌ **Ambiguous**: "bug"
- Could be any bug in any project

✅ **Clear**: "payment processing bug client a"
- Specific project and system

## Domain Prefixes

### dev: (Technical Only)

```
/recall dev:authentication
```

**Searches**:
- memory/semantic/patterns/dev-patterns.md
- memory/semantic/tech/

**Skips**:
- Client-specific information
- Content patterns

### client: (Client-Specific)

```
/recall client:acme
```

**Searches**:
- memory/semantic/clients/
- memory/episodic/projects/ (filtered)

### pattern: (Patterns Only)

```
/recall pattern:authentication
```

**Searches**:
- memory/semantic/patterns/ only

**Use when**: You know you're looking for a learned pattern, not documentation.

## Search Strategies

### Broad → Narrow

1. Start broad: `/recall authentication`
2. Review results
3. Refine: `/recall dev:jwt authentication`

### Try Variations

Same concept, different terms:
- "auth" vs "authentication" vs "login"
- "bug" vs "issue" vs "problem"
- "deploy" vs "deployment" vs "release"

### Time-Based Filtering

**Recent work**:
```
/recall authentication last-week
```

**This month**:
```
/recall client-a this-month
```

## Common Patterns

### Before Starting Work

```
/recall <topic>          # Have I solved this before?
/recall client:<name>    # What do I know about this client?
/recall pattern:<topic>  # What patterns apply?
```

### During Problem-Solving

```
/recall <specific-error>  # How did I fix this last time?
/recall <technology>      # What patterns exist for this tech?
```

### Before Meetings

```
/recall client:<name>     # Client context
/recall project:<name>    # Project history
```
