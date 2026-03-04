---
name: ralphloop-setup
description: Set up a Ralph Loop for the current project. Interviews you to create TASKS.md and .ralphloop_prompt from scratch. Always starts fresh — use /ralphloop-add-tasks, /ralphloop-add-bugs, or /ralphloop-update-prompt to modify existing files.
disable-model-invocation: true
allowed-tools: Read, Write
---

# Ralph Loop Setup

Set up the Ralph Loop for the current project by creating two files in the current
working directory: `TASKS.md` and `.ralphloop_prompt`.

**This is a fresh setup — it overwrites any existing `TASKS.md` and `.ralphloop_prompt`.**
To add tasks to an existing setup, use `/ralphloop-add-tasks`.
To add bugs to an existing setup, use `/ralphloop-add-bugs`.
To update the prompt only, use `/ralphloop-update-prompt`.

## Step 1 — Interview the user

Ask the following questions **one at a time**. Do not generate any files until all
questions have been answered.

1. **Project description**: What does this project do? What is its purpose and tech
   stack?

2. **Key files**: Which files should subagents read at the start of each iteration to
   understand the project? (e.g. README.md, ARCHITECTURE.md, src/index.ts). List as
   many as needed.

3. **Initial tasks**: What tasks need to be completed? For each task:
   a. Ask for a short title, a detailed description, and priority (Critical / High / Medium / Low)
   b. **Analyze for split** — before recording the task, evaluate it using these criteria:
      - Does it involve multiple independent systems, components, or files?
      - Does it have distinct deliverables that could each stand alone?
      - Does it combine unrelated concerns joined by "and"?
      - Could different parts warrant different priorities?
      - Would a subagent plausibly need multiple sessions to finish it alone?
      If two or more criteria apply, propose a split: present the suggested sub-tasks
      (each with a title, description, and priority) and ask the user: "Should I create
      these as separate tasks, keep it as one, or would you like to adjust the split?"
      Accept the user's decision — split, keep, or modify — before moving on.
   c. Ask "Any more tasks to add?" and repeat until the user says no.

4. **Initial bugs**: Are there any known bugs to fix? For each bug:
   a. Ask for a short title, a description of what is broken, how to reproduce it,
      expected behavior, and priority (Critical / High / Medium / Low)
   b. **Analyze for split** — before recording the bug, evaluate it using these criteria:
      - Does it describe multiple separate failure modes rather than one?
      - Does it affect multiple independent areas of the codebase?
      - Could different parts warrant different priorities?
      If two or more criteria apply, propose a split: present the suggested sub-bugs
      (each with a title, description, and priority) and ask the user: "Should I create
      these as separate bugs, keep it as one, or would you like to adjust the split?"
      Accept the user's decision before moving on.
   c. Ask "Any more bugs to add?" and repeat until the user says no.
   This is optional — if none, the Bugs section will be created empty.

5. **Project-specific instructions**: Are there specific instructions for how tasks
   and bugs should be completed? (coding conventions, tools to use, files to avoid, etc.)
   This is optional — if none, record "None."

## Step 2 — Generate TASKS.md

Refer to the format in `task-format.md` for the exact structure. The file has two
sections: Tasks and Bugs.

**Tasks section:**
- Assign sequential IDs starting from TASK-001
- Set all initial statuses to `Open`
- Set `Last Updated` to the current date and time (format: YYYY-MM-DD HH:MM)
- Add an Agent Log entry: `- [<timestamp>] Task created during setup`
- Populate the Tasks summary table with correct Open counts (all other columns are 0)

**Bugs section:**
- Assign sequential IDs starting from BUG-001
- Set all initial statuses to `Open`
- Set `Last Updated` to the current date and time
- Add an Agent Log entry: `- [<timestamp>] Bug logged during setup`
- Populate the Bugs summary table with correct Open counts (all other columns are 0)
- If no bugs were provided, create the Bugs section with an empty card list and all
  zeros in the summary table

Write the completed file to `TASKS.md` in the current working directory.

## Step 3 — Generate .ralphloop_prompt

Refer to `prompt-template.md` for the full subagent instruction template.

Fill in the following placeholders:
- `{{PROJECT_DESCRIPTION}}` — answer from interview question 1
- `{{KEY_FILES}}` — answer from interview question 2, formatted as a markdown bullet
  list (one file per line, prefixed with `- `)
- `{{PROJECT_SPECIFIC_INSTRUCTIONS}}` — answer from interview question 5, or "None."
  if the user did not provide any

Write the completed prompt to `.ralphloop_prompt` in the current working directory.

## Step 4 — Confirm

After writing both files, report:
- The files created and their locations
- The number of tasks added and their priorities
- The number of bugs added and their priorities
- Next step: run `/ralphloop-start` to start the loop
