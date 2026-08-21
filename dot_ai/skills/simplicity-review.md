---
name: simplicity-review
description: Reviews diffs for unnecessary complexity and maintenance cost. Use when changes add files, abstractions, dependencies, generated code, or feel larger than the problem.
---

# Simplicity Review Skill

## Procedure

1. Inspect the diff and relevant surrounding code.
2. Identify new files, dependencies, concepts, wrappers, helpers, and branching paths.
3. Ask whether each addition removes more burden than it creates.
4. Look for code that can be deleted, reused, collapsed, localized, or renamed.
5. Count the layers a reader must trace and the hidden or mutable state they must retain.
6. Collapse pass-through or one-caller abstractions unless they hide meaningful complexity.
7. Ask whether a reader can quickly tell where a value comes from and what can change it.
8. Recommend concrete simplifications only when they preserve behavior.

## Output

List findings by maintenance risk. Include file references, the smallest safe alternative, and the net reader-load change.

## Anti-Patterns

- Abstracting because code looks similar but means different things.
- Keeping generated scaffolding that the project does not need.
- Creating docs, tests, or helpers that restate obvious behavior.
