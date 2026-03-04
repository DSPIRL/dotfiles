---
name: raphloop-update-tasks
description: Add new tasks to an existing TASKS.md for the current Ralph Loop project. Does not touch .raphloop_prompt.
disable-model-invocation: true
allowed-tools: Read, Write
---

# Update Tasks

Add new tasks to the existing `TASKS.md` in the current working directory.

## Step 1 — Check prerequisites

Read `TASKS.md`. If it does not exist, stop and tell the user:
"No `TASKS.md` found in the current directory. Run `/raphloop-setup` first."

## Step 2 — Interview the user

Ask for new tasks one at a time. For each task, collect:
- **Title** — a short descriptive title
- **Priority** — Critical / High / Medium / Low
- **Description** — a detailed description of what needs to be done

After each task, ask: "Any more tasks to add?"

Continue until the user says no.

## Step 3 — Determine next task ID

Read the existing `TASKS.md` to find the highest existing `TASK-NNN` ID.
New tasks start at the next number (e.g. if TASK-007 is highest, new tasks begin at
TASK-008).

## Step 4 — Append new tasks

For each new task, append a task card to `TASKS.md` before the end of the file,
using this exact format:

```
### TASK-NNN | Priority | Open
**Title:** <title>
**Description:** <description>
**Status:** Open
**Last Updated:** <YYYY-MM-DD HH:MM>
**Agent Log:**
- [<timestamp>] Task added via /raphloop-update-tasks

---
```

Refer to `~/.claude/skills/raphloop-setup/task-format.md` for full format rules
(ID formatting, valid status/priority values, timestamp format, etc.).

## Step 5 — Update the summary table

Recount all tasks by priority and status, then update the summary table in `TASKS.md`
to reflect the new totals.

## Step 6 — Confirm

Report:
- How many tasks were added and their priorities
- The new total Open task count per priority
