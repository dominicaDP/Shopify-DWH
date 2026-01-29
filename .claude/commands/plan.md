---
name: plan
description: Create a structured 5-step plan for complex tasks, breaking them into 10-minute increments
---

# Plan Command

Create a step-by-step plan before starting complex work. Prevents overwhelming tasks, context drift, and helps manage rate limits.

## Usage

```bash
/plan [goal description]
```

**Examples:**
```bash
/plan Add Stripe webhook idempotency to client-a-ecommerce
/plan Create blog post about React Server Actions
/plan Debug production OAuth issue
```

---

## What This Does

1. **Analyzes the goal** - Breaks down into logical steps
2. **Estimates time** - Each step should take ≤10 minutes
3. **Identifies dependencies** - What needs to happen first
4. **Saves plan** - Stores in `.claude-plan.json` for tracking
5. **Provides first step** - Ready to execute with `/step`

---

## Plan Structure

```json
{
  "id": "plan-20251110-143522",
  "goal": "Add Stripe webhook idempotency",
  "created": "2025-11-10T14:35:22Z",
  "project": "client-a-ecommerce",
  "steps": [
    {
      "number": 1,
      "action": "Read current webhook handler code",
      "files": ["api/src/webhooks/stripe.ts"],
      "estimate": "5 min",
      "status": "pending"
    },
    {
      "number": 2,
      "action": "Create webhook_events database table",
      "files": ["migrations/001_webhook_events.sql"],
      "estimate": "8 min",
      "status": "pending",
      "dependencies": [1]
    }
  ],
  "currentStep": 1,
  "totalSteps": 5
}
```

---

## Workflow

### Step 1: Understand the Goal

**Questions to answer:**
- What's the desired outcome?
- What context is needed? (current project, related files)
- What constraints exist? (time, dependencies, complexity)

**Load relevant context:**
```bash
# Check current project
Read projects/CURRENT

# Load project context
Read projects/[project-name]/context.md
Read projects/[project-name]/tasks.md

# Load related patterns
Grep "[related keyword]" memory/semantic/patterns/
```

---

### Step 2: Break Into Steps (5-7 steps ideal)

**Each step should:**
- ✅ Take ≤10 minutes
- ✅ Have clear output (file created, test passing, decision made)
- ✅ Be independently verifiable
- ✅ Build on previous steps

**Step template:**
```markdown
Step N: [Action verb] [specific target]
- Files: [Exact files to read/edit]
- Estimate: [5-10 min]
- Output: [What will exist after this step]
- Verification: [How to know it worked]
```

**Good examples:**
- ✅ "Read webhook handler code (api/src/webhooks/stripe.ts)"
- ✅ "Create webhook_events table migration"
- ✅ "Add idempotency check to handler (lines 45-60)"
- ✅ "Write test for duplicate webhook handling"
- ✅ "Update documentation with idempotency notes"

**Bad examples:**
- ❌ "Fix the webhook system" (too broad)
- ❌ "Improve code quality" (not specific)
- ❌ "Refactor everything" (too big)

---

### Step 3: Identify Dependencies

**Mark dependencies explicitly:**
```json
{
  "number": 3,
  "action": "Add idempotency check",
  "dependencies": [1, 2],  // Requires steps 1 and 2 first
  "blockers": []
}
```

**Common dependency patterns:**
- Read before write (understand before changing)
- Create before use (table before query)
- Test before deploy (verify before commit)

---

### Step 4: Estimate Total Time

**Calculate total time:**
```
5 steps × 8 min average = 40 minutes total
```

**If > 1 hour:**
- ⚠️ Plan too ambitious
- Break into smaller goal
- OR split into multiple sessions

**Example adjustment:**
```
Original goal: "Build complete Stripe integration"
Adjusted goal: "Add webhook idempotency (first of 3 phases)"
```

---

### Step 5: Save Plan

**Write to `.claude-plan.json`:**
```json
{
  "id": "plan-[timestamp]",
  "goal": "[user goal]",
  "created": "[ISO timestamp]",
  "project": "[current project]",
  "steps": [...],
  "currentStep": 1,
  "totalSteps": 5,
  "estimatedMinutes": 40,
  "status": "active"
}
```

**Also create checkpoint:**
```bash
# Save current git state
git add -A
git commit -m "Checkpoint before: [goal]"
```

---

## Output Format

```markdown
📋 Plan Created: Add Stripe webhook idempotency

**Goal:** Prevent duplicate webhook processing in production

**Project:** client-a-ecommerce
**Total Steps:** 5
**Estimated Time:** 40 minutes
**Plan ID:** plan-20251110-143522

---

## Steps

### ✓ Step 1: Read current webhook handler (5 min)
**Files:** api/src/webhooks/stripe.ts
**Output:** Understand current implementation
**Verification:** Can explain how webhooks currently processed

### ⏳ Step 2: Create webhook_events table (8 min)
**Files:** migrations/001_webhook_events.sql
**Output:** Database table with unique constraint on stripe_event_id
**Verification:** Migration runs successfully
**Dependencies:** Step 1

### ⏳ Step 3: Add idempotency check (10 min)
**Files:** api/src/webhooks/stripe.ts (lines 45-60)
**Output:** Check for existing event_id before processing
**Verification:** Test with duplicate event_id returns 200
**Dependencies:** Steps 1, 2

### ⏳ Step 4: Write test for duplicates (8 min)
**Files:** api/tests/webhooks/stripe.test.ts
**Output:** Test sending same webhook twice
**Verification:** Test passes, no duplicate processing
**Dependencies:** Steps 1, 2, 3

### ⏳ Step 5: Update docs (5 min)
**Files:** docs/stripe-integration.md
**Output:** Document idempotency pattern
**Verification:** Docs explain why and how it works
**Dependencies:** Steps 1-4

---

## Next Steps

**Start now:**
```bash
/step
```

**Check progress:**
```bash
/plan-status
```

**Save plan for later:**
Plan saved to `.claude-plan.json`
Resume anytime with `/step`

---

**Estimated completion:** 40 minutes
**Current project:** client-a-ecommerce
**Files to touch:** 4 files (read 1, create 2, update 1)
```

---

## Best Practices

### ✅ DO

- **Start with /plan for any task > 15 minutes**
- **Keep steps small** (≤10 min each)
- **Be specific** (exact files, line numbers)
- **Check current project context first**
- **Save checkpoints** before starting
- **Use `/step` to execute** (don't skip planning)

### ❌ DON'T

- **Don't plan for trivial tasks** (single file edit < 5 min)
- **Don't make steps too big** (>15 min = break down more)
- **Don't skip dependencies** (will cause errors)
- **Don't start without loading project context**
- **Don't ignore time estimates** (if > 1 hour, split goal)

---

## Integration with Other Commands

### Before Planning

```bash
/switch client-a-ecommerce  # Set active project
/recall "webhook"           # Load relevant patterns
```

### During Execution

```bash
/step                       # Execute next step
/plan-status                # Check progress
```

### After Completion

```bash
/learn                      # Extract patterns from this work
/grow                       # Update brain health metrics
```

---

## Handling Complications

### If Step Takes Longer Than Expected

```bash
# Update plan with actual time
Edit .claude-plan.json
# Update step.estimate to actual time
# Adjust remaining estimates

# OR break step into 2 smaller steps
/plan [update] "Split step 3 into 3a and 3b"
```

### If You Hit a Blocker

```bash
# Mark step as blocked
Edit .claude-plan.json
{
  "number": 3,
  "status": "blocked",
  "blocker": "Need staging credentials from client"
}

# Work on non-blocked steps or switch projects
/switch internal-saas
/step  # Work on different project while blocked
```

### If Goal Changes Mid-Plan

```bash
# Save progress
git add -A
git commit -m "WIP: Completed steps 1-3 of webhook plan"

# Create new plan
/plan [new goal]

# Old plan preserved in git history
git log --all --grep="Checkpoint before"
```

---

## Why This Matters

**Prevents common issues:**
- ✅ Context drift (steps too big, lose track)
- ✅ Rate limit hits (no incremental saves)
- ✅ Overwhelm (break big tasks into small wins)
- ✅ Rework (dependencies clear upfront)

**Improves outcomes:**
- ✅ Faster execution (clear next action always)
- ✅ Better quality (each step verified)
- ✅ Learning (steps → patterns via /learn)
- ✅ Momentum (small wins feel good)

---

## Example Plans

### Example 1: Feature Development

```bash
/plan Add real-time notifications to dashboard
```

**Generated plan:**
1. Read current WebSocket setup (5 min)
2. Create notifications table (8 min)
3. Add WebSocket emit on events (7 min)
4. Update frontend to listen (10 min)
5. Test end-to-end (8 min)

**Total:** 38 minutes, 5 steps

---

### Example 2: Bug Fix

```bash
/plan Fix OAuth token refresh failing
```

**Generated plan:**
1. Reproduce bug locally (10 min)
2. Read OAuth handler code (5 min)
3. Add debug logging (5 min)
4. Identify root cause (8 min)
5. Implement fix + test (10 min)

**Total:** 38 minutes, 5 steps

---

### Example 3: Content Creation

```bash
/plan Write blog post about Stripe webhooks
```

**Generated plan:**
1. Outline structure (5 min)
2. Write problem section + example (10 min)
3. Write solution section + code (10 min)
4. Create LinkedIn + video outline (8 min)
5. Review and polish (7 min)

**Total:** 40 minutes, 5 steps

---

## Rate Limit Management

**Why plans help with rate limits:**
- Each step is a checkpoint (can pause/resume)
- Incremental progress saved (no lost work)
- Clear stopping points (end of any step)

**If you hit rate limit mid-plan:**
```bash
# Check progress
/plan-status
# Shows: "Completed 3/5 steps, resume with /step"

# Resume later
/step  # Picks up at step 4
```

---

**Plan created and saved to:** `.claude-plan.json`
**Ready to start:** Run `/step` to execute first step
