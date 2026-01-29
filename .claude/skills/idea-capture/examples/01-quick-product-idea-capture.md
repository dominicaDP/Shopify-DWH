# Idea Capture Example: Quick Product Idea

## Scenario
Mid-work on client project, random product idea strikes. Don't want to lose it, but also don't want to context-switch. Need quick capture (< 30 seconds) to keep flow.

## User Input
```
/idea "Add AI-powered code review suggestions to the dashboard - could save developers time reviewing PRs"
```

## Execution

### Step 1: Capture Raw Input
- **Idea**: "Add AI-powered code review suggestions to the dashboard - could save developers time reviewing PRs"
- **Timestamp**: 2025-01-09 14:23

### Step 2: AI Categorization

**Keyword Analysis**:
- "dashboard" → product (UI feature)
- "AI-powered" → product (feature enhancement)
- "developers" → product (user-facing)

**Category**: PRODUCT

### Step 3: AI Priority Detection

**Keyword Analysis**:
- No urgency indicators (urgent, critical, asap)
- No high-priority signals (important, deadline)
- Contains "could" (exploratory, not required)

**Priority**: MEDIUM (good idea, worth exploring)

### Step 4: Generate Metadata

**AI enhancement**:
```markdown
Title: AI-Powered Code Review Dashboard

Why This Matters:
- Developers spend 2-5 hours/week on code reviews
- AI suggestions could reduce review time by 30-50%
- Competitive advantage (most dashboards lack AI features)
- Potential premium feature for pricing tier

Next Steps:
1. Research existing AI code review tools
2. Survey developers: would they pay for this?
3. Prototype with OpenAI API integration
4. Estimate development cost (API costs, UI, logic)
```

### Step 5: Detect Relevant Projects

**Grep search**:
```bash
Grep(
  pattern="dashboard",
  path="projects/",
  output_mode="files_with_matches"
)
```

**Results**:
- `projects/internal-dashboard/context.md`
- `projects/client-a-dashboard/context.md`

**Potential fit**: internal-dashboard (own product)

### Step 6: Write to Idea File

**Tool: Edit**
```bash
Edit(
  file_path="memory/semantic/ideas/product-ideas.md",
  old_string="## Product Ideas\n",
  new_string="## Product Ideas\n\n### AI-Powered Code Review Dashboard\n**Priority**: MEDIUM | **Added**: 2025-01-09\n\n**Idea**: Add AI-powered code review suggestions to the dashboard - could save developers time reviewing PRs\n\n**Why This Matters**:\n- Developers spend 2-5 hours/week on code reviews\n- AI suggestions could reduce review time by 30-50%\n- Competitive advantage (most dashboards lack AI features)\n- Potential premium feature for pricing tier\n\n**Next Steps**:\n1. Research existing AI code review tools\n2. Survey developers: would they pay for this?\n3. Prototype with OpenAI API integration\n4. Estimate development cost (API costs, UI, logic)\n\n**Potential fit**: internal-dashboard project\n\n---\n\n"
)
```

### Step 7: Link to Projects (Optional)

**If strong project fit**, add note to project:
```bash
Edit(
  file_path="projects/internal-dashboard/notes.md",
  old_string="## Ideas\n",
  new_string="## Ideas\n\n- AI-powered code review feature (captured 2025-01-09, see product-ideas.md)\n"
)
```

### Step 8: Show Confirmation

```markdown
💡 Idea captured!

📝 **Idea**: AI-Powered Code Review Dashboard
⭐ **Priority**: MEDIUM
📂 **Category**: Product
📅 **Added**: 2025-01-09 14:23

💾 **Saved to**: memory/semantic/ideas/product-ideas.md

🔗 **Linked to project**: internal-dashboard

✅ **Time**: 12 seconds (didn't break your flow!)

💭 **Next**: Run /recall "product ideas" during weekly review to convert to tasks
```

## Outcome
- **Time**: 12 seconds (< 30 second target ✅)
- **Context preserved**: Back to client work immediately
- **Idea preserved**: Captured with metadata, priority, next steps
- **Future action**: Weekly review will convert to task if priority remains

## Capture Stats After This
- Total ideas captured this week: 5
- Product ideas: 2
- Average capture time: 15 seconds
- Conversion rate (ideas → tasks): 40% (2 of last 5 ideas became tasks)

## Why This Works
1. **Fast**: 12 seconds, no context switch
2. **Smart**: AI categorization + priority (no manual tagging)
3. **Actionable**: "Why it matters" and "Next steps" generated
4. **Organized**: Auto-filed in correct category
5. **Linked**: Connected to relevant project
6. **Traceable**: Timestamped, ready for weekly review
