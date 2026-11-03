# Pi Bootstrap

Use this as the prelude for Pi agents that can read local files.

## Always Load

- `~/.ai/adapters/pi/instructions.md`

## Load By Task

For an underspecified new project or feature, load `~/.ai/skills/make-plan.md` and use `interview` mode in the main conversation. Get brief approval before planning; do not treat it as implementation permission.

For UI proposals (including new screens, layout or navigation changes, and visual references), implementation, or consistency reviews, load `~/.ai/skills/ui-ux-design.md` before suggesting a design or editing UI. Ask one material question at a time about missing design inputs, reuse approved decisions for clear changes, and apply the quality check before handoff. Inspect the rendered interface when tools permit; do not install browser tooling without agreement.

For code changes, work directly and also load:

- `~/.ai/skills/virtuous-laziness.md`

Delegate to `implementer` only when an isolated context or separately delegated task provides a concrete benefit. For that task, also load:

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
