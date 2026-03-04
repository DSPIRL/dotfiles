# TASKS.md Format Reference

This documents the exact format for `TASKS.md`. Use this when creating or modifying
task files to ensure consistency.

---

## Full file structure

```markdown
# Tasks

## Summary
| Priority | Open | In Progress | Resolved | Ignored |
|----------|------|-------------|----------|---------|
| Critical | 0    | 0           | 0        | 0       |
| High     | 0    | 0           | 0        | 0       |
| Medium   | 0    | 0           | 0        | 0       |
| Low      | 0    | 0           | 0        | 0       |

---

### TASK-001 | Critical | Open
**Title:** Short descriptive title
**Description:** Detailed description of what needs to be done and why.
**Status:** Open
**Last Updated:** 2026-03-04 14:23
**Agent Log:**
- [2026-03-04 14:23] Task created during setup

---

### TASK-002 | High | Open
**Title:** Another task title
**Description:** Another detailed description.
**Status:** Open
**Last Updated:** 2026-03-04 14:23
**Agent Log:**
- [2026-03-04 14:23] Task created during setup

---
```

---

## Rules

### Task IDs
- Format: `TASK-NNN` (zero-padded to 3 digits: TASK-001, TASK-012, TASK-100)
- Always sequential, never reused
- To find the next ID: read existing TASKS.md and increment the highest TASK-NNN found

### Status values
Only these four values are valid:
- `Open` — not yet started
- `In Progress` — currently being worked on by a subagent
- `Resolved` — completed successfully
- `Ignored` — skipped (not applicable, already done externally, or cannot be completed)

### Priority values
Only these four values are valid (in descending priority order):
- `Critical`
- `High`
- `Medium`
- `Low`

### Section header format
```
### TASK-NNN | Priority | Status
```
All three parts must be present and match the values in the card body.

### Timestamps
- Format: `YYYY-MM-DD HH:MM`
- Always use current local time
- Update `Last Updated` every time the task card is modified

### Agent Log
- Append-only — never remove existing entries
- One entry per line, prefixed with `- [YYYY-MM-DD HH:MM] `
- Keep entries concise (one line each)
- Standard entry types:
  - Created: `Task created during setup`
  - Created by agent: `Task created by agent during TASK-NNN`
  - Created via update: `Task added via /raphloop-update-tasks`
  - Started: `Starting task`
  - Stale reset: `Reset from In Progress to Open (stale — previous session likely crashed)`
  - Resolved: `Resolved: <one-line summary of what was done>`
  - Ignored: `Ignored: <reason>`

### Summary table
- Must always reflect the actual counts of tasks at each priority × status combination
- Recount and update after every change to any task's status
- The header row and separator row must not be modified

### Horizontal rules
- Each task card is separated by `---` (a markdown horizontal rule)
- There is also a `---` after the summary table, before the first task card
