---
id: simplicity-review
kind: skill
trigger: Reviewing diffs for unnecessary complexity.
---

# Simplicity Review Skill

## Procedure

1. Inspect the diff and relevant surrounding code.
2. Identify new files, dependencies, concepts, wrappers, helpers, and branching paths.
3. Ask whether each addition removes more burden than it creates.
4. Look for code that can be deleted, reused, collapsed, localized, or renamed.
5. Recommend concrete simplifications only when they preserve behavior.

## Output

List findings by maintenance risk. Include file references and the smallest safe alternative.

## Anti-Patterns

- Abstracting because code looks similar but means different things.
- Keeping generated scaffolding that the project does not need.
- Creating docs, tests, or helpers that restate obvious behavior.
