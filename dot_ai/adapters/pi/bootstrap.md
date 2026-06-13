# Pi Bootstrap

Use this as the prelude for Pi agents that can read local files.

## Always Load

- `~/.ai/adapters/pi/instructions.md`

## Load By Task

For code changes, also load:

- `~/.ai/skills/virtuous-laziness.md`
- `~/.ai/agents/implementer.md`

For large diffs, generated code, new files, new abstractions, or uncertain implementations, also load:

- `~/.ai/skills/simplicity-review.md`
- `~/.ai/agents/simplifier.md`

For auth, authorization, secrets, external input, dependencies, filesystem, network, database, crypto, or data exposure changes, also load:

- `~/.ai/skills/security-review.md`
- `~/.ai/agents/security-reviewer.md`

For public behavior, setup, APIs, workflows, operations, onboarding, or architecture changes, also load:

- `~/.ai/skills/documentation-stewardship.md`
- `~/.ai/agents/documentation-steward.md`

For durable tradeoffs, conventions, non-goals, dependency choices, or abstraction boundaries, also load:

- `~/.ai/skills/decision-scribe.md`
- `~/.ai/agents/decision-scribe.md`

## Project Memory

When present in the current repo, read:

- `AGENTS.md`
- `CONTEXT.md`
- Relevant files in `docs/adr/`

Do not create docs, ADRs, or reports unless they reduce future confusion.
