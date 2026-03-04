---
name: ralphloop-add-tasks
description: Add new tasks to an existing TASKS.md for the current Ralph Loop project. Does not touch .ralphloop_prompt.
disable-model-invocation: true
allowed-tools: Read, Write
---

# Add Tasks

Add new tasks to the existing `TASKS.md` in the current working directory.

## Step 1 — Check prerequisites

Read `TASKS.md`. If it does not exist, stop and tell the user:
"No `TASKS.md` found in the current directory. Run `/ralphloop-setup` first."

## Step 2 — Collect and analyze each task

For each task, follow this sequence:

**a. Collect details**
Ask for:
- **Title** — a short descriptive title
- **Description** — a detailed description of what needs to be done
- **Priority** — Critical / High / Medium / Low

**b. Analyze for split**
Before recording, evaluate the task against these criteria:
- Does it involve multiple independent systems, components, or files?
- Does it have distinct deliverables that could each stand alone?
- Does it combine unrelated concerns joined by "and"?
- Could different parts warrant different priorities?
- Would a subagent plausibly need multiple sessions to finish it alone?

If two or more criteria apply, propose a split. Present the suggested sub-tasks (each
with a title, description, and priority) and ask:
"Should I create these as separate tasks, keep it as one, or would you like to adjust
the split?"

Accept the user's decision — split, keep, or modify — before moving on.

**c. Continue**
Ask: "Any more tasks to add?" Repeat until the user says no.

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
- [<timestamp>] Task added via /ralphloop-add-tasks

---
```

Refer to `~/.claude/skills/ralphloop-setup/task-format.md` for full format rules
(ID formatting, valid status/priority values, timestamp format, etc.).

## Step 5 — Update the summary table

Recount all tasks by priority and status, then update the summary table in `TASKS.md`
to reflect the new totals.

## Step 6 — Confirm

Report:
- How many tasks were added and their priorities
- The new total Open task count per priority
