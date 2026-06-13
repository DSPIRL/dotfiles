---
name: simplicity-review
description: Reviews changes for unnecessary complexity and maintainability cost. Use when a diff adds files, abstractions, dependencies, generated code, or feels larger than the problem.
---

# Simplicity Review

## Procedure

1. Inspect the diff and nearby code.
2. Identify new files, abstractions, wrappers, helpers, dependencies, and branching paths.
3. Ask whether each addition removes more burden than it creates.
4. Look for deletion, reuse, collapse, localization, or clearer names.
5. Return concrete simplifications that preserve behavior.
