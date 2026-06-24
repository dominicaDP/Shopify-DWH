---
name: wrap-up
description: End-of-session routine — review what changed, update each touched project's tracking, run learn-extraction, then commit with a session summary. Use at the end of a work session or when pausing a project.
allowed-tools: Read, Write, Edit, Grep, Bash
---

# Session Wrap-Up Command

Close out a work session cleanly so the next session (yours or a future Claude
instance) can pick up with zero context loss. Orchestrates the end-of-session
ritual: **review → update tracking → learn → commit → summarise.**

This is the codified version of the "Daily Wrap-Up" habit (previously done by hand
as `/learn` + manual tracking updates).

## Execution Steps

### Step 1: Review what changed this session

**Tool: Bash**
```bash
date '+%Y-%m-%d'                 # today's date for any dated entries
git status -s                    # what's modified/untracked
git diff --stat                  # scope of changes
git log --oneline -10            # recent commits for context
```

**Determine:**
- Which **project(s)** were touched (map changed paths → `projects/<name>/`)
- What was actually accomplished vs. what's still open
- Whether anything is blocked or needs the user/another person

### Step 2: Update each touched project's tracking

For **every** project worked on, update its files (only what changed):

- **`projects/<name>/tasks.md`** — check off completed tasks (`[ ]` → `[x]`),
  move them to Completed with the date, add any new/next tasks discovered.
- **`projects/<name>/notes.md`** — append a dated entry with findings, surprises,
  decisions, and numbers worth keeping. Append-only.
- **`projects/<name>/plan.md`** (if it exists) — update the "Resume Here" pointer so
  the next session knows the exact next step.
- **`projects/<name>/context.md`** — only if a decision or constraint changed.

### Step 3: Update the index and current pointer

- **`projects/INDEX.md`** — update status/recent-activity for touched projects if
  they changed materially (e.g. phase complete, project finished).
- **`projects/CURRENT`** — update if the active focus shifted.

### Step 4: Run learning extraction

Invoke the **learn-extraction** skill (i.e. run `/learn`) to:
- Extract new patterns / reinforce existing ones in `memory/semantic/patterns/dev-patterns.md`
- Create an episodic record in `memory/episodic/completed-work/<date>-<slug>.md`
- Update `brain-health/metrics.md`

Skip only if the session was trivial (no reusable learning) — say so explicitly.

### Step 5: Commit the work

**Tool: Bash**
```bash
git branch --show-current        # if on the main/master branch, create a branch first
git add <the work>               # stage deliberately — don't sweep in unrelated changes
```
Commit with a descriptive message. End the message with the standard trailers
(Co-Authored-By + Claude-Session) per the repo's git conventions.

- Branch first if on `master`/`main`.
- Don't commit secrets, generated artifacts, or unrelated working changes.
- Only push if the user asks.

### Step 6: Session summary

**Output to user:**
```
🧹 Session wrapped up — <date>

✅ Accomplished:
- <bullet per meaningful outcome>

📁 Tracking updated:
- <project>: tasks / notes / plan

🧠 Learnings:
- <new/reinforced patterns, or "none — trivial session">

💾 Committed:
- <sha> <subject>  (branch <name>; pushed? yes/no)

➡️ Next up:
- <the single clearest next step, and any blockers / handoffs needed from the user>
```

## When to run

- End of a work session
- Before switching projects (pair with `/switch`)
- After completing a phase, milestone, or significant chunk
- Any time you're about to step away mid-task and want a clean resume point

## Notes

- **Faithful, not flattering:** report what actually happened — if tests failed or a
  step was skipped, say so in the summary.
- **Scope the commit:** stage only this session's work; leave unrelated working-tree
  changes alone.
- **Idempotent-ish:** safe to run repeatedly; it just re-reviews and commits what's new.
- Pairs with: `/learn` (Step 4 uses it), `/switch` (run wrap-up before switching),
  `/overview` (run at the *start* of the next session).
