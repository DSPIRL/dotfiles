---
name: make-plan
description: Interviews users about new projects or features and turns agreed requirements or existing proposals into executable plans. Use for underspecified project or feature requests, requirements discovery, scoping, planning, or stress-testing a proposal.
---

# Make Plan

## Modes

- `interview`: Discover what to build and why. Use when explicitly requested or when a new project or feature is too underspecified to plan responsibly.
- `draft`: Turn a sufficiently understood goal into an execution plan. This is the default otherwise.
- `stress-test`: Challenge an existing plan against project language, code, constraints, and concrete edge cases.

Do not interview well-specified changes or repeat questions answered by the user or project context. Conduct the interview in the main conversation; no separate agent is required.

## Interview

1. Read available project context first. For a new project without a repository, start from the user's goal rather than requiring files.
2. Establish the problem, intended users, current alternatives, and observable outcome before discussing implementation.
3. Ask one material question at a time. Adapt to each answer; offer reasoned defaults for decisions without inventing facts or user preferences.
4. Probe relevant workflows, concrete examples, edge cases, constraints, priorities, and non-goals. Challenge vague terms, contradictions, hidden assumptions, and consequential tradeoffs rather than exhausting a fixed questionnaire.
5. When UI is involved, use `ui-ux-design` for its design-readiness questions and quality bar. Ask about primary tasks, navigation, hierarchy, devices and platform conventions, accessibility, visual references and dislikes, real content and asset availability, and important interaction states. Skip topics already resolved or irrelevant to the task; do not invent visual direction from an underspecified proposal.
6. Stop when remaining uncertainty does not block a credible brief. Separate confirmed requirements from assumptions and unresolved questions; explain the consequence of any material unknown rather than silently deciding it.
7. Present a concise brief covering the outcome, users and workflows, scope and non-goals, constraints, UI requirements when applicable, and observable acceptance criteria. Ask the user to correct or approve it.
8. Wait for approval before drafting an execution plan or building. Brief approval permits planning, not implementation; still obtain stack agreement before scaffolding a new project or making a substantial stack change.

Return the brief in the conversation. Do not create a requirements file or record every interview answer by default.

## Planning Procedure

1. Restate the desired outcome in one sentence.
2. Inspect the codebase, `CONTEXT.md`, and relevant ADRs before asking questions they can answer.
3. Identify constraints, non-goals, dependencies, risks, and observable success criteria.
4. Ask one material question at a time only when it blocks a credible plan. For decisions, include a recommended answer and why it is the default.
5. In `stress-test` mode, probe fuzzy terms, hidden assumptions, irreversible choices, and concrete failure scenarios.
6. Stop when the remaining uncertainty does not block a credible plan.
7. Present the plan in dependency order with verification attached to the relevant steps.

## Planning Output

Use only sections that add information:

- Goal
- Constraints and non-goals
- Steps
- Verification
- Risks and open questions

Return the plan in the response. Create `PLAN.md` only when the user asks for a file.

Do not turn planning into implementation. Record project context or ADRs only when the user requests it and the decision is durable.
