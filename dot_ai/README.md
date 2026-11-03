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

## Tool Preferences

[`principles/tool-preferences.md`](principles/tool-preferences.md) is the single source for personal stack defaults and the pre-build stack assessment. Every adapter and the project instruction template direct agents to read it before choosing tools. Keeping preferences separate from skills makes them apply regardless of which skill runs, without duplicating the tool list across adapters.

## Default Workflow

1. Use `virtuous-laziness` for any code change.
2. Handle ordinary implementation directly using the implementer role. Delegate to `implementer` only when an isolated context or separately delegated task provides a concrete benefit.
3. Use `simplifier` when a diff adds files, abstractions, generated code, or feels large.
4. Use `security-reviewer` when trust boundaries, dependencies, inputs, auth, secrets, filesystem, network, or data access change.
5. Use `documentation-steward` when public behavior, setup, APIs, workflows, or architecture change.
6. Use `decision-scribe` when a durable decision, convention, non-goal, or tradeoff should be preserved.

Specialized skills cover discovery and planning, UI/UX design and review, difficult diagnosis, opt-in TDD, architecture review, manual prose decoding, and maintenance of the stack itself. See [`HOW_TO.md`](HOW_TO.md) for invocation examples.

## Discovery and UI/UX Design

Discovery belongs in an `interview` mode of `make-plan`, not a separate agent or skill. It determines what to build and why, producing a user-approved brief before planning or building. Reusing planning keeps the conversation and approval together.

`ui-ux-design` has `design` and `review` modes. It owns how interfaces look and behave and their consistency: a reusable procedure distinct from discovery and execution planning. Visual direction is project-specific and starts from references; mockups and working prototypes are optional. Share a quality bar, not a universal aesthetic.

Make reference-based decisions concrete in project tokens, components, and existing useful docs to prevent drift, without mandating files or a design system. Inspect with available tools and state gaps. Neither workflow requires a new agent, dependency, or browser extension; inspection tooling is a separate, agreed choice.

## Adapter Model

The canonical files in this directory are the source of truth. Tool adapters should stay thin and preserve the same behavior in the format each tool can ingest.

If an adapter and canonical file disagree, update the canonical file first.

The manual-only `unslop` skill is adapted from pstack. See [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

## Adapter Targets

Paths below describe the deployed layout under `~/.ai/`. In this chezmoi source, `.opencode/` and `.claude/` are stored as `dot_opencode/` and `dot_claude/`, respectively.

- OpenCode: `adapters/opencode/.opencode/`, `adapters/opencode/AGENTS.md`, and `adapters/opencode/CONTEXT.md`.
- Claude Code: `adapters/claude-code/CLAUDE.md` and `adapters/claude-code/.claude/`.
- Codex: `adapters/codex/AGENTS.md`.
- Pi or generic tools: `adapters/pi/instructions.md`.
