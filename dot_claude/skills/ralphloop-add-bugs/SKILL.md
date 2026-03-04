---
name: ralphloop-add-bugs
description: Add new bugs to the Bugs section of an existing TASKS.md for the current Ralph Loop project. Does not touch Tasks or .ralphloop_prompt.
disable-model-invocation: true
allowed-tools: Read, Write
---

# Add Bugs

Add new bugs to the Bugs section of the existing `TASKS.md` in the current working
directory. Does not modify the Tasks section or `.ralphloop_prompt`.

## Step 1 — Check prerequisites

Read `TASKS.md`. If it does not exist, stop and tell the user:
"No `TASKS.md` found in the current directory. Run `/ralphloop-setup` first."

## Step 2 — Collect and analyze each bug

For each bug, follow this sequence:

**a. Collect details**
Ask for:
- **Title** — a short description of the bug
- **Description** — what is broken, how to reproduce it, and what the expected behavior is
- **Priority** — Critical / High / Medium / Low

**b. Analyze for split**
Before recording, evaluate the bug against these criteria:
- Does it describe multiple separate failure modes rather than one root cause?
- Does it affect multiple independent areas of the codebase?
- Could different parts warrant different priorities?

If two or more criteria apply, propose a split. Present the suggested sub-bugs (each
with a title, description, and priority) and ask:
"Should I create these as separate bugs, keep it as one, or would you like to adjust
the split?"

Accept the user's decision — split, keep, or modify — before moving on.

**c. Continue**
Ask: "Any more bugs to add?" Repeat until the user says no.

## Step 3 — Determine next bug ID

Read the Bugs section of `TASKS.md` to find the highest existing `BUG-NNN` ID.
New bugs start at the next number (e.g. if BUG-005 is highest, new bugs begin at
BUG-006). If no bugs exist yet, start at BUG-001.

## Step 4 — Append new bugs

For each new bug, append a card to the Bugs section of `TASKS.md` using this exact
format:

```
### BUG-NNN | Priority | Open
**Title:** <title>
**Description:** <description>
**Status:** Open
**Last Updated:** <YYYY-MM-DD HH:MM>
**Agent Log:**
- [<timestamp>] Bug added via /ralphloop-add-bugs

---
```

Refer to `~/.claude/skills/ralphloop-setup/task-format.md` for full format rules
(ID formatting, valid status/priority values, timestamp format, etc.).

## Step 5 — Update the Bugs summary table

Recount all bugs by priority and status in the Bugs section, then update the Bugs
summary table in `TASKS.md` to reflect the new totals. Do not modify the Tasks
summary table.

## Step 6 — Confirm

Report:
- How many bugs were added and their priorities
- The new total Open bug count per priority
