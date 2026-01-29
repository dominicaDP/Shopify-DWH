---
name: step
description: Execute the next step in the current plan incrementally
---

# Step Command

Execute exactly one step from the active plan. Prevents context drift, manages rate limits, and ensures incremental progress.

## Usage

```bash
/step
```

**No arguments needed** - automatically loads current plan and executes next pending step.

---

## What This Does

1. **Loads active plan** from `.claude-plan.json`
2. **Identifies next step** (first pending step with dependencies met)
3. **Executes step** (reads files, makes changes, verifies)
4. **Updates plan** (marks step complete, saves progress)
5. **Creates checkpoint** (git commit with step details)
6. **Shows next action** (what to do next)

---

## Prerequisites

**Must have active plan:**
```bash
# Check if plan exists
Read .claude-plan.json

# If no plan exists, create one
/plan [your goal]
```

**Plan must be active:**
```json
{
  "status": "active",  // Not "completed" or "blocked"
  "currentStep": 3     // Has pending steps
}
```

---

## Execution Flow

### Step 1: Load Plan

```bash
# Read plan file
Read .claude-plan.json

# Verify:
- Plan exists
- Plan is active (not completed/blocked)
- Has pending steps
- Dependencies met for next step
```

**If no plan:**
```
❌ No active plan found

Create a plan first:
/plan [your goal]

Example:
/plan Add Stripe webhook idempotency
```

---

### Step 2: Identify Next Step

**Find first pending step with dependencies met:**
```json
{
  "steps": [
    { "number": 1, "status": "completed" },
    { "number": 2, "status": "completed" },
    { "number": 3, "status": "pending", "dependencies": [1, 2] },  // ← NEXT
    { "number": 4, "status": "pending", "dependencies": [3] }
  ]
}
```

**Dependency logic:**
```typescript
function getNextStep(plan) {
  return plan.steps.find(step => {
    if (step.status !== 'pending') return false;

    // Check all dependencies completed
    const allDepsMet = step.dependencies.every(depNum => {
      const dep = plan.steps.find(s => s.number === depNum);
      return dep && dep.status === 'completed';
    });

    return allDepsMet;
  });
}
```

---

### Step 3: Execute Step

**Load context for this step:**
```bash
# Read files specified in step
Read [step.files[0]]
Read [step.files[1]]
...

# Load relevant memory
Grep "[keywords from step.action]" memory/semantic/patterns/
```

**Perform step action:**
```markdown
Step 3: Add idempotency check to webhook handler

Action: Edit api/src/webhooks/stripe.ts (lines 45-60)

Tasks:
1. Read current webhook handler
2. Add event ID lookup before processing
3. Return 200 if already processed
4. Update comments to explain idempotency
```

**Execute with appropriate tools:**
- Read files: `Read [file]`
- Edit files: `Edit [file]` (specific changes only)
- Create files: `Write [file]`
- Run tests: `Bash pytest [test]` or `Bash npm test`
- Verify: Check output matches step.verification

---

### Step 4: Verify Step Completion

**Check verification criteria:**
```json
{
  "verification": "Test with duplicate event_id returns 200"
}
```

**Run verification:**
```bash
# Example: Run test
Bash npm test -- webhooks/stripe.test.ts

# Check output
✓ handles duplicate webhook gracefully (45ms)
✓ returns 200 for already-processed event (12ms)

# Verification passed ✅
```

**If verification fails:**
```markdown
⚠️  Verification failed: Test returned 500 instead of 200

Debugging:
1. Check error logs
2. Review changes made
3. Fix issue
4. Re-run verification

Do NOT mark step complete until verification passes.
```

---

### Step 5: Update Plan

**Mark step complete:**
```json
{
  "steps": [
    ...,
    {
      "number": 3,
      "status": "completed",        // ← Updated
      "completedAt": "2025-11-10T15:22:18Z",  // ← Added
      "actualTime": "12 min",       // ← Actual vs estimate
      "notes": "Test passed first try"
    }
  ],
  "currentStep": 4,                 // ← Incremented
  "progress": "3/5 (60%)"          // ← Updated
}
```

**Save to `.claude-plan.json`:**
```bash
Write .claude-plan.json
```

---

### Step 6: Create Checkpoint

**Git commit after each step:**
```bash
git add -A
git commit -m "$(cat <<'EOF'
Step 3/5: Add idempotency check to webhook handler

Plan: Add Stripe webhook idempotency
File: api/src/webhooks/stripe.ts
Time: 12 min (estimated 10 min)

Changes:
- Added event_id lookup before processing
- Return 200 if already processed
- Updated tests to verify duplicate handling

Verification: ✅ Test passed
Next: Step 4 - Write test for duplicates
EOF
)"
```

**Why checkpoint after each step:**
- ✅ Incremental progress saved (no lost work)
- ✅ Easy rollback if next step fails
- ✅ Clear history of what changed when
- ✅ Rate limit recovery (can resume from any step)

---

### Step 7: Show Next Action

**Output summary:**
```markdown
✅ Step 3/5 Complete: Add idempotency check

**What was done:**
- Edited api/src/webhooks/stripe.ts
- Added event ID lookup logic
- Updated tests
- Verified with test suite (2 tests passing)

**Time:** 12 minutes (estimated 10 minutes)

---

📊 **Progress:** 3/5 steps complete (60%)

**Next Step:**
Step 4/5: Write test for duplicate webhooks (8 min)

**Files:** api/tests/webhooks/stripe.test.ts
**Action:** Test sending same webhook twice, verify no duplicate processing

**Run next step:**
```bash
/step
```

**Or check full status:**
```bash
/plan-status
```

**Estimated time remaining:** 13 minutes (2 steps left)
```

---

## Output Format

### Success Output

```markdown
✅ Step [N]/[Total] Complete: [Step description]

**Files changed:**
- [file1]: [what changed]
- [file2]: [what changed]

**Verification:** ✅ [verification result]

**Time:** [actual] (estimated [estimate])

---

📊 Progress: [N]/[Total] steps ([percentage]%)

**Next:** Step [N+1]/[Total]: [description] ([estimate])

Run `/step` to continue
```

### Blocked Output

```markdown
⚠️  Step [N] Blocked: [reason]

**Blocker:** [description]

**What to do:**
1. [Resolution step 1]
2. [Resolution step 2]

**OR work on other steps:**
[List of non-blocked steps if any]

**OR switch projects:**
```bash
/switch [other-project]
/step  # Work on different project
```
```

### Plan Complete Output

```markdown
🎉 Plan Complete: [goal]

**Total time:** [actual] (estimated [estimate])
**Steps completed:** [total]
**Files changed:** [count]

**Summary:**
✅ Step 1: [description] ([time])
✅ Step 2: [description] ([time])
✅ Step 3: [description] ([time])
✅ Step 4: [description] ([time])
✅ Step 5: [description] ([time])

---

## Next Actions

**Extract learnings:**
```bash
/learn
```
*What patterns did you discover? Save to semantic memory.*

**Update brain health:**
```bash
/grow
```
*Track progress and celebrate 🎉*

**Start new task:**
```bash
/plan [next goal]
```

---

**Plan archived:** .claude-plan-archive/plan-[id].json
```

---

## Special Cases

### Parallel Steps (No Dependencies)

**If multiple steps have no dependencies:**
```json
{
  "steps": [
    { "number": 1, "status": "completed" },
    { "number": 2, "status": "pending", "dependencies": [1] },
    { "number": 3, "status": "pending", "dependencies": [1] },  // ← Both can run
  ]
}
```

**Execution:**
```
/step
# Executes step 2 (first pending)

/step
# Executes step 3 (next pending)
```

**Note:** Steps run sequentially, not in parallel (prevents file conflicts).

---

### Updating Estimates Mid-Plan

**If step takes longer than expected:**
```markdown
Step 3 took 25 min (estimated 10 min)

Update plan:
- Record actual time
- Adjust remaining estimates
- Flag if total time > 1 hour
```

**Updated plan:**
```json
{
  "steps": [
    {
      "number": 3,
      "estimate": "10 min",
      "actualTime": "25 min",
      "notes": "OAuth debugging more complex than expected"
    }
  ],
  "estimatedMinutes": 40,
  "actualMinutesUsed": 48,  // Running total
  "warningIssued": true     // Flag if over estimate
}
```

---

### Skipping Steps

**If step no longer needed:**
```bash
# Mark as skipped instead of completed
Edit .claude-plan.json
{
  "number": 4,
  "status": "skipped",
  "reason": "Feature requirements changed, test not needed"
}

# Continue with /step
/step  # Moves to step 5
```

---

## Integration with Other Commands

### Before Each Step

```bash
# Optional: Check plan status first
/plan-status

# Execute step
/step
```

### After Step Completion

```bash
# Continue immediately
/step

# OR take a break
/plan-status  # Check progress
# Resume later with /step
```

### After Plan Completion

```bash
/learn   # Extract patterns
/grow    # Update metrics
```

---

## Error Handling

### Error: No Plan Found

```markdown
❌ No active plan found

**Create a plan:**
```bash
/plan [goal]
```

**Or check plan status:**
```bash
ls -la .claude-plan.json  # Verify file exists
```
```

### Error: Plan Already Complete

```markdown
✅ Plan already complete: [goal]

**Start new plan:**
```bash
/plan [new goal]
```

**Or review completed plan:**
```bash
Read .claude-plan-archive/plan-[id].json
```
```

### Error: All Steps Blocked

```markdown
⚠️  All remaining steps are blocked

**Blockers:**
- Step 3: Waiting for staging credentials
- Step 4: Waiting for step 3
- Step 5: Waiting for step 3

**Resolve blockers or switch projects:**
```bash
/switch [other-project]
/step  # Work on different project
```
```

### Error: Verification Failed

```markdown
❌ Step verification failed

**Step 3:** Add idempotency check
**Verification:** Test with duplicate event_id returns 200
**Result:** Test returned 500 (Internal Server Error)

**Debug:**
1. Check error logs: [error message]
2. Review changes: [what was modified]
3. Fix issue
4. Re-run: /step (will retry current step)

**Do NOT mark complete until verification passes.**
```

---

## Best Practices

### ✅ DO

- **Run /step for each step** (don't skip planning)
- **Verify before marking complete**
- **Review checkpoint commit** after each step
- **Update estimates** if steps take longer
- **Take breaks between steps** (avoid burnout)

### ❌ DON'T

- **Don't execute multiple steps manually** (use /step for each)
- **Don't skip verification** (causes issues later)
- **Don't ignore blockers** (mark blocked, switch projects)
- **Don't force completion** if verification fails
- **Don't lose incremental progress** (checkpoint saves work)

---

## Rate Limit Strategy

**How /step helps with rate limits:**

**Traditional approach (no planning):**
```
Work for 30 minutes → Hit rate limit → Lose context → Start over tomorrow
```

**With /step:**
```
/step (5 min) → Checkpoint ✅
/step (8 min) → Checkpoint ✅
/step (10 min) → Hit rate limit
Resume tomorrow: /step (picks up exactly where left off)
```

**Benefits:**
- ✅ Incremental progress saved
- ✅ No lost work
- ✅ Clear resumption point
- ✅ Context preserved in plan

---

## Why This Matters

**Prevents:**
- ❌ Context drift (steps too big, lose track)
- ❌ Overwhelm (entire goal feels huge)
- ❌ Rework (verification catches issues early)
- ❌ Rate limit waste (incremental checkpoints)

**Enables:**
- ✅ Momentum (small wins feel good)
- ✅ Quality (each step verified)
- ✅ Learning (clear progression)
- ✅ Recovery (can resume from any step)

---

## Example Session

```bash
# Create plan
/plan Add Stripe webhook idempotency

# Execute steps one by one
/step
# ✅ Step 1/5 Complete: Read webhook handler (5 min)

/step
# ✅ Step 2/5 Complete: Create webhook_events table (8 min)

/step
# ✅ Step 3/5 Complete: Add idempotency check (12 min)

# Take a break, resume later...

/step
# ✅ Step 4/5 Complete: Write tests (8 min)

/step
# ✅ Step 5/5 Complete: Update docs (5 min)
# 🎉 Plan Complete! Total: 38 minutes

# Extract learnings
/learn

# Update metrics
/grow
```

---

**Execute next step in current plan**
**Incremental progress with automatic checkpoints**
