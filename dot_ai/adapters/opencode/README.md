# OpenCode Adapter

This adapter is shaped for OpenCode project configuration.

## Contents

- `AGENTS.md` provides root project instructions.
- `CONTEXT.md` provides project memory scaffolding.
- `.opencode/opencode.json` loads root `AGENTS.md` and `CONTEXT.md` instructions.
- `.opencode/agents/` contains role prompts.
- `.opencode/skills/` contains skill directories with `SKILL.md` files.

In this chezmoi source, `.opencode/` is stored as `dot_opencode/`. After `chezmoi apply`, the deployed adapter uses the paths shown above under `~/.ai/adapters/opencode/`.

## Stage the Adapter

```bash
chezmoi apply ~/.ai/adapters/opencode
```

This stages the adapter only. It does not activate OpenCode globally or install configuration into projects. Edit the chezmoi source under `dot_ai/`, not the deployed copies under `~/.ai/`.

## Notes

OpenCode loads config at startup. Restart OpenCode after installing the adapter into a project.

Use the canonical templates when a project already has its own root instruction files and needs a manual merge.
