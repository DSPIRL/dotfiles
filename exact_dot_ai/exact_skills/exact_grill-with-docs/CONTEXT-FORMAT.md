# CONTEXT.md Format

Fallback only: follow the project's existing documentation locations and formats first. Use this format only if no existing convention applies and the user approves it. Ask before creating any new documentation file or introducing a convention; record only user-confirmed terminology and decisions.

## Structure

The examples below are illustrative placeholders, not facts about the project.

```md
# {Context Name}

{One or two sentence description of what this context is and why it exists.}

## Language

**Order**:
{A concise description of the term}
_Avoid_: Purchase, transaction

**Invoice**:
A request for payment sent to a customer after delivery.
_Avoid_: Bill, payment request

**Customer**:
A person or organization that places orders.
_Avoid_: Client, buyer, account

## Relationships

- An **Order** produces one or more **Invoices**
- An **Invoice** belongs to exactly one **Customer**

## Example dialogue

> **Dev:** "When a **Customer** places an **Order**, do we create the **Invoice** immediately?"
> **Domain expert:** "No — an **Invoice** is only generated once a **Fulfillment** is confirmed."

## Flagged ambiguities

- "account" was used to mean both **Customer** and **User** — resolved: these are distinct concepts.
```

## Rules

- **Propose precise language.** When multiple words exist for the same concept, recommend a canonical term and aliases to avoid. Record that choice only after the user confirms it.
- **Flag conflicts explicitly.** If a term is used ambiguously, call it out in "Flagged ambiguities". Record only user-confirmed resolutions; leave pending ambiguities explicitly unresolved.
- **Keep definitions tight.** One sentence max. Define what it IS, not what it does.
- **Show confirmed relationships.** Use bold term names and record user-confirmed relationships and cardinality. Do not infer missing domain facts.
- **Only include terms specific to this project's context.** General programming concepts (timeouts, error types, utility patterns) don't belong even if the project uses them extensively. Before adding a term, ask: is this a concept unique to this context, or a general programming concept? Only the former belongs.
- **Group terms under subheadings** when natural clusters emerge. If all terms belong to a single cohesive area, a flat list is fine.
- **Use illustrative dialogue when helpful.** Label it as illustrative, not an actual exchange, and use only user-confirmed domain facts to show how terms interact and where their boundaries lie.

## Single vs multi-context repos

**Single context:** This fallback uses one `CONTEXT.md` at the repo root.

**Multiple contexts:** A `CONTEXT-MAP.md` at the repo root lists the contexts, where they live, and how they relate to each other:

```md
# Context Map

## Contexts

- [Ordering](./src/ordering/CONTEXT.md) — receives and tracks customer orders
- [Billing](./src/billing/CONTEXT.md) — generates invoices and processes payments
- [Fulfillment](./src/fulfillment/CONTEXT.md) — manages warehouse picking and shipping

## Relationships

- **Ordering → Fulfillment**: Ordering emits `OrderPlaced` events; Fulfillment consumes them to start picking
- **Fulfillment → Billing**: Fulfillment emits `ShipmentDispatched` events; Billing consumes them to generate invoices
- **Ordering ↔ Billing**: Shared types for `CustomerId` and `Money`
```

After checking the project's actual documentation conventions:

- If `CONTEXT-MAP.md` exists, read it to find contexts
- If only a root `CONTEXT.md` exists, use it for the single context
- If neither exists and no other convention applies, offer this fallback; create a root `CONTEXT.md` only after approval and when there is confirmed content to record

When multiple contexts exist, infer which one the current topic relates to. If unclear, ask.
