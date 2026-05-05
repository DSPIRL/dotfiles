---
name: make-plan
description: Interviews the user to turn a task into a concise execution plan and a ready-to-paste PLAN.md draft. Use when the user wants help scoping work, creating an implementation plan, breaking down a task, or preparing a PLAN.md before coding.
disable-model-invocation: true
---

# Make Plan

Turn a vague task into a short, reviewable plan.

## Quick Start

1. Restate the task in one sentence.
2. If the repo can answer obvious questions, inspect it first.
3. Ask one clarifying question at a time.
4. For every question, include a recommended answer.
5. When the task is clear enough, draft `PLAN.md` in markdown.

## Workflow

### 1. Frame the task

- Summarize the task briefly.
- Identify the likely outcome: feature, bug fix, refactor, migration, research, or ops work.
- State any assumptions you are making.

### 2. Inspect before asking

- If the task is code-related, explore the codebase before asking questions the repo can answer.
- Look for existing patterns, constraints, naming, tests, and related files.
- Only ask the user questions that materially change the plan.

### 3. Interview concisely

- Ask questions one at a time.
- Keep each question short and specific.
- After each question, provide `Recommended:` with the answer you think is best.
- Prefer questions about scope, constraints, success criteria, sequencing, and risks.
- Avoid questions that do not affect execution.

### 4. Stop at sufficient clarity

You do not need perfect certainty. Stop asking once you can produce a credible plan with:

- clear goal
- relevant constraints
- execution steps
- validation steps
- open questions called out explicitly

### 5. Draft PLAN.md

Produce a concise markdown draft using this shape:

```md
# Plan

## Goal

## Constraints

## Steps

## Validation

## Open Questions
```

## Style Rules

- Be concise. Do not over-explain.
- Prefer concrete next steps over background theory.
- Recommend defaults when the user is unsure.
- If multiple paths exist, recommend one and briefly say why.
- If the task is blocked on missing information, say exactly what is missing.

## Example Question Style

Question: Should this be a minimal fix or a broader cleanup?

Recommended: Start with the minimal fix unless the surrounding code will otherwise stay confusing or risky.
