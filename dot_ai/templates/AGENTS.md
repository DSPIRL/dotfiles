# Agent Instructions

Default to virtuous laziness: reduce future human cognitive load.

## Engineering Rules

- Inspect existing patterns before editing.
- Prefer deletion, reuse, and consolidation over addition.
- Make the smallest correct change.
- Do not add abstractions, dependencies, files, or compatibility paths without a concrete reason.
- Treat generated code as a draft, not evidence of progress.
- Define success as an observable result.
- Verify the real artifact or user path; state when tests or compilation are only proxies.
- Explain any complexity added and why it belongs.

## Agent Triggers

Use a simplifier review for large diffs, generated code, new abstractions, or new files.

Use a security review for auth, authorization, secrets, external input, dependencies, filesystem, network, database, crypto, or data exposure changes.

Use documentation stewardship for public behavior, setup, API, workflow, operations, or architecture changes.

Use decision scribing for durable tradeoffs, conventions, non-goals, dependency choices, and abstraction boundaries.
