---
id: virtuous-laziness
kind: skill
trigger: Any code change or implementation review.
---

# Virtuous Laziness Skill

## Procedure

1. Inspect existing code, docs, and project context before editing.
2. State the smallest behavior change that satisfies the request.
3. Prefer deletion, reuse, consolidation, or configuration over new code.
4. Add new abstractions only when duplication or domain boundaries justify them.
5. Add dependencies only when they remove more maintenance burden than they add.
6. Verify behavior with the narrowest relevant checks.
7. Explain any complexity added and why it belongs.

## Quality Bar

- The diff is no larger than the problem requires.
- Existing project language is preserved.
- Future maintainers have less to understand, not more.
- Any new concept has a clear owner and reason to exist.
