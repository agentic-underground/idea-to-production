# Domain-Driven Design Reference

---

## Strategic DDD

### Bounded Contexts

A **bounded context** is the explicit boundary within which a domain model applies.
The same word ("Customer") may mean different things in different contexts:
- In Sales: a prospect with a pipeline stage
- In Support: a ticket-holder with an SLA
- In Billing: a payer with a payment method

**Smell:** One `Customer` class shared across the whole application, growing
ever fatter with fields used only by one department.

### Context Map

Document how bounded contexts relate:
- **Shared Kernel:** two teams share a subset of the model
- **Customer/Supplier:** upstream team delivers to downstream team
- **Conformist:** downstream team conforms to upstream's model
- **Anti-Corruption Layer (ACL):** downstream team translates upstream's model
- **Published Language:** open protocol (JSON schema, Protobuf)

---

## Tactical DDD

### Building Blocks

| Block | Definition | Key rule |
|---|---|---|
| **Entity** | Has identity, continuity over time | Equality by ID, not by attributes |
| **Value Object** | Defined by attributes, no identity | Immutable; equality by value |
| **Aggregate** | Cluster of entities/VOs with a root | All access via Aggregate Root only |
| **Aggregate Root** | The gatekeeper of the aggregate | Enforces invariants; holds the ID |
| **Domain Event** | Something that happened in the domain | Named in past tense; immutable |
| **Repository** | Persistence abstraction for an aggregate | Returns Aggregate Roots only |
| **Domain Service** | Logic that doesn't belong to any entity | Stateless; operates on domain objects |
| **Application Service** | Orchestrates use cases | No domain logic; thin layer |
| **Factory** | Complex creation logic | Creates valid aggregates |

### Ubiquitous Language

- Use the **same words** domain experts use, in code and in conversation.
- If the business says "booking" and the code says "reservation", there is a translation tax.
- If a developer explains the code and the domain expert doesn't understand the words, the language is not ubiquitous.

### DDD Smell Checklist

```
[ ] Anemic domain model: objects with only getters/setters, logic in services
[ ] "Manager", "Handler", "Helper", "Util" classes (no domain meaning)
[ ] Domain language absent from code (code uses technical terms only)
[ ] Invariants enforced in application service, not in aggregate
[ ] Repository returns database rows, not domain objects
[ ] Direct access to aggregate internals (bypassing root)
[ ] Domain events missing — key state changes not communicated
[ ] Bounded context boundaries not clear — one model for all contexts
```
