---
name: tdd
description: Applies a focused red-green-refactor loop through observable behavior. Use only when the user explicitly requests TDD, test-first development, red-green-refactor, or a regression test before the fix.
---

# Test-Driven Development

## Procedure

1. Name the next observable behavior and stable caller interface.
2. Write one reliable test and confirm it fails for the right reason.
3. Add only enough production code to pass.
4. Repeat one behavior at a time.
5. Refactor only while green and rerun tests after structural changes.
6. Finish with broader real-path verification.

Prefer stable behavior over internal structure. Mock impractical external or nondeterministic boundaries, not internal implementation. Do not force TDD when a cheaper verification method proves behavior more reliably.
