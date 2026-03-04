---
name: raphloop
description: Run the Ralph Loop for the current project. Spawns a subagent for each task iteration until all tasks in TASKS.md are resolved or ignored. Requires /raphloop-setup to have been run first.
disable-model-invocation: true
argument-hint: [session-label]
allowed-tools: Bash, Agent
---

# Ralph Loop Runner

Run the iterative task loop for the current project. Each iteration spawns a subagent
that works on one task, then the loop checks whether all tasks are complete.

## Step 1 — Pre-flight checks

Run these checks before starting. If any fail, stop and report the error.

**Check `.raphloop_prompt` exists:**
```bash
test -f .raphloop_prompt
```
If missing: "No `.raphloop_prompt` found. Run `/raphloop-setup` first."

**Check `TASKS.md` exists:**
```bash
test -f TASKS.md
```
If missing: "No `TASKS.md` found. Run `/raphloop-setup` first."

**Clear any previous done file:**
```bash
rm -f .raphloop-done
```

## Step 2 — Load the prompt

Read the full contents of `.raphloop_prompt`. This is the task instruction that will
be passed to every subagent iteration unchanged.

## Step 3 — Announce start

Tell the user:
- "Ralph Loop starting" and the session label if `$ARGUMENTS` was provided
- "Watching for `.raphloop-done`..."

## Step 4 — The loop

Repeat the following until `.raphloop-done` exists. Keep an internal iteration count
starting at 1.

**4a. Spawn a subagent**
Spawn a `general-purpose` subagent. Pass the full contents of `.raphloop_prompt` as
the task. Do not add any additional instructions.

**4b. Discard the result**
When the subagent completes, discard its output entirely. Do not summarize it, repeat
it, store it, or mention what it did. The subagent has already written its results
directly to `TASKS.md`.

**4c. Check the done file**
```bash
test -f .raphloop-done
```

**4d. Decide**
- If `.raphloop-done` exists → exit the loop
- If not → increment the iteration count and go to 4a

## Step 5 — Report completion

When the loop exits, tell the user:
- "Ralph Loop complete. All tasks resolved."
- "Total iterations: <count>"
