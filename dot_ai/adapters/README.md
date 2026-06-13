# Adapters

Adapters package the canonical stack for specific tools.

## Rule

Keep adapters thin. If behavior changes, update the canonical file first, then mirror only the necessary tool-specific wording.

## Available Adapters

- `opencode/` provides `.opencode/` agents, skills, and config.
- `claude-code/` provides `CLAUDE.md`, `.claude/agents/`, and `.claude/skills/`.
- `codex/` provides an `AGENTS.md` instruction file.
- `pi/` provides a generic instruction file for tools without native agents or skills.
