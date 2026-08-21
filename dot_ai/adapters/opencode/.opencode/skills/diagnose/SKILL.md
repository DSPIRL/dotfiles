---
name: diagnose
description: Diagnoses difficult bugs, intermittent failures, and performance regressions through reproducible evidence. Use when a failure resists an obvious fix or the user explicitly asks to diagnose or debug it.
---

# Diagnose

## Procedure

1. Define the exact symptom and observable reproduction signal.
2. Build the cheapest reliable feedback loop and confirm it reproduces the user's failure.
3. Minimize the loop without changing the failure mechanism.
4. Form plausible hypotheses with falsifiable predictions.
5. Test one prediction at a time with targeted probes or tagged instrumentation.
6. Apply the smallest causal fix and add a regression test when a stable seam represents the real failure.
7. Re-run the minimized loop and original user path.
8. Remove temporary instrumentation and artifacts.

For performance regressions, establish a repeatable baseline before changing code. If reproduction is blocked, request the smallest missing artifact and label static conclusions by evidence strength.
