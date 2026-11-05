---
name: zoom-out
description: Tell the agent to zoom out and give broader context or a higher-level perspective. Use when you're unfamiliar with a section of code or need to understand how it fits into the bigger picture.
disable-model-invocation: true
---

I don't know this area of code well. Go up a layer of abstraction.

Start with this area's purpose and where it fits in the larger system. Map the main modules, callers, and data flow rather than listing every dependency.

Use the project's domain glossary if one exists; otherwise explain terms plainly. Ground the explanation in inspected code, include useful file references, and distinguish verified relationships from assumptions or gaps.

Explain without editing files. Keep the initial explanation short, then offer to explore a particular branch more deeply.
