# Clean Architecture & Hexagonal Architecture Reference

---

## Clean Architecture (Robert C. Martin)

### The Dependency Rule

> Source code dependencies must point only inward, toward higher-level policies.

```
         ┌─────────────────────────────┐
         │      Frameworks & Drivers   │  ← Web, DB, UI, external
         │   ┌─────────────────────┐   │
         │   │     Interface       │   │  ← Controllers, Presenters, Gateways
         │   │   Adapters          │   │
         │   │  ┌─────────────┐   │   │
         │   │  │  Use Cases  │   │   │  ← Application business rules
         │   │  │  ┌───────┐  │   │   │
         │   │  │  │Entities│  │   │   │  ← Enterprise business rules
         │   │  │  └───────┘  │   │   │
         │   │  └─────────────┘   │   │
         │   └─────────────────────┘   │
         └─────────────────────────────┘
         Arrows always point INWARD only
```

### Layer Responsibilities

| Layer | Contains | Depends On |
|---|---|---|
| Entities | Business objects, core rules | Nothing |
| Use Cases | Application-specific rules, orchestration | Entities only |
| Interface Adapters | Controllers, Presenters, Gateways | Use Cases, Entities |
| Frameworks & Drivers | Flask, SQLAlchemy, React, etc. | Interface Adapters |

### The Crossing Rule

Data crossing a boundary must be in the form of simple data structures — not
framework objects, not database rows. A domain entity must never carry a
SQLAlchemy model. A use case must never return a Flask Response object.

### Smell Checklist

```
[ ] Domain entity imports an ORM model
[ ] Use case imports Flask / Django / FastAPI
[ ] Controller contains business logic (if/else on domain rules)
[ ] Repository returns ORM objects (not domain objects)
[ ] Test requires a real database to test a use case
[ ] Framework exception propagates into domain layer
[ ] Business rule changes require touching the web layer
```

---

## Hexagonal Architecture (Alistair Cockburn — Ports & Adapters)

### The Model

```
         External World
              │
         [Adapter]          ← HTTP controller, CLI, message consumer
              │
         (Port) ─────────── Application Core ─────────── (Port)
                                                              │
                                                         [Adapter]
                                                              │
                                                     External World
                                              (DB, 3rd-party API, message broker)
```

### Ports

A **port** is an interface defined by the application core.

- **Driving port** (primary): called by the outside world to drive the application.
  E.g., `CreateOrderUseCase`, `AuthenticateUserUseCase`.
- **Driven port** (secondary): called by the application core to reach the outside world.
  E.g., `OrderRepository`, `EmailNotifier`, `PaymentGateway`.

### Adapters

An **adapter** implements a port — it translates between the external world's
representation and the application core's representation.

- **Primary adapter:** HTTP controller, CLI command handler, gRPC handler.
  Calls the driving port.
- **Secondary adapter:** SQLAlchemy repository, SendGrid email adapter, Stripe adapter.
  Implements the driven port.

### Why This Matters for Testing

Every driven port can be replaced by a test double:

```python
# Production
class PostgresOrderRepository(OrderRepository):
    def save(self, order): ...  # real DB

# Test
class InMemoryOrderRepository(OrderRepository):
    def save(self, order): self.orders.append(order)

# Test can run the full use case without a DB
processor = OrderProcessor(repo=InMemoryOrderRepository())
```

If your test requires a real DB to test domain logic, you have no port.
The DB is directly coupled to the domain — this is the most common Hexagonal violation.

### Hexagonal Smell Checklist

```
[ ] No interface between domain and database access
[ ] "Repository" imports ORM model, not domain model
[ ] Use case instantiates its own collaborators (new DatabaseService())
[ ] HTTP request object passed into use case
[ ] Domain method has @route decorator
[ ] Test mocks a concrete class, not an interface
[ ] Third-party SDK imported directly in business logic
[ ] No way to run the domain logic without starting a web server
```

---

## DRY / YAGNI / KISS (Supplementary)

### DRY — Don't Repeat Yourself

> Every piece of knowledge must have a single, unambiguous, authoritative representation.

DRY is about **knowledge**, not text. Two functions with similar code but
different purposes are NOT a DRY violation. Two places that both encode
"a valid email has exactly one @" IS a violation.

**Smell:** Shotgun surgery — one business rule change requires touching N files.

### YAGNI — You Aren't Gonna Need It

Don't build what you don't need yet. Speculative generality is a code smell.
The cost of unused abstraction: complexity, confusion, maintenance burden.

**Smell:** Abstract base classes with one implementation. Plugin systems with
one plugin. Config keys that are never read.

### KISS — Keep It Simple, Stupid

The simplest solution that works is correct until proven otherwise.
Clever code is expensive to read, expensive to debug, expensive to change.

**Smell:** Metaprogramming where a simple function would do. Deep inheritance
where composition would do. Generator expressions as dense one-liners.
