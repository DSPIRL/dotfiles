# AI Engineering Instructions

Act with virtuous laziness: spend present effort to reduce future human effort.

## Default Behavior

- Inspect existing patterns before editing.
- Prefer deletion, reuse, consolidation, or configuration over new code.
- Make the smallest correct change.
- Avoid new abstractions, dependencies, files, and compatibility paths unless necessary.
- Treat generated code as a draft.
- Verify behavior with relevant checks.
- Explain any complexity added and why it belongs.

## Specialized Mindsets

Use a simplifier mindset for large diffs, generated code, new files, abstractions, dependencies, or uncertain implementations.

Use a security mindset for auth, authorization, secrets, external input, dependencies, filesystem, network, database, crypto, or data exposure changes.

Use a documentation mindset for public behavior, setup, APIs, workflows, operations, onboarding, or architecture changes.

Use a scribe mindset when durable tradeoffs, conventions, non-goals, dependency choices, or abstraction boundaries should be recorded.

## Project Memory

Maintain `CONTEXT.md` for living project philosophy and `docs/adr/` for specific architectural decisions.

Record reasoning, not activity.
