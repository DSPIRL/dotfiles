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
- Do not add opinions, personality, evidence, or certainty that the source lacks.

## Modes

Use `decode` by default when the user says the text is hard to understand.

- `decode`: Explain the actual claims in plain language and identify what remains unclear.
- `rewrite`: Produce a clearer version with the same meaning and tone.
- `audit`: Mark AI-writing patterns and explain why they obstruct meaning.

## Procedure

1. Read only the supplied text or target file and any context the user provides.
2. Identify the concrete claims, actors, actions, evidence, uncertainty, and requested outcome.
3. Flag statements that cannot be made concrete without more information.
4. Remove patterns that obscure meaning:
   - filler, puffery, promotional language, and canned conclusions
   - vague attribution, unsupported confidence, and excessive hedging
   - abstract metaphors where a concrete mechanism or term exists
   - unstable terminology and synonym cycling
   - passive voice that hides a relevant actor
   - dense sentences, unnecessary qualifiers, and chatbot pleasantries
   - descriptions of how something feels when the mechanism or measurement is what matters
5. Use plain words, stable project terminology, active voice, and one main idea per sentence.
6. Compare the result with the source and restore any meaning that was lost.

## Output

For `decode`, return:

1. `Plain-language meaning`: the concrete claims and requested action.
2. `Unclear or unsupported`: ambiguities, missing evidence, and terms that need definition.

For `rewrite`, return the rewritten text. Add notes only when ambiguity prevents a faithful rewrite.

For `audit`, quote short problem phrases and give a concrete replacement or question for each.

Do not apply blanket punctuation rules or make factual writing artificially casual.
