---
name: virtuous-laziness
description: Applies maintenance-first engineering discipline to code changes. Use for implementation, refactoring, bug fixes, and reviews where minimal diffs, reuse, deletion, and justified complexity matter.
---

# Virtuous Laziness

## Procedure

1. Inspect existing patterns before editing.
2. State the smallest behavior change that satisfies the request.
3. Prefer deletion, reuse, consolidation, or configuration over new code.
4. Add abstractions only when duplication or domain boundaries justify them.
5. Add dependencies only when they reduce total maintenance burden.
6. Verify behavior with relevant checks.
7. Explain any complexity added and why it belongs.
