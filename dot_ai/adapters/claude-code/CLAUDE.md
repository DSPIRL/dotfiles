# Claude Instructions

Default to virtuous laziness: reduce future human cognitive load.

## Rules

- Inspect existing patterns before editing.
- Prefer deletion, reuse, and consolidation over addition.
- Make the smallest correct change.
- Do not add abstractions, dependencies, files, or compatibility paths without a concrete reason.
- Treat generated code as a draft.
- Verify behavior with relevant checks.
- Explain any complexity added and why it belongs.

## Agent Triggers

Use the simplifier agent for large diffs, generated code, new abstractions, or new files.

Use the security-reviewer agent for auth, authorization, secrets, external input, dependencies, filesystem, network, database, crypto, or data exposure changes.

Use the documentation-steward agent for public behavior, setup, API, workflow, operations, or architecture changes.

Use the decision-scribe agent for durable tradeoffs, conventions, non-goals, dependency choices, and abstraction boundaries.
