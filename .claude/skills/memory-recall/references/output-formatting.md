# Memory Recall - Output Formatting

Display templates for search results.

## Output Structure

```markdown
# 🔍 Recall: "<search_query>"

## Semantic Memory (What You Know)

[HIGH confidence patterns]
[MEDIUM confidence patterns]
[Technical knowledge]

## Episodic Memory (What You've Done)

[Recent experiences < 30 days]
[All experiences]

## Procedural Memory (How You Do Things)

[Workflows and checklists]

## Knowledge Graph

[Cross-references and connections]

---

**Found:** <N> results
**Most recent:** <X> days ago
**Next action:** <suggestion>
```

## Section Templates

### HIGH Confidence Pattern

```markdown
### High Confidence Patterns
⭐ **Pattern Name** (HIGH confidence, 6 examples)
Location: memory/semantic/patterns/dev-patterns.md#pattern-name

Summary: [1-2 sentence description]
When to use: [use case]
Time saved: ~4 hours total (6 applications)
Last updated: 2025-01-09
```

### Recent Experience

```markdown
### Recent Experiences (Last 30 days)
📝 **Experience Title** (2025-01-09)
Location: memory/episodic/code/2025-01-09-slug.md

What: [description]
Pattern applied: Pattern Name (saved 60 min)
Result: ✅ SUCCESS
```

### Workflow

```markdown
### Workflows
🔧 **Workflow Name**
Location: memory/procedural/workflows/workflow-name.md

Steps: 5 steps, ~30 min
Last used: Client A project (2025-01-05)
```

### Knowledge Graph

```markdown
## Cross-References

🕸️ **Knowledge Graph:**
- "authentication" appears in 5 patterns
- Used across 3 projects (client-a, client-b, internal)
- 7 related experiences in episodic memory
- 2 workflows reference this topic

💡 **Most Valuable:**
"JWT Authentication" has saved ~4 hours total
(applied 6 times, 40 min saved each)

📊 **Confidence:**
Authentication knowledge: STRONG
3 HIGH confidence patterns, 2 MEDIUM, 1 LOW
```
