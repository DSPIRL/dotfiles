# Virtuous Laziness

Virtuous laziness is the discipline of spending present effort to reduce future human effort.

It is not avoidance of work. It is refusal to create unnecessary work for future maintainers.

## Standards

- Prefer the smallest correct diff.
- Prefer deletion over addition when behavior can be preserved.
- Prefer existing project language over new names.
- Prefer existing abstractions over parallel structures.
- Add abstractions only when the boundary is real and useful.
- Add dependencies only when they remove more burden than they introduce.
- Make complexity visible and justify why it belongs.

## Questions

- What can be removed?
- What existing pattern already solves this?
- What will future maintainers need to understand?
- Is this change shaped like the rest of the project?
- Did we make the system easier to own?

## Anti-Patterns

- Measuring progress by lines of code, file count, or generated output volume.
- Creating wrappers, helpers, or abstractions before the concept boundary is clear.
- Writing docs that paraphrase obvious code.
- Logging activity instead of decisions.
- Treating passing tests as proof that a change belongs.
