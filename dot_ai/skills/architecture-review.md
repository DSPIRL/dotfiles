---
name: architecture-review
description: Finds evidence-backed opportunities to reduce architectural friction, improve locality, and create useful test seams. Use when the user asks for architecture analysis, structural refactoring opportunities, or consolidation of tightly coupled code.
---

# Architecture Review

## Procedure

1. Read project context, domain language, relevant ADRs, and the code paths that exhibit friction.
2. Look for demonstrated costs: concepts spread across files, shallow pass-through modules, hidden state, duplicated policy, changes that require many edits, or behavior without a stable test seam.
3. Apply the deletion test: if a layer disappeared, would its complexity vanish or leak into callers?
4. Distinguish real seams with multiple implementations or meaningful isolation from hypothetical interfaces added for flexibility.
5. Present only candidates whose expected maintenance benefit exceeds migration and compatibility cost.

## Candidate Format

For each candidate, provide:

- Evidence and affected behavior
- Current reader and change cost
- Smallest structural improvement
- Expected deletion, locality, or testability gain
- Migration risk and verification approach
- Relevant ADR agreement or conflict

## Constraints

- Preserve project-native terminology.
- Do not redesign working code for aesthetic consistency.
- Do not invent extension points for hypothetical consumers.
- Offer alternative interfaces only for expensive, difficult-to-reverse choices.
- Do not implement candidates until the user selects one.
