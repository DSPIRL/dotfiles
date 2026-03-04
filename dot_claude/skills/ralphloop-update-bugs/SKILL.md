---
name: ralphloop-update-bugs
description: Add new bugs to the Bugs section of an existing TASKS.md for the current Ralph Loop project. Does not touch Tasks or .ralphloop_prompt.
disable-model-invocation: true
allowed-tools: Read, Write
---

# Update Bugs

Add new bugs to the Bugs section of the existing `TASKS.md` in the current working
directory. Does not modify the Tasks section or `.ralphloop_prompt`.

## Step 1 — Check prerequisites

Read `TASKS.md`. If it does not exist, stop and tell the user:
"No `TASKS.md` found in the current directory. Run `/ralphloop-setup` first."

## Step 2 — Interview the user

Ask for new bugs one at a time. For each bug, collect:
- **Title** — a short description of the bug
- **Priority** — Critical / High / Medium / Low
- **Description** — what is broken, how to reproduce it, and what the expected
  behavior is

After each bug, ask: "Any more bugs to add?"

Continue until the user says no.

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
- [<timestamp>] Bug added via /ralphloop-update-bugs

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
