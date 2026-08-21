---
name: maintain-ai-skill
description: Creates or revises skills in this portable AI engineering stack. Use only when the user explicitly asks to add, rewrite, review, or maintain an agent skill.
disable-model-invocation: true
---

# Maintain AI Skill

## Procedure

1. Inspect `MANIFEST.yaml`, existing skills, adapters, and project conventions before creating another concept.
2. Decide whether a direct instruction or an existing skill can handle the request. Add a skill only for a reusable procedure with a clear trigger.
3. Write the canonical skill first under `skills/`.
4. Give it a specific name, a description that states capability and trigger, explicit boundaries, a short procedure, and an observable quality bar.
5. Keep optional detail out of the main file. Add references or scripts only when repeated use proves they reduce errors or tokens.
6. Add only the adapter copies required by tools that cannot consume the canonical form.
7. Update `MANIFEST.yaml` and `HOW_TO.md` when users need to discover or invoke it.
8. Validate frontmatter, adapter discovery, manual-only behavior, and actual installation.

## Review Test

Every sentence must change model behavior. Remove inspiration, repeated warnings, generic expertise claims, and examples that do not clarify a boundary.

Prefer fewer skills with distinct ownership over overlapping micro-skills.
