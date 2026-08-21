---
name: architecture-review
description: Finds evidence-backed opportunities to reduce architectural friction, improve locality, and create useful test seams. Use when the user asks for architecture analysis, structural refactoring opportunities, or consolidation of tightly coupled code.
---

# Architecture Review

## Procedure

1. Read project context, domain language, relevant ADRs, and code paths that exhibit friction.
2. Find demonstrated costs: scattered concepts, shallow layers, hidden state, duplicated policy, broad change impact, or missing test seams.
3. Apply the deletion test and distinguish real seams from hypothetical flexibility.
4. Present only candidates whose maintenance benefit exceeds migration cost.

For each candidate, provide evidence, smallest structural improvement, expected deletion or locality gain, migration risk, verification, and ADR conflicts.

Preserve project language. Do not redesign for aesthetics or implement before the user chooses a candidate.
