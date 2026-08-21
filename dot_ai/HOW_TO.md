# How to Use the AI Engineering Stack

This guide uses Pi Coding Agent examples. The principles and role triggers also apply to the other adapters.

## Start Pi

Run Pi normally inside a project:

```bash
pi
```

Pi automatically loads:

- Global engineering instructions from `~/.pi/agent/AGENTS.md`.
- Skill names and descriptions from `~/.pi/agent/skills/`.
- Named agents from `~/.pi/agent/agents/` through the subagent extension.
- Project `AGENTS.md` files discovered by Pi.

The full skill instructions, project `CONTEXT.md`, and relevant ADRs are read only when needed.

## Automatic Use

Describe the task normally. Pi should select matching skills and agents from their trigger descriptions.

Examples:

```text
Fix the pagination bug in the users endpoint.
```

Pi should apply `virtuous-laziness` and make the smallest correct change.

```text
Add OAuth login and review the result for security problems.
```

Pi should implement the change and delegate an independent review to `security-reviewer`.

```text
This refactor became much larger than expected. Find a simpler solution.
```

Pi should use `simplicity-review` or delegate to `simplifier`.

## Force a Skill

Use Pi's skill command when you want a specific procedure:

```text
/skill:virtuous-laziness
/skill:simplicity-review
/skill:security-review
/skill:documentation-stewardship
/skill:decision-scribe
/skill:unslop
```

Arguments can follow the command:

```text
/skill:security-review review the current branch against main
```

```text
/skill:simplicity-review inspect my uncommitted changes
```

### Decode AI-Generated Writing

`unslop` is manual-only. It never runs automatically and requires text or a file target.

Decode unclear writing into concrete claims:

```text
/skill:unslop decode @docs/proposal.md
```

Rewrite supplied text without changing its meaning:

```text
/skill:unslop rewrite this text: "Paste the text here."
```

Audit a file for patterns that obscure meaning:

```text
/skill:unslop audit @README.md
```

The skill does not edit the target file unless you explicitly ask it to.

## Request an Agent

Ask Pi to delegate when you want an independent context and perspective:

```text
Use the security-reviewer agent to review the current diff.
```

```text
Have the simplifier inspect this implementation and recommend the smallest safe alternative.
```

```text
Use the decision-scribe to record the architectural decision we just made.
```

Available agents:

| Agent | Use for |
|---|---|
| `implementer` | Isolated or separately delegated implementation work |
| `simplifier` | Large diffs, generated code, unnecessary abstractions, or uncertain designs |
| `security-reviewer` | Auth, input, secrets, dependencies, data, filesystem, network, or trust boundaries |
| `documentation-steward` | Public behavior, setup, APIs, workflows, operations, or architecture |
| `decision-scribe` | Durable decisions, conventions, tradeoffs, non-goals, and boundaries |

Do not invoke every agent for every change. Independent agents are useful only when their perspective reduces risk or future cognitive load.

## Common Workflows

### Ordinary Change

```text
Fix the reported bug. Use the smallest correct change and run relevant tests.
```

The main Pi agent should work directly using `virtuous-laziness`.

For bugs, it should reproduce the failure and verify the fix through the same path. For refactors, it should pin existing behavior and demonstrate equivalence.

### Change and Simplify

```text
Implement this feature, then have the simplifier review the diff. Apply only simplifications that preserve behavior.
```

### Security-Sensitive Change

```text
Implement the authorization change. Then use security-reviewer to inspect the final diff for realistic vulnerabilities.
```

### Documentation Change

```text
Implement the new public API. Then use documentation-steward to update only the documentation affected by the change.
```

### Durable Decision

```text
We chose SQLite instead of PostgreSQL for this local-only tool. Use decision-scribe to record the context, alternatives, and consequences.
```

## Project Memory

Use `CONTEXT.md` for living project knowledge:

- project purpose and values
- domain language
- invariants and boundaries
- conventions and non-goals
- durable decisions
- unresolved questions agents should not guess

Use `docs/adr/NNNN-title.md` for a specific architectural decision with alternatives and consequences.

Start from:

- `~/.ai/templates/CONTEXT.md`
- `~/.ai/templates/adr-template.md`

The decision scribe should record reasoning, not a transcript of actions.

## Review Results

Agent output is advisory. The main agent or human remains responsible for deciding what belongs in the project.

Good review findings should include:

- concrete file references
- realistic impact
- the smallest safe remediation
- explicit uncertainty or testing gaps

Reject suggestions that add more maintenance burden than they remove.

## Troubleshooting

Reload Pi after changing instructions, skills, agents, or extensions:

```text
/reload
```

At startup, Pi's header should show loaded context files, skills, and extensions. Use verbose startup if needed:

```bash
pi --verbose
```

Force-load a skill to distinguish discovery problems from automatic-selection problems:

```bash
pi --skill ~/.ai/skills/security-review.md
```

If `/skill:<name>` commands are missing, verify `enableSkillCommands` is `true` in `~/.pi/agent/settings.json`.

If named agents are unavailable, verify the following paths exist:

```text
~/.pi/agent/agents
~/.pi/agent/extensions/subagent/index.ts
~/.pi/agent/extensions/subagent/agents.ts
```

Reapply the managed configuration when necessary:

```bash
chezmoi apply ~/.ai ~/.pi/agent/AGENTS.md ~/.pi/agent/skills ~/.pi/agent/agents ~/.pi/agent/extensions/subagent
```
