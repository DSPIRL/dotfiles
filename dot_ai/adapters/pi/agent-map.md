# Pi Agent Map

Use this when Pi supports named agents or personas.

## Base Agent

All agents should inherit:

- `~/.ai/adapters/pi/instructions.md`

## Implementer

Use for feature work, bug fixes, refactors, and project edits.

Prompt files:

- `~/.ai/agents/implementer.md`
- `~/.ai/skills/virtuous-laziness.md`

## Simplifier

Use for large diffs, new abstractions, generated code, or changes that feel larger than the problem.

Prompt files:

- `~/.ai/agents/simplifier.md`
- `~/.ai/skills/simplicity-review.md`

## Security Reviewer

Use for trust boundaries, external input, secrets, auth, dependencies, filesystem, network, database, crypto, or data exposure.

Prompt files:

- `~/.ai/agents/security-reviewer.md`
- `~/.ai/skills/security-review.md`

## Documentation Steward

Use for public behavior, setup, API, workflow, operations, onboarding, or architecture changes.

Prompt files:

- `~/.ai/agents/documentation-steward.md`
- `~/.ai/skills/documentation-stewardship.md`

## Decision Scribe

Use for durable decisions, conventions, non-goals, dependency choices, and abstraction boundaries.

Prompt files:

- `~/.ai/agents/decision-scribe.md`
- `~/.ai/skills/decision-scribe.md`
