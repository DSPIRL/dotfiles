# Claude Code Adapter

This adapter provides shared instructions, agents, and skills in Claude Code's native layout. Claude Code does not read `~/.ai/` automatically; install the adapter at either user or project scope.

## Contents

- `CLAUDE.md` provides shared instructions.
- `.claude/agents/` contains role prompts.
- `.claude/skills/` contains skill directories with `SKILL.md` files.

In this chezmoi source, `.claude/` is stored as `dot_claude/`. After `chezmoi apply`, the deployed adapter uses the paths shown above under `~/.ai/adapters/claude-code/`.

## Stage the Adapter

Apply the adapter before installing it:

```bash
chezmoi apply ~/.ai/adapters/claude-code
```

Edit files under the chezmoi source's `dot_ai/`, not the deployed copies under `~/.ai/`.

## Project Setup

Use project scope when the repository should carry and version the behavior. For a project that has no `CLAUDE.md` or `.claude/` directory:

```bash
cp "$HOME/.ai/adapters/claude-code/CLAUDE.md" ./CLAUDE.md
cp -R "$HOME/.ai/adapters/claude-code/.claude" ./.claude
```

If either destination already exists, merge the adapter files individually. Do not overwrite project instructions, agents, or same-named skills.

For project memory, copy `~/.ai/templates/CONTEXT.md` to the project and add one `@CONTEXT.md` import to its `CLAUDE.md`. Claude Code does not load `CONTEXT.md` automatically.

## User Setup

Use user scope when these should be defaults in every project.

Add this import to `~/.claude/CLAUDE.md`, merging it with any existing instructions:

```markdown
@~/.ai/adapters/claude-code/CLAUDE.md
```

Link non-conflicting agents and skills so adapter updates remain available without copying them again:

```bash
mkdir -p "$HOME/.claude/agents" "$HOME/.claude/skills"
for kind in agents skills; do
  for source in "$HOME/.ai/adapters/claude-code/.claude/$kind/"*; do
    target="$HOME/.claude/$kind/${source##*/}"
    if [ -e "$target" ] || [ -L "$target" ]; then
      printf 'skip existing %s\n' "$target"
    else
      ln -s "$source" "$target"
    fi
  done
done
```

The loop reports existing names without changing them. Review each conflict instead of choosing one implicitly. When `~/.claude/` is managed by chezmoi, represent the import and links under `dot_claude/` rather than creating unmanaged files directly.

Avoid installing the same agents and skills at both user and project scope; duplicate names make ownership and updates unclear.

## Verify

Start a new Claude Code session in the configured scope, then:

1. Run `/memory` and confirm the expected `CLAUDE.md` files are loaded.
2. Run `/agents` and confirm the adapter agents are available.
3. Invoke `/virtuous-laziness` and confirm the skill is discovered.
