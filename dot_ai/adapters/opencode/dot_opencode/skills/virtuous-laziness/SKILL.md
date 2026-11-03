---
name: virtuous-laziness
description: Applies maintenance-first engineering discipline to code changes. Use for implementation, refactoring, bug fixes, and reviews where minimal diffs, reuse, deletion, and justified complexity matter.
---

# Virtuous Laziness

## Procedure

1. Inspect existing patterns before editing.
2. State the smallest behavior change that satisfies the request.
3. Define success as an observable result.
4. Prefer deletion, reuse, consolidation, or configuration over new code.
5. Add abstractions only when duplication or domain boundaries justify them.
6. Add dependencies only when they reduce total maintenance burden.
7. Verify the real artifact or user path; identify proxy-only checks.
8. Inspect delegated artifacts instead of trusting summaries alone.
9. Explain any complexity added and why it belongs.
