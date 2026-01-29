---
name: plan-status
description: Show current plan progress, completed steps, and what's next
---

# Plan Status Command

Check progress on the current plan. Shows completed steps, current step, blockers, and time tracking.

## Usage

```bash
/plan-status
```

**No arguments needed** - displays status of active plan from `.claude-plan.json`

---

## What This Shows

1. **Plan overview** (goal, project, total steps)
2. **Progress bar** (visual progress indicator)
3. **Completed steps** (what's done)
4. **Current step** (what's next)
5. **Blocked steps** (if any)
6. **Time tracking** (estimated vs actual)
7. **Next actions** (what to do)

---

## Output Format

### Active Plan (In Progress)

```markdown
📋 Plan Status: Add Stripe webhook idempotency

**Plan ID:** plan-20251110-143522
**Project:** client-a-ecommerce
**Created:** 2025-11-10 14:35:22
**Status:** 🟢 Active

---

## Progress

[████████████░░░░░░░░] 60% (3/5 steps)

**Time:**
- Estimated: 40 minutes
- Actual: 23 minutes (58% of estimate)
- Remaining: ~17 minutes

---

## Completed Steps ✅

### Step 1: Read current webhook handler
**Time:** 5 min (estimated 5 min) ✅
**Files:** api/src/webhooks/stripe.ts
**Completed:** 2025-11-10 14:40:22
**Notes:** Understood current implementation

### Step 2: Create webhook_events table
**Time:** 8 min (estimated 8 min) ✅
**Files:** migrations/001_webhook_events.sql
**Completed:** 2025-11-10 14:48:22
**Verification:** Migration ran successfully

### Step 3: Add idempotency check
**Time:** 10 min (estimated 10 min) ✅
**Files:** api/src/webhooks/stripe.ts
**Completed:** 2025-11-10 14:58:22
**Verification:** Test passed - duplicate handling works

---

## Next Step ⏭️

### Step 4: Write test for duplicate webhooks
**Status:** 🟡 Pending (ready to execute)
**Estimate:** 8 minutes
**Files:** api/tests/webhooks/stripe.test.ts
**Action:** Test sending same webhook twice, verify no duplicate processing
**Dependencies:** ✅ Steps 1, 2, 3 complete

**Execute now:**
```bash
/step
```

---

## Remaining Steps

### Step 5: Update documentation
**Status:** ⏸️ Pending (waiting for Step 4)
**Estimate:** 5 minutes
**Files:** docs/stripe-integration.md
**Dependencies:** Waiting for steps 4

---

## Summary

**What's done:**
✅ 3/5 steps complete (60%)
✅ 23 minutes spent (58% of estimate)
✅ All tests passing
✅ No blockers

**What's next:**
→ Execute Step 4 with `/step`
→ ~17 minutes remaining
→ 2 steps to completion

**Checkpoints:**
→ 3 git commits (one per completed step)
→ Resume anytime with `/step`
```

---

### Blocked Plan

```markdown
📋 Plan Status: Deploy to production

**Plan ID:** plan-20251110-150000
**Project:** client-a-ecommerce
**Status:** 🔴 Blocked

---

## Progress

[████░░░░░░░░░░░░░░░░] 20% (1/5 steps)

---

## Completed Steps ✅

### Step 1: Run tests locally
**Time:** 5 min ✅
**Completed:** 2025-11-10 15:05:00

---

## Current Step ⚠️

### Step 2: Deploy to staging
**Status:** 🔴 Blocked
**Blocker:** Waiting for staging credentials from client
**ETA:** Unknown

---

## Blocked Steps

**Steps 2-5** are blocked waiting for Step 2.

---

## What To Do

**Option 1: Resolve blocker**
Contact client for staging credentials

**Option 2: Work on other project**
```bash
/switch internal-saas
/step  # Work on different project
```

**Option 3: Adjust plan**
```bash
/plan Deploy to production (updated)
# Create new plan with adjusted approach
```

---

**Blocked since:** 15 minutes ago
**Last activity:** 2025-11-10 15:05:00
```

---

### Completed Plan

```markdown
🎉 Plan Complete: Add Stripe webhook idempotency

**Plan ID:** plan-20251110-143522
**Project:** client-a-ecommerce
**Completed:** 2025-11-10 15:15:22
**Status:** ✅ Complete

---

## Summary

**Total time:** 38 minutes (estimated 40 minutes)
**Efficiency:** 95% (under estimate ✅)
**Steps:** 5/5 complete
**Files changed:** 4 files
**Tests:** 5 new tests (all passing)

---

## Steps Completed ✅

✅ Step 1: Read webhook handler (5 min)
✅ Step 2: Create webhook_events table (8 min)
✅ Step 3: Add idempotency check (10 min)
✅ Step 4: Write tests (8 min)
✅ Step 5: Update docs (7 min)

---

## Outcomes

**Files changed:**
- api/src/webhooks/stripe.ts (idempotency check added)
- migrations/001_webhook_events.sql (table created)
- api/tests/webhooks/stripe.test.ts (5 tests added)
- docs/stripe-integration.md (documented pattern)

**Quality metrics:**
- ✅ All tests passing
- ✅ All verification criteria met
- ✅ Documentation updated
- ✅ Pattern ready for reuse

---

## Next Actions

**Extract learnings:**
```bash
/learn
```
*Capture the idempotency pattern for future use*

**Update brain health:**
```bash
/grow
```
*Track time saved, patterns learned*

**Start next task:**
```bash
/plan [next goal]
```

---

**Plan archived:** .claude-plan-archive/plan-20251110-143522.json
**Git commits:** 5 checkpoints saved
**Pattern candidates:** Webhook idempotency, database transactions
```

---

### No Plan Found

```markdown
📋 No Active Plan

**No plan file found:** .claude-plan.json

---

## Create a plan

**For complex tasks (>15 minutes):**
```bash
/plan [your goal]
```

**Examples:**
```bash
/plan Add Stripe webhook idempotency
/plan Fix OAuth token refresh bug
/plan Write blog post about React patterns
```

---

## Or use direct commands

**For simple tasks (<15 minutes):**
```bash
/learn     # Extract patterns from recent work
/overview  # Morning planning dashboard
/recall    # Search memory for patterns
```

---

**Need help?**
- `/plan [goal]` - Break task into 5-10 min steps
- `/step` - Execute next step incrementally
- `/plan-status` - Check progress anytime
```

---

## Additional Details

### Time Tracking

**Shows:**
```markdown
**Time Breakdown:**
- Step 1: 5 min (100% of estimate)
- Step 2: 8 min (100% of estimate)
- Step 3: 10 min (100% of estimate)
- Total: 23 min / 40 min (58%)

**Pace:**
- Average: 7.7 min/step
- Estimate accuracy: 100% (very accurate!)
- On track: Yes ✅
```

**Time metrics help:**
- Improve future estimates
- Identify bottlenecks
- Celebrate efficiency

---

### Dependency Visualization

**Shows which steps are blocked:**
```markdown
## Dependency Map

Step 1 ✅
  ├── Step 2 ✅
  │     ├── Step 3 ⏭️ (ready to execute)
  │     └── Step 4 ⏸️ (waiting for Step 3)
  └── Step 5 ⏸️ (waiting for Step 3)

**Legend:**
✅ Complete
⏭️ Ready (all dependencies met)
⏸️ Waiting (dependencies not met)
🔴 Blocked (external blocker)
```

---

### Checkpoint History

**Shows git commits:**
```markdown
## Checkpoints

**Git commits for this plan:**
1. 10bd834 - Step 1/5: Read webhook handler (5 min ago)
2. a3f5221 - Step 2/5: Create webhook_events table (12 min ago)
3. 7b89c45 - Step 3/5: Add idempotency check (just now)

**Can rollback to any step:**
```bash
git checkout 10bd834  # Return to step 1
```

**Or view changes:**
```bash
git log --oneline --grep="Step"
git diff 10bd834..7b89c45  # Changes from step 1 to 3
```
```

---

## Best Practices

### ✅ DO

- **Check status regularly** (after each `/step`)
- **Review time tracking** (improve estimates)
- **Celebrate progress** (3/5 done = 60%!)
- **Use for planning breaks** (end of any step is good stopping point)

### ❌ DON'T

- **Don't ignore blockers** (flag early, switch projects)
- **Don't skip time tracking** (estimates get better over time)
- **Don't lose momentum** (run `/step` when ready)

---

## Integration with Other Commands

### Check Status Before Starting

```bash
/plan-status  # Am I mid-plan?
# If yes: continue with /step
# If no: create plan with /plan [goal]
```

### Check Status During Work

```bash
/step           # Execute next step
/plan-status    # How much done? What's left?
/step           # Continue
```

### Check Status After Break

```bash
# Returning after lunch
/plan-status    # Where was I?
# Shows: "Step 3/5 complete, next: Step 4 (8 min)"
/step           # Resume work
```

---

## Visual Progress Indicators

### Progress Bar

```
[████████████░░░░░░░░] 60%
```

**Calculation:**
```
completed_steps / total_steps × 100
3 / 5 × 100 = 60%
```

### Status Icons

- 🟢 **Active** - Plan in progress, ready to continue
- 🔴 **Blocked** - External blocker, can't proceed
- ✅ **Complete** - All steps done
- ⏸️ **Paused** - No active work (can resume anytime)

### Step Status

- ✅ **Complete** - Done and verified
- ⏭️ **Ready** - Can execute now (dependencies met)
- ⏸️ **Waiting** - Dependencies not met
- 🔴 **Blocked** - External blocker
- ⏭️ **Current** - Next to execute
- ⏸️ **Skipped** - No longer needed

---

## Example Scenarios

### Scenario 1: Mid-Plan Check

```bash
# After completing 3 steps
/plan-status

# Output shows:
# - 60% complete
# - 23 min spent
# - ~17 min remaining
# - Next: Step 4 (ready to execute)

# Decision: Continue
/step
```

---

### Scenario 2: Resuming After Break

```bash
# Next morning
/plan-status

# Output shows:
# - Last activity: Yesterday 4:45 PM
# - 3/5 steps complete
# - Next: Step 4 (ready)
# - No blockers

# Resume
/step
```

---

### Scenario 3: Discovered Blocker

```bash
# During step execution
/step
# Error: Need production credentials

# Check impact
/plan-status

# Output shows:
# - Step 4 blocked (missing credentials)
# - Steps 4-5 can't proceed
# - Suggestion: Switch projects

# Switch to other work
/switch internal-saas
/step  # Work on different project
```

---

### Scenario 4: Plan Complete

```bash
/step
# ✅ Step 5/5 Complete
# 🎉 Plan Complete!

/plan-status

# Output shows:
# - All steps complete
# - Total time: 38 min (95% of estimate)
# - Suggestions: /learn, /grow, new /plan

# Extract learnings
/learn
```

---

## Why This Matters

**Transparency:**
- Know exactly where you are
- See what's left
- Estimate completion time

**Momentum:**
- Visual progress motivates
- Small wins add up
- Clear next action

**Recovery:**
- Resume after breaks easily
- Understand blockers quickly
- Switch projects when needed

**Learning:**
- Time tracking improves estimates
- Identify patterns (steps always take longer than expected?)
- Celebrate efficiency

---

**Check status of current plan anytime**
**Visual progress tracking with time estimates**
