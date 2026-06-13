# Pi Adapter

Use `instructions.md` for tools that support custom instructions but do not have native agents, skills, or repository instruction discovery.

The file compresses the stack into one instruction block. Keep the canonical stack as the source of truth.

## Minimal Setup

Configure each Pi agent to use this file as its base instruction:

```text
~/.ai/adapters/pi/instructions.md
```

In this chezmoi repo, `dot_ai/` installs to `~/.ai/` after `chezmoi apply`.

## Better Setup

Use `bootstrap.md` as the agent prelude if Pi can read local files. It tells the agent which canonical files to load for each kind of task.

Use `agent-map.md` when Pi supports per-agent prompts or named personas.

## Loading Rule

Do not load every file on every task. Always load `instructions.md`, then load only the agent or skill files whose triggers match the task.
