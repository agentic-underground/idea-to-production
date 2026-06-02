# Untestable Code Patterns — Diagnosis & Fixes

When the coverage-loop-agent encounters a gap it cannot fill with tests,
consult this reference to diagnose the pattern and find the fix.

---

## Pattern 1: Hard-coded Dependency (Most Common)

**Symptom:** Class instantiates its own collaborators.

```python
# UNTESTABLE
class OrderProcessor:
    def process(self, order):
        db = PostgresDatabase()        # ← hard-coded
        mailer = SendGridMailer()      # ← hard-coded
        db.save(order)
        mailer.send_confirmation(order)
```

**Coverage impact:** Any branch in `process()` that touches `db` or `mailer`
is untestable without a real database and real email sender.

**Fix:** Dependency Injection

```python
# TESTABLE
class OrderProcessor:
    def __init__(self, db: Database, mailer: Mailer):
        self.db = db
        self.mailer = mailer

    def process(self, order):
        self.db.save(order)
        self.mailer.send_confirmation(order)
```

**Refactor risk:** Low (structural change, no logic change).

---

## Pattern 2: Global State / Singleton

**Symptom:** Tests affect each other because they share global state.

```python
# UNTESTABLE (in isolation)
_cache = {}

def get_user(user_id):
    if user_id in _cache:
        return _cache[user_id]
    user = db.fetch(user_id)
    _cache[user_id] = user
    return user
```

**Fix:** Make state injectable or use thread-local / context-local storage.

```python
def get_user(user_id, cache=None):
    cache = cache if cache is not None else {}
    ...
```

**Refactor risk:** Low–Medium.

---

## Pattern 3: Hidden Time Dependency

**Symptom:** Code calls `datetime.now()`, `time.time()`, or `Date.now()` directly.

```python
def is_expired(token):
    return token.expires_at < datetime.now()  # ← can't control "now" in tests
```

**Fix:** Inject a clock.

```python
def is_expired(token, clock=None):
    now = clock() if clock else datetime.now
    return token.expires_at < now()
```

**Refactor risk:** Low.

---

## Pattern 4: Static Methods With Side Effects

**Symptom:** Static/class methods that call external systems.

```java
// UNTESTABLE
public static Order processOrder(Order order) {
    DatabaseService.getInstance().save(order);  // static singleton
    EmailService.sendConfirmation(order);        // static call
    return order;
}
```

**Fix:** Extract to instance method; inject dependencies.

**Refactor risk:** Medium (may touch many call sites).

---

## Pattern 5: Private Method With Untested Logic

**Symptom:** Complex logic hidden in a private method, not reachable via public API.

```python
class ReportGenerator:
    def generate(self, data):
        cleaned = self._normalise(data)  # ← tested indirectly
        return self._format(cleaned)

    def _complex_private_logic(self, x):  # ← only called by dead code path
        ...
```

**Options:**
1. If the private method is only called from tested paths → it IS tested.
2. If it's dead code → delete it.
3. If it's genuinely complex and needs isolated testing → extract to a collaborator class.

**Fix:** Extract `ReportNormaliser` class with a public interface.

---

## Pattern 6: OS / Filesystem / Environment Dependency

**Symptom:** Code reads files, environment variables, or system state directly.

```python
def load_config():
    path = os.environ['CONFIG_PATH']  # ← what if not set?
    with open(path) as f:             # ← what if file doesn't exist?
        return json.load(f)
```

**Fix:** Make the dependency explicit and injectable.

```python
def load_config(env=None, opener=None):
    env = env or os.environ
    opener = opener or open
    path = env['CONFIG_PATH']
    with opener(path) as f:
        return json.load(f)
```

**Refactor risk:** Low.

---

## Pattern 7: Non-deterministic Code

**Symptom:** Code uses `random`, `uuid`, `datetime.now()` without injection.

**Fix:** Inject the source of randomness. Seed it in tests.

---

## Pattern 8: Multi-threading / Async Race Conditions

**Symptom:** Coverage drops because some branches only execute under specific
timing conditions impossible to reproduce in tests.

**Fix:** Extract the concurrency mechanism from the logic. Test the logic
synchronously. Test the concurrency with integration tests.

---

## Pattern 9: Truly Dead Code

**Symptom:** Code is unreachable by any input. Usually leftover from a
previous feature or a defensive branch that is logically impossible.

**Diagnosis:** If you can prove no input can reach the code, it is dead.

**Fix:** Delete it. Dead code carries the illusion of completeness while
providing no value.

**Before deleting:** Check git history. Dead code sometimes has a reason.

---

## Pattern 10: Third-Party SDK Without Abstraction

**Symptom:** Business logic calls an SDK directly (boto3, stripe, twilio, etc.)

```python
def charge_customer(amount, token):
    stripe.Charge.create(amount=amount, source=token)  # ← real API call
```

**Fix:** Introduce a port (interface) and an adapter.

```python
class PaymentGateway(Protocol):
    def charge(self, amount: Decimal, token: str) -> ChargeResult: ...

class StripeAdapter(PaymentGateway):
    def charge(self, amount, token):
        result = stripe.Charge.create(...)
        return ChargeResult(id=result.id, status=result.status)

# Domain code depends on PaymentGateway, not stripe
# Tests inject FakePaymentGateway
```

**Refactor risk:** Medium. High value — unlocks full testability of payment flows.
