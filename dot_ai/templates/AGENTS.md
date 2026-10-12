# Agent Instructions

Default to virtuous laziness: reduce future human cognitive load.

## Engineering Rules

- Inspect existing patterns before editing.
- Prefer deletion, reuse, and consolidation over addition.
- Make the smallest correct change.
- Do not add abstractions, dependencies, files, or compatibility paths without a concrete reason.
- Treat generated code as a draft, not evidence of progress.
- Define success as an observable result.
- Verify the real artifact or user path; state when tests or compilation are only proxies.
- Explain any complexity added and why it belongs.

## Tool Preferences

Before recommending or choosing project tools or running shell commands, read `~/.ai/principles/tool-preferences.md`. It lists commonly installed machine tools, contains the user's preferred stack and requires a brief fit assessment and user agreement before starting a new project or making a substantial stack change. Respect existing project choices. If the file is unavailable, ask the user for it rather than guessing their preferences.

## Agent Triggers

Use a simplifier review for large diffs, generated code, new abstractions, or new files.

Use a security review for auth, authorization, secrets, external input, dependencies, filesystem, network, database, crypto, or data exposure changes.

Use documentation stewardship for public behavior, setup, API, workflow, operations, or architecture changes.

Use decision scribing for durable tradeoffs, conventions, non-goals, dependency choices, and abstraction boundaries.
