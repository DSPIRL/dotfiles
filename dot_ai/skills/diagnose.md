---
name: diagnose
description: Diagnoses difficult bugs, intermittent failures, and performance regressions through reproducible evidence. Use when a failure resists an obvious fix or the user explicitly asks to diagnose or debug it.
---

# Diagnose

## Procedure

1. Define the exact reported symptom and the observable signal that reproduces it.
2. Build the cheapest reliable feedback loop: focused test, CLI command, request replay, browser path, fixture, trace, differential check, or measurement harness.
3. Confirm the loop reproduces the user's failure, then minimize it without changing the failure mechanism.
4. Form only the plausible hypotheses needed to distinguish causes. Give each a falsifiable prediction.
5. Test one prediction at a time with a debugger, targeted probe, or tagged temporary instrumentation.
6. Fix the cause with the smallest change. Add a regression test when a stable seam can represent the real failure.
7. Re-run both the minimized loop and the original user path.
8. Remove temporary instrumentation and throwaway artifacts.

## Performance Regressions

Establish a repeatable baseline before changing code. Compare measurements, profiles, query plans, or versions rather than relying on impressions.

## When Reproduction Is Blocked

State what was attempted and request the smallest missing artifact or access: logs, trace, failing input, environment details, recording, or permission for temporary instrumentation. Continue with static reasoning only when useful, and label conclusions by evidence strength.

## Output

Report the root mechanism, evidence that distinguishes it from alternatives, the fix, original-path verification, and any residual uncertainty.
