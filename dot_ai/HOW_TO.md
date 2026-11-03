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

## Preferred Tools and New Projects

Edit `dot_ai/principles/tool-preferences.md` in this chezmoi source, then apply it to `~/.ai/principles/tool-preferences.md`, to change your defaults once for all adapters.

For example:

```text
I want to build a desktop app for tracking expenses. Assess my preferred stack before building anything.
```

The agent should recommend a stack, explain fit and meaningful drawbacks, and wait for agreement before scaffolding. See [`principles/tool-preferences.md`](principles/tool-preferences.md) for the defaults. Existing projects keep their established stack unless a change is justified and agreed.

Pi's global instructions already link to the adapter in this repository. Merely installing `~/.ai/` does not make other tools read it. For Claude Code, follow [`adapters/claude-code/README.md`](adapters/claude-code/README.md) to install its instructions, agents, and skills at user or project scope. For Codex and OpenCode, load the corresponding instruction file from `~/.ai/adapters/` through the tool's global or project instructions. Merge with existing instructions rather than overwriting them.

For remote or chat-only assistants without access to `~/.ai/`, include the preference file's contents in their instructions or attach it to the conversation. No file on your machine can automatically configure every AI service.

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

```text
I want to build a shared expense tracker, but I haven't worked out the requirements yet.
```

Pi should use `make-plan` to interview you in the main conversation before planning or building. See [Plan Work](#plan-work).

## Force a Skill

Use Pi's skill command when you want a specific procedure:

```text
/skill:virtuous-laziness
/skill:simplicity-review
/skill:security-review
/skill:documentation-stewardship
/skill:decision-scribe
/skill:unslop
/skill:make-plan
/skill:ui-ux-design
/skill:diagnose
/skill:tdd
/skill:architecture-review
/skill:maintain-ai-skill
```

Arguments can follow the command:

```text
/skill:security-review review the current branch against main
```

```text
/skill:simplicity-review inspect my uncommitted changes
```

### Plan Work

`make-plan` supports `interview`, `draft`, and `stress-test` modes. Underspecified new-project or feature requests start with an adaptive interview in the main conversation. Request it explicitly with:

```text
/skill:make-plan interview help me define a shared expense tracker
```

Pi asks one material question at a time, including UI requirements when relevant. Once consequential uncertainty is resolved, it presents a brief separating confirmed requirements, assumptions, and open questions, then waits for your approval before planning or building.

Draft a plan from an agreed goal:

```text
/skill:make-plan draft a migration from SQLite to PostgreSQL
```

Stress-test an existing proposal against the codebase and project context:

```text
/skill:make-plan stress-test @PLAN.md
```

The skill returns the brief or plan in the conversation; it creates no files automatically. Ask explicitly if you want a plan written to `PLAN.md`. Approval to plan is not approval to implement.

### Design or Review UI

`ui-ux-design` supports `design` (default) for UI design and implementation, and `review` for visual-consistency reviews:

```text
/skill:ui-ux-design design the settings screens for this project
```

```text
/skill:ui-ux-design review the dashboard and settings screens for visual consistency
```

Ordinary proposals should trigger the skill too; you do not need to say "design" or invoke a command:

```text
I'd like to add a dashboard and make the app feel more premium.
```

The agent reads existing context and asks one material question at a time about missing users/tasks, visual direction, real content/assets, devices, and important states. It stops when a credible direction and acceptance criteria can be summarized, seeking approval for new direction before broad implementation. Clear changes reuse approved decisions; scoped reviews should not trigger an unrelated project interview.

Before handoff, it checks visual fundamentals, content and assets, cross-screen consistency, platform behavior, and rendered evidence—not just whether the components compile. These are model instructions, not a runtime guarantee.

Apply updated files with `chezmoi apply ~/.ai`, then run `/reload` in Pi before invoking the skill. If the skill is installed but automatic selection misses a proposal, force `/skill:ui-ux-design`. See [Troubleshooting](#troubleshooting) for discovery checks.

Discuss project-specific references and agree on direction first, preserving the existing design language. Work with concrete tokens and components, keeping screens and states consistent. Mockups or prototypes are optional and used only by agreement to resolve uncertainty; neither a prototype nor a design system is required.

Use available browser inspection for rendered UI; if unavailable, provide screenshots for review. Browser tooling is not bundled or installed automatically. The agent must state what it inspected and what remains unverified, and must not claim verification without a tool result or provided artifact.

### Diagnose a Difficult Failure

```text
/skill:diagnose investigate why this request intermittently times out
```

The skill builds a reproducible feedback loop, tests falsifiable hypotheses, and verifies the fix through the original path.

### Use Test-Driven Development

```text
/skill:tdd add support for expiring invitations
```

TDD is opt-in. It uses one observable behavior per red-green cycle and does not force brittle tests when a cheaper proof is stronger.

### Review Architecture

```text
/skill:architecture-review find evidence-backed opportunities to simplify the billing modules
```

The skill reports candidates and waits for you to choose one before implementation.

### Maintain This Stack

`maintain-ai-skill` is manual-only:

```text
/skill:maintain-ai-skill add a reusable database migration review skill
```

It checks for overlap, edits canonical files first, and updates only the adapters and documentation that are necessary.

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
