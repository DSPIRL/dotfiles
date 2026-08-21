---
name: virtuous-laziness
description: Applies maintenance-first engineering discipline to implementation and review. Use for code changes where minimal diffs, reuse, deletion, and justified complexity matter.
---

# Virtuous Laziness Skill

## Procedure

1. Inspect existing code, docs, and project context before editing.
2. State the smallest behavior change that satisfies the request.
3. Define success as an observable result before choosing verification.
4. Prefer deletion, reuse, consolidation, or configuration over new code.
5. Add new abstractions only when duplication or domain boundaries justify them.
6. Add dependencies only when they remove more maintenance burden than they add.
7. Verify the real artifact or user path; identify when tests or compilation are only proxies.
8. Inspect delegated diffs and artifacts instead of trusting summaries alone.
9. Explain any complexity added and why it belongs.

## Quality Bar

- The diff is no larger than the problem requires.
- Existing project language is preserved.
- Future maintainers have less to understand, not more.
- Any new concept has a clear owner and reason to exist.
- Verification demonstrates the requested behavior, not merely tool success.
