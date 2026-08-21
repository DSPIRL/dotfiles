# Pi Adapter

Use `instructions.md` for tools that support custom instructions but do not have native agents, skills, or repository instruction discovery.

The file compresses the stack into one instruction block. Keep the canonical stack as the source of truth.

## Recommended Setup

This chezmoi repo installs a native Pi integration under `~/.pi/agent/`:

- `AGENTS.md` links to `~/.ai/adapters/pi/instructions.md`.
- `skills/` links to `~/.ai/skills/` for native progressive disclosure.
- `agents/` links to `~/.ai/agents/` for named subagents.
- `extensions/subagent/` links to Pi's bundled subagent extension.

Run `chezmoi apply`, then restart Pi or use `/reload`.

## How It Behaves

Pi always loads the short global `AGENTS.md`. It sees only skill names and descriptions until a matching skill is loaded. The main agent handles ordinary implementation directly and delegates independent review or documentation work only when a trigger is present.

Available named agents:

- `implementer`
- `simplifier`
- `security-reviewer`
- `documentation-steward`
- `decision-scribe`

Use `/skill:<name>` to force a skill when automatic loading does not occur.
