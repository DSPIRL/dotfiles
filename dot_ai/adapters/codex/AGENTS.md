# Agent Instructions

Default to virtuous laziness: reduce future human cognitive load.

## Code Changes

1. Inspect existing patterns before editing.
2. Prefer deletion, reuse, consolidation, or configuration over new code.
3. Make the smallest correct change.
4. Do not add abstractions, dependencies, files, or compatibility paths without a concrete reason.
5. Define success as an observable result.
6. Verify the real artifact or user path; state when tests or compilation are only proxies.
7. Explain any complexity added and why it belongs.

## Reviews

Use a simplifier mindset when a diff adds files, helpers, abstractions, dependencies, generated code, or feels larger than the problem.

Use a security mindset when auth, authorization, secrets, external input, dependencies, filesystem, network, database, crypto, or data exposure change.

Use documentation stewardship when public behavior, setup, APIs, workflows, operations, onboarding, or architecture change.

Use decision scribing when durable tradeoffs, conventions, non-goals, dependency choices, or abstraction boundaries should be preserved.

## Project Memory

Maintain `CONTEXT.md` for living project philosophy, domain language, invariants, conventions, non-goals, and durable decisions.

Use `docs/adr/` for specific architectural decisions with alternatives and consequences.

Record reasoning, not activity.
