---
name: unslop
description: Decodes or rewrites explicitly supplied AI-generated prose into concrete plain language. Use only when the user explicitly invokes unslop and provides text or a file to inspect.
license: MIT
disable-model-invocation: true
metadata:
  source: Adapted from backnotprop/pstack skills/unslop
---

# Decode AI Slop

## Invocation Contract

- Never invoke this skill automatically.
- Require explicit text or a file target. Ask for one if it is missing.
- Do not edit the source file unless the user asks.
- Preserve facts, technical meaning, uncertainty, and intended audience.
- Do not add opinions, evidence, or certainty that the source lacks.

## Modes

- `decode`: Explain the concrete claims and identify what remains unclear. This is the default.
- `rewrite`: Produce a clearer version with the same meaning and tone.
- `audit`: Mark AI-writing patterns and explain why they obstruct meaning.

## Procedure

1. Identify the claims, actors, actions, evidence, uncertainty, and requested outcome.
2. Flag statements that cannot be made concrete without more information.
3. Remove filler, puffery, vague attribution, unsupported confidence, excessive hedging, abstract metaphors, unstable terminology, hidden actors, dense sentences, and chatbot phrases.
4. Use plain words, stable terminology, active voice, and one main idea per sentence.
5. Compare the result with the source and restore any lost meaning.

Do not apply blanket punctuation rules or make factual writing artificially casual.
