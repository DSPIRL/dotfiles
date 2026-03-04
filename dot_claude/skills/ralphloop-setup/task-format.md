# TASKS.md Format Reference

This documents the exact format for `TASKS.md`. Use this when creating or modifying
task files to ensure consistency.

The file has two independent sections: **Tasks** and **Bugs**. Tasks are always worked
on first. Bugs are worked on only after all Tasks are Resolved or Ignored.

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

# Bugs

## Summary
| Priority | Open | In Progress | Resolved | Ignored |
|----------|------|-------------|----------|---------|
| Critical | 0    | 0           | 0        | 0       |
| High     | 0    | 0           | 0        | 0       |
| Medium   | 0    | 0           | 0        | 0       |
| Low      | 0    | 0           | 0        | 0       |

---

### BUG-001 | High | Open
**Title:** Short description of the bug
**Description:** What is broken, how to reproduce it, and what the expected behavior is.
**Status:** Open
**Last Updated:** 2026-03-04 14:23
**Agent Log:**
- [2026-03-04 14:23] Bug logged during setup

---
```

---

## Rules

### Task IDs
- Format: `TASK-NNN` (zero-padded to 3 digits: TASK-001, TASK-012, TASK-100)
- Always sequential within the Tasks section, never reused
- To find the next ID: read the Tasks section and increment the highest TASK-NNN found

### Bug IDs
- Format: `BUG-NNN` (zero-padded to 3 digits: BUG-001, BUG-012, BUG-100)
- Always sequential within the Bugs section, never reused
- To find the next ID: read the Bugs section and increment the highest BUG-NNN found
- IDs are independent — TASK-001 and BUG-001 can both exist

### Status values
Only these four values are valid (applies to both Tasks and Bugs):
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
### BUG-NNN | Priority | Status
```
All three parts must be present and match the values in the card body.

### Timestamps
- Format: `YYYY-MM-DD HH:MM`
- Always use current local time
- Update `Last Updated` every time a card is modified

### Agent Log
- Append-only — never remove existing entries
- One entry per line, prefixed with `- [YYYY-MM-DD HH:MM] `
- Keep entries concise (one line each)
- Standard entry types:
  - Created (task): `Task created during setup`
  - Created (bug): `Bug logged during setup`
  - Created by agent (task): `Task created by agent during TASK-NNN`
  - Created by agent (bug): `Bug logged by agent during TASK-NNN` or `Bug logged by agent during BUG-NNN`
  - Created via update (task): `Task added via /ralphloop-add-tasks`
  - Created via update (bug): `Bug added via /ralphloop-add-bugs`
  - Started: `Starting task` / `Starting bug fix`
  - Stale reset: `Reset from In Progress to Open (stale — previous session likely crashed)`
  - Resolved: `Resolved: <one-line summary of what was done>`
  - Ignored: `Ignored: <reason>`

### Summary tables
- Each section (Tasks, Bugs) has its own independent summary table
- Each table must reflect the actual counts for its own section only
- Recount and update the relevant table after every status change
- The header row and separator row must not be modified

### Horizontal rules
- Each card is separated by `---`
- There is also a `---` after each summary table, before the first card in that section
- The `# Bugs` heading acts as the separator between the two sections
