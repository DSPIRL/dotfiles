---
name: test-matrix
description: Map a project against 20 kinds of testing and verification, find the gaps worth closing, and add the ones the user picks. Trigger this if the user says 'test matrix'.
disable-model-invocation: true
---

# Test Matrix

Find out which kinds of testing this project has, which ones it needs, and
add the ones the user picks. Not every project needs every kind. A good result
is a few well-chosen tests, not all 20.

If the user names specific kinds or paths, limit the work to those.

## 1. Survey

Inspect before asking. Find:

- language, frameworks, build tool, and package manager;
- existing test directories, test runners, and the commands that run them;
- CI config, pre-commit hooks, linters, formatters, and type checkers;
- what the project is: library, CLI, service, web app, mobile app, etc.;
- the riskiest code: auth, money, parsing, concurrency, data migrations,
  public APIs.

Run the existing test, lint, and coverage commands if they're cheap and safe.
Record what passes, what fails, and the current coverage number.

## 2. Classify

Rate each kind of testing in the table below as one of:

- **Present**: exists and runs (say where and how).
- **Weak**: exists but thin, broken, or not run in CI.
- **Gap**: missing, and worth adding here.
- **Skip**: not worth it for this project (say why in a few words).

| Kind | Catches | Worth it when |
|------|---------|---------------|
| Unit | Logic bugs in one function or class | Almost always |
| Functional | A feature behaves wrong end to end through its public interface | Features have clear inputs and outputs |
| Component | One module breaks with its real neighbors, or UI components render wrong | Code has clear module or UI-component boundaries |
| Fuzz | Crashes and hangs on malformed input | Parsers, decoders, anything that reads untrusted bytes |
| Property-based | Edge cases that examples miss | Pure functions with invariants (round trips, sorting, math) |
| Formal verification | Proves an algorithm or protocol is correct | Small, critical cores (consensus, crypto, money). Usually Skip |
| Static analysis | Type errors, null derefs, unsafe patterns | Almost always. Prefer the language's type checker first |
| Mutation | Tests that run code but don't check results | A decent suite already exists and coverage is high |
| Coverage | Untested code paths | Almost always. A measure, not a goal |
| Benchmark | Speed regressions in hot paths | Performance is a requirement |
| Contract | API producers and consumers disagree on shape | Separate services or a published API/schema |
| Lint | Style drift and common mistakes | Almost always |
| Acceptance | The product doesn't do what the user asked | There are written requirements or user stories |
| Regression | Fixed bugs come back | Every fixed bug. One test per bug |
| Smoke | The build or deploy is broken at a basic level | Anything that gets deployed or released |
| Usability | Real people get confused or stuck | User-facing products. Needs humans, so the agent can only plan it |
| UI/UX | Layout, visual, and accessibility breakage | Anything with a UI |
| Penetration | Exploitable security holes | Anything exposed to untrusted users. Use `/security-audit` |
| Threat modeling | Missing defenses in the design | Anything handling sensitive data. Use `/security-audit` guidance mode |
| Performance | Load, latency, and memory limits | Services with real traffic or SLAs |

## 3. Report and recommend

Show the table with ratings and one-line notes. Then recommend the gaps to
close, in order of value per effort. For each one, say:

- what it would catch in *this* codebase, naming real files or functions;
- which tool to use, preferring tools the project already has, then the
  language's standard tool, then a new dependency (justify any new dependency);
- the rough size of the change.

Ask the user which ones to implement. Don't write tests before they choose.

## 4. Implement

For each chosen kind:

1. Match the project's existing test layout, naming, and style.
2. Start with the riskiest code found in the survey.
3. Make the tests fail when the code is wrong. Briefly break the code under
   test, confirm the test fails, then restore it.
4. Run the new tests and report the real output, including failures.
5. Add a project script or CI step only if the user agrees.

If a test finds a real bug, stop and report it. Don't fix product code unless
the user asks.

For penetration testing and threat modeling, hand off to `/security-audit`
rather than duplicating it. For usability testing, write a short test plan
(tasks, who to recruit, what to watch for) instead of tests.

## Anti-patterns

- Chasing a coverage percentage with tests that check nothing.
- Adding a tool, framework, or CI job for a kind of testing the project
  doesn't need.
- Tests that mirror the implementation instead of checking behavior.
- Mocking the thing being tested.
- Slow or flaky tests in the default test command.
- Claiming a kind is covered because a config file exists.
