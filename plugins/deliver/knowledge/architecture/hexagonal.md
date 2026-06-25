# Hexagonal Architecture — Ports & Adapters

*This is a supplementary file. The main Clean Architecture reference
(references/clean-architecture.md) contains the core Hexagonal summary.
Load this file when the project is service-oriented and testability via
port substitution is the primary concern.*

---

## Practical Implementation Guide

### Step 1: Identify your ports

A **port** is an interface your application core needs but does not implement.

**Ask:** "What does my application core need from the outside world?"

Common driven ports:
- Persistence (save/load domain objects)
- Notifications (email, SMS, push)
- Payment processing
- External API data (weather, maps, prices)
- Message publishing

Common driving ports (the application's public API):
- Process order
- Authenticate user
- Generate report

### Step 2: Write the port as an interface/protocol

```python
# Python (Protocol — structural typing)
from typing import Protocol

class OrderRepository(Protocol):
    def save(self, order: Order) -> None: ...
    def find_by_id(self, order_id: OrderId) -> Optional[Order]: ...
    def find_all_pending(self) -> list[Order]: ...
```

### Step 3: Write the production adapter

```python
class SQLAlchemyOrderRepository:
    def __init__(self, session: Session):
        self.session = session

    def save(self, order: Order) -> None:
        record = OrderRecord.from_domain(order)
        self.session.merge(record)

    def find_by_id(self, order_id: OrderId) -> Optional[Order]:
        record = self.session.get(OrderRecord, str(order_id))
        return record.to_domain() if record else None
```

### Step 4: Write the test adapter

```python
class InMemoryOrderRepository:
    def __init__(self):
        self._store: dict[str, Order] = {}

    def save(self, order: Order) -> None:
        self._store[str(order.id)] = order

    def find_by_id(self, order_id: OrderId) -> Optional[Order]:
        return self._store.get(str(order_id))
```

### Step 5: Wire it together at the boundary

```python
# In production (framework layer / DI container)
repo = SQLAlchemyOrderRepository(session=db.session)
processor = OrderProcessor(repo=repo, mailer=SendGridMailer())

# In tests (no framework, no DB, no network)
repo = InMemoryOrderRepository()
processor = OrderProcessor(repo=repo, mailer=FakeMailer())
```

---

## Port Testing Strategy

| Adapter | Where tested | How |
|---|---|---|
| InMemory (test double) | Unit tests for use cases | Injected directly |
| SQL adapter | Integration tests | Real DB (Docker/testcontainers) |
| HTTP adapter (controller) | Integration tests | Test client (TestClient, supertest) |
| Third-party API adapter | Contract tests | Recorded responses (VCR, nock) |

The split means:
- Unit tests are **fast** (no I/O)
- Integration tests are **thorough** (real I/O)
- No test mixes both concerns
