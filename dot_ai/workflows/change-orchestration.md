# Change Orchestration

Use explicit triggers. Do not run every agent for every task.

## Default Flow

1. Inspect the codebase and project context.
2. Apply the `virtuous-laziness` skill.
3. Use the implementer role for the smallest correct change.
4. Verify the observable result through the real artifact or user path when feasible.
5. Invoke follow-up roles only when their triggers are present.
6. Record durable decisions only when future agents would benefit.

## Task-Specific Flows

For a bug, reproduce the failure, identify its mechanism, make the smallest fix, and verify through the original failing path.

For a refactor, pin current behavior with a characterization test or equivalence check. Reshape in verifiable units without adding behavior changes.

For a small but risky change, identify the load-bearing safety assumption, trace beyond direct callers, and prove it or mark it unproven.

## Role Triggers

Use `simplifier` when the change adds files, abstractions, helpers, generated code, or a large diff.

Use `security-reviewer` when the change touches auth, authorization, external input, secrets, dependencies, filesystem, network, database, crypto, or data exposure.

Use `documentation-steward` when the change affects public behavior, setup, operations, APIs, workflows, architecture, or onboarding.

Use `decision-scribe` when the work establishes a durable convention, rejects an approach, chooses a dependency, defines a boundary, or clarifies a project value.

## Stop Conditions

- Do not create process artifacts for trivial changes.
- Do not write documentation unless it reduces future confusion.
- Do not write ADRs for reversible local implementation details.
- Do not let agents debate indefinitely. Prefer concrete diffs, findings, or documented decisions.
- Do not treat compilation, passing proxies, or agent summaries as proof of user-visible behavior.
