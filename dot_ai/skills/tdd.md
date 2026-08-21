---
name: tdd
description: Applies a focused red-green-refactor loop through observable behavior. Use only when the user explicitly requests TDD, test-first development, red-green-refactor, or a regression test before the fix.
---

# Test-Driven Development

## Procedure

1. Name the next observable behavior and the stable interface through which callers experience it.
2. Choose the cheapest reliable test that would fail for the right reason.
3. Write one test and run it to confirm `RED`.
4. Add only enough production code to reach `GREEN`.
5. Repeat one behavior at a time, adjusting later tests to what earlier cycles reveal.
6. Refactor only while green, running the narrow test after each structural change.
7. Finish with the broader real-path verification appropriate to the change.

## Test Design

- Prefer stable public behavior over private methods, call counts, or internal structure.
- Use existing project test conventions unless they cannot prove the behavior.
- Mock external or nondeterministic boundaries when the real dependency is impractical; avoid mocks that merely mirror internal implementation.
- Keep multiple assertions when they jointly prove one behavior. Split tests when failures would diagnose different behavior.
- Do not add a brittle test solely to claim coverage. Explain when no stable seam exists.

## Constraints

- Do not write the full test suite before implementation.
- Do not invent future requirements to justify abstractions.
- Do not force TDD when a cheaper verification method proves the behavior more reliably.
