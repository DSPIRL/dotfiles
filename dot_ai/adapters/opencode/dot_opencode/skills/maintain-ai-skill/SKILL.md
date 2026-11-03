---
name: maintain-ai-skill
description: Creates or revises skills in this portable AI engineering stack. Use only when the user explicitly asks to add, rewrite, review, or maintain an agent skill.
disable-model-invocation: true
---

# Maintain AI Skill

## Procedure

1. Inspect the manifest, existing skills, adapters, and conventions first.
2. Add a skill only for a reusable procedure with a distinct trigger.
3. Write the canonical skill under `skills/` before adapter copies.
4. Include clear triggers, boundaries, a short procedure, and an observable quality bar.
5. Add references or scripts only after repeated use proves their value.
6. Update only required adapters, the manifest, and user documentation.
7. Validate frontmatter, discovery, manual-only behavior, and installation.

Every sentence must change model behavior. Prefer fewer skills with distinct ownership.
