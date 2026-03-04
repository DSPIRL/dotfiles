# .ralphloop_prompt Template

This is the standard subagent instruction template. When generating `.ralphloop_prompt`,
copy the content between the START and END markers below, then replace all
`{{PLACEHOLDER}}` values with the project-specific answers from the interview.

Do not modify the numbered workflow steps — they are the standard protocol every
subagent must follow exactly.

---
<!-- START TEMPLATE -->
You are running as part of an automated loop. Your job is to complete ONE item from
TASKS.md and then stop. The loop will call you again for the next item.

TASKS.md has two sections: **Tasks** and **Bugs**. Always complete all Tasks before
working on any Bugs.

## Project context

{{PROJECT_DESCRIPTION}}

## Read these files first

Before doing anything else, read these files to understand the project:

{{KEY_FILES}}

Also read `TASKS.md` in full.

## Project-specific instructions

{{PROJECT_SPECIFIC_INSTRUCTIONS}}

## Your workflow — follow this exactly, in order

### Step 1 — Handle stale "In Progress" items

Check every card in TASKS.md (both Tasks and Bugs sections) with `Status: In Progress`.

If any card has `Status: In Progress` and its `Last Updated` timestamp is more than
10 minutes ago, it was left by a crashed previous session. Reset it:
- Change `Status` to `Open`
- Update `Last Updated` to now
- Append to its Agent Log: `- [<timestamp>] Reset from In Progress to Open (stale — previous session likely crashed)`
- Update that section's summary table counts

### Step 2 — Find your item (Tasks first, then Bugs)

**First, look for an Open Task:**
Find the single highest-priority card with `Status: Open` in the **Tasks** section.
Priority order: **Critical → High → Medium → Low**
If two Open Tasks share the same priority, pick the lowest task number (e.g. TASK-003
before TASK-007).

**If no Open Tasks exist, look for an Open Bug:**
Find the single highest-priority card with `Status: Open` in the **Bugs** section.
Use the same priority and tie-breaking rules.

Do not pick any card with `Status: In Progress`, `Resolved`, or `Ignored`.

### Step 3 — If nothing remains

If there are no `Open` Tasks AND no `Open` Bugs, all work is complete:
1. Create a file named `.ralphloop-done` in the current directory with the content
   `All tasks and bugs complete`
2. Stop immediately. Do not do anything else.

### Step 4 — Claim your item

Update the card in TASKS.md:
- Change `Status` to `In Progress`
- Update `Last Updated` to the current date and time
- Append to Agent Log: `- [<timestamp>] Starting task` (for Tasks) or
  `- [<timestamp>] Starting bug fix` (for Bugs)
- Update that section's summary table counts

### Step 5 — Do the work

Complete the item as described in its `Description` field. Focus only on this one item.

### Step 6 — Mark the item complete

Update the card in TASKS.md:
- Change `Status` to `Resolved` if completed, or `Ignored` if not applicable, already
  done externally, or cannot be completed
- Update `Last Updated` to the current date and time
- Append to Agent Log: `- [<timestamp>] Resolved: <one-line summary>` or
  `- [<timestamp>] Ignored: <reason>`
- Update that section's summary table counts

### Step 7 — Log any new issues discovered

**New follow-up tasks** (feature work, improvements): add to the Tasks section
- Assign the next sequential `TASK-NNN` ID
- Set an appropriate priority: Critical / High / Medium / Low
- Set `Status` to `Open`
- Set `Last Updated` to now
- Add Agent Log entry: `- [<timestamp>] Task created by agent during TASK-NNN` or
  `- [<timestamp>] Task created by agent during BUG-NNN`
- Update the Tasks summary table counts

**New bugs discovered** (broken behavior, regressions): add to the Bugs section
- Assign the next sequential `BUG-NNN` ID
- Set an appropriate priority: Critical / High / Medium / Low
- Set `Status` to `Open`
- Set `Last Updated` to now
- Add Agent Log entry: `- [<timestamp>] Bug logged by agent during TASK-NNN` or
  `- [<timestamp>] Bug logged by agent during BUG-NNN`
- Update the Bugs summary table counts

### Step 8 — Stop

You are done for this iteration. Do not attempt to work on any other items.
The loop will call you again.
<!-- END TEMPLATE -->
