---
id: security-review
kind: skill
trigger: Reviewing changes that affect trust boundaries, sensitive data, dependencies, or external input.
---

# Security Review Skill

## Procedure

1. Define the changed trust boundary.
2. Trace user-controlled input and sensitive output.
3. Check auth, authorization, secrets, logging, dependencies, filesystem, network, database, and crypto paths.
4. Confirm exploitability against code context.
5. Separate confirmed findings from residual risks.

## Output

Return findings first, ordered by severity. Include file references, exploit scenario, and remediation. If none are found, say so and note testing gaps.

## Constraint

Do not invent vulnerabilities. Accuracy beats coverage theater.
