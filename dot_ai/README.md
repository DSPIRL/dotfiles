# AI Engineering Stack

This stack turns "virtuous laziness" into reusable agent and skill instructions.

The goal is not to make agents produce more. The goal is to make agents reduce future human cognitive load.

See [`HOW_TO.md`](HOW_TO.md) for practical usage, examples, and troubleshooting.

## Operating Principle

Good AI-assisted engineering optimizes for the smallest durable improvement:

- Inspect existing patterns before editing.
- Prefer deletion, reuse, or consolidation over addition.
- Make the smallest correct change.
- Treat every new abstraction, file, dependency, and document as a maintenance cost.
- Record durable decisions so future humans and agents do not re-litigate them.

## Structure

- `principles/` contains the philosophy distilled into rules.
- `workflows/` defines when roles and skills should run.
- `agents/` defines tool-agnostic role prompts.
- `skills/` defines tool-agnostic procedures.
- `templates/` contains project memory and report templates.
- `adapters/` packages the same stack for specific agent tools.

## Default Workflow

1. Use `virtuous-laziness` for any code change.
2. Use `implementer` to make the smallest correct change.
3. Use `simplifier` when a diff adds files, abstractions, generated code, or feels large.
4. Use `security-reviewer` when trust boundaries, dependencies, inputs, auth, secrets, filesystem, network, or data access change.
5. Use `documentation-steward` when public behavior, setup, APIs, workflows, or architecture change.
6. Use `decision-scribe` when a durable decision, convention, non-goal, or tradeoff should be preserved.

## Adapter Model

The canonical files in this directory are the source of truth. Tool adapters should stay thin and preserve the same behavior in the format each tool can ingest.

If an adapter and canonical file disagree, update the canonical file first.

The manual-only `unslop` skill is adapted from pstack. See [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

## Adapter Targets

- OpenCode: `adapters/opencode/.opencode/`, `adapters/opencode/AGENTS.md`, and `adapters/opencode/CONTEXT.md`.
- Claude Code: `adapters/claude-code/CLAUDE.md` and `adapters/claude-code/.claude/`.
- Codex: `adapters/codex/AGENTS.md`.
- Pi or generic tools: `adapters/pi/instructions.md`.
