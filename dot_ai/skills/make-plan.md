---
name: make-plan
description: Turns a vague task or existing proposal into a concise, executable plan. Use when the user asks to scope work, break down a task, stress-test a plan, or prepare a PLAN.md before implementation.
---

# Make Plan

## Modes

- `draft`: Turn a goal into an execution plan. This is the default.
- `stress-test`: Challenge an existing plan against project language, code, constraints, and concrete edge cases.

## Procedure

1. Restate the desired outcome in one sentence.
2. Inspect the codebase, `CONTEXT.md`, and relevant ADRs before asking questions they can answer.
3. Identify constraints, non-goals, dependencies, risks, and observable success criteria.
4. Ask one material question at a time. Include a recommended answer and why it is the default.
5. In `stress-test` mode, probe fuzzy terms, hidden assumptions, irreversible choices, and concrete failure scenarios.
6. Stop when the remaining uncertainty does not block a credible plan.
7. Present the plan in dependency order with verification attached to the relevant steps.

## Output

Use only sections that add information:

- Goal
- Constraints and non-goals
- Steps
- Verification
- Risks and open questions

Return the plan in the response. Create `PLAN.md` only when the user asks for a file.

Do not turn planning into implementation. Record project context or ADRs only when the user requests it and the decision is durable.
