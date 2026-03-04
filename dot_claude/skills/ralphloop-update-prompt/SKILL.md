---
name: ralphloop-update-prompt
description: Re-interview the user and rewrite .ralphloop_prompt for the current Ralph Loop project. Does not touch TASKS.md.
disable-model-invocation: true
allowed-tools: Read, Write
---

# Update Prompt

Re-interview the user and rewrite `.ralphloop_prompt` in the current working directory.
Does not modify `TASKS.md`.

## Step 1 — Check prerequisites

Check that `.ralphloop_prompt` exists. If it does not, stop and tell the user:
"No `.ralphloop_prompt` found in the current directory. Run `/ralphloop-setup` first."

## Step 2 — Interview the user

Ask the following questions one at a time:

1. **Project description**: What does this project do? (Can be the same as before or
   updated with new context.)

2. **Key files**: Which files should subagents read first to understand the project?
   (e.g. README.md, ARCHITECTURE.md — list all relevant files)

3. **Project-specific instructions**: Any specific instructions for how tasks should
   be completed? (coding conventions, tools to use, files to avoid, etc.)
   Optional — if none, record "None."

## Step 3 — Rewrite .ralphloop_prompt

Read the prompt template from `~/.claude/skills/ralphloop-setup/prompt-template.md`.

Copy the content between the `<!-- START TEMPLATE -->` and `<!-- END TEMPLATE -->`
markers. Fill in the placeholders:
- `{{PROJECT_DESCRIPTION}}` — answer from question 1
- `{{KEY_FILES}}` — answer from question 2, formatted as a markdown bullet list
  (one file per line, prefixed with `- `)
- `{{PROJECT_SPECIFIC_INSTRUCTIONS}}` — answer from question 3, or "None."

Write the completed content to `.ralphloop_prompt`, replacing the existing file.

## Step 4 — Confirm

Tell the user:
- "`.ralphloop_prompt` updated."
- Next step: run `/ralphloop` to start the loop with the updated instructions.
