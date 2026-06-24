---
name: session-wrap-up
description: |
  End-of-session routine that closes out work cleanly for zero context loss.
  Reviews what changed (git + open files), updates each touched project's tasks/notes/plan,
  runs learn-extraction to compound patterns, commits the work, and prints a session summary.
  Use at the end of a work session, before switching projects, or after finishing a milestone.
allowed-tools: "Read,Write,Edit,Grep,Bash"
---

# Session Wrap-Up Skill

## Purpose

Codifies the "Daily Wrap-Up" habit into a repeatable routine. The goal is that the
**next** session — whether you or a fresh Claude instance — can resume with full
context: tracking is current, learnings are captured, and work is committed.

Invoked by the `/wrap-up` command. Orchestrates: **review → update tracking → learn → commit → summarise.**

## Routine

### 1. Review
- `date '+%Y-%m-%d'`, `git status -s`, `git diff --stat`, `git log --oneline -10`
- Map changed paths to the project(s) touched; separate real accomplishments from open threads.

### 2. Update tracking (per touched project)
- `projects/<name>/tasks.md` — tick completed, move to Completed (dated), add next tasks
- `projects/<name>/notes.md` — append a dated findings/decisions entry (append-only)
- `projects/<name>/plan.md` — update the "Resume Here" pointer (if the file exists)
- `projects/<name>/context.md` — only if a decision/constraint changed
- `projects/INDEX.md` + `projects/CURRENT` — if status or focus shifted

### 3. Learn
- Run the **learn-extraction** skill (`/learn`): extract/reinforce patterns in
  `memory/semantic/patterns/dev-patterns.md`, create an episodic record under
  `memory/episodic/completed-work/`, update `brain-health/metrics.md`.
- Skip only for trivial sessions — and say so.

### 4. Commit
- Branch first if on `master`/`main`. Stage deliberately (no secrets, no unrelated changes).
- Descriptive message ending with the repo's standard trailers. Push only if asked.

### 5. Summarise
Print: accomplished · tracking updated · learnings · committed (sha/branch/pushed) · next up + blockers.

## Principles

- **Report faithfully** — surface failures, skips, and blockers; don't gloss.
- **Scope the commit** to this session's work only.
- **Sequence over calendar** — leave a clear next step, not a deadline.

## Relationship to other skills

| Skill / command | Role |
|-----------------|------|
| `learn-extraction` (`/learn`) | Used in step 3 — the pattern/episodic extraction |
| `project-switching` (`/switch`) | Run wrap-up *before* switching |
| `daily-overview` (`/overview`) | Run at the *start* of the next session |

## When to use

- End of a work session
- Before switching projects or stepping away mid-task
- After completing a phase, milestone, or significant chunk
