---
name: make-plan
description: Turns a vague task or existing proposal into a concise, executable plan. Use when the user asks to scope work, break down a task, stress-test a plan, or prepare a PLAN.md before implementation.
---

# Make Plan

## Procedure

1. Restate the desired outcome in one sentence.
2. Inspect the codebase, `CONTEXT.md`, and relevant ADRs before asking questions they can answer.
3. Identify constraints, non-goals, dependencies, risks, and observable success criteria.
4. Ask one material question at a time with a recommended default.
5. When stress-testing, probe fuzzy terms, hidden assumptions, irreversible choices, and concrete failure scenarios.
6. Stop when remaining uncertainty does not block a credible plan.
7. Present steps in dependency order with verification attached.

Return the plan in the response. Create `PLAN.md` only when the user asks.
