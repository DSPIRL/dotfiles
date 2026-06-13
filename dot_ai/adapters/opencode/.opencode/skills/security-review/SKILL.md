---
name: security-review
description: Reviews changes for security vulnerabilities. Use for auth, authorization, external input, secrets, dependencies, filesystem, network, database, crypto, or data exposure changes.
---

# Security Review

## Procedure

1. Define the changed trust boundary.
2. Trace user-controlled input and sensitive output.
3. Check auth, authorization, secrets, logging, dependencies, filesystem, network, database, and crypto paths.
4. Confirm exploitability against code context.
5. Return findings first, ordered by severity, with remediation.

Do not invent vulnerabilities. Accuracy beats coverage theater.
