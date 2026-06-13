# OpenCode Adapter

This adapter is shaped for OpenCode project configuration.

## Contents

- `AGENTS.md` provides root project instructions.
- `CONTEXT.md` provides project memory scaffolding.
- `.opencode/opencode.json` loads root `AGENTS.md` and `CONTEXT.md` instructions.
- `.opencode/agents/` contains role prompts.
- `.opencode/skills/` contains skill directories with `SKILL.md` files.

## Notes

OpenCode loads config at startup. Restart OpenCode after applying these files.

Use the canonical templates when a project already has its own root instruction files and needs a manual merge.
