---
name: ralphloop
description: Run the Ralph Loop for the current project. Spawns a subagent for each task iteration until all tasks in TASKS.md are resolved or ignored. Requires /ralphloop-setup to have been run first.
disable-model-invocation: true
argument-hint: [session-label]
allowed-tools: Bash, Agent
---

# Ralph Loop Runner

Run the iterative task loop for the current project. Each iteration spawns a subagent
that works on one task, then the loop checks whether all tasks are complete.

## Step 1 — Pre-flight checks

Run these checks before starting. If any fail, stop and report the error.

**Check `.ralphloop_prompt` exists:**
```bash
test -f .ralphloop_prompt
```
If missing: "No `.ralphloop_prompt` found. Run `/ralphloop-setup` first."

**Check `TASKS.md` exists:**
```bash
test -f TASKS.md
```
If missing: "No `TASKS.md` found. Run `/ralphloop-setup` first."

**Clear any previous done file:**
```bash
rm -f .ralphloop-done
```

## Step 2 — Load the prompt

Read the full contents of `.ralphloop_prompt`. This is the task instruction that will
be passed to every subagent iteration unchanged.

## Step 3 — Announce start

Tell the user:
- "Ralph Loop starting" and the session label if `$ARGUMENTS` was provided
- "Watching for `.ralphloop-done`..."

## Step 4 — The loop

Repeat the following until `.ralphloop-done` exists. Keep an internal iteration count
starting at 1.

**4a. Spawn a subagent**
Spawn a `general-purpose` subagent. Pass the full contents of `.ralphloop_prompt` as
the task. Do not add any additional instructions.

**4b. Discard the result**
When the subagent completes, discard its output entirely. Do not summarize it, repeat
it, store it, or mention what it did. The subagent has already written its results
directly to `TASKS.md`.

**4c. Check the done file**
```bash
test -f .ralphloop-done
```

**4d. Decide**
- If `.ralphloop-done` exists → exit the loop
- If not → increment the iteration count and go to 4a

## Step 5 — Report completion

When the loop exits, tell the user:
- "Ralph Loop complete. All tasks resolved."
- "Total iterations: <count>"
