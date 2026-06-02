# SOLID Principles Reference

---

## S — Single Responsibility Principle

> A class should have only one reason to change.

A "reason to change" = one actor (stakeholder group) whose requirements drive changes.

**Smell:** A class that has methods used by different actors. E.g., `Employee` with:
- `calculatePay()` (used by Finance)
- `reportHours()` (used by HR)
- `save()` (used by DBAs)

**Fix:** Separate into `PayCalculator`, `HourReporter`, `EmployeeRepository`. Share data via a thin `EmployeeData` struct.

---

## O — Open/Closed Principle

> Software entities should be open for extension, closed for modification.

Extend behaviour by adding new code, not by changing existing code.

**Pattern:** Strategy, Template Method, Decorator.

**Example:**
```python
# Closed — adding a new shape requires modifying draw()
def draw(shapes):
    for s in shapes:
        if isinstance(s, Circle): draw_circle(s)
        elif isinstance(s, Square): draw_square(s)  # ← must modify

# Open — each shape knows how to draw itself
class Shape(ABC):
    @abstractmethod
    def draw(self): ...

class Circle(Shape):
    def draw(self): ...  # ← add new shapes without touching draw()
```

**Smell:** Long if/elif chains on type codes. Switch statements on `type` fields.

---

## L — Liskov Substitution Principle

> Subtypes must be substitutable for their base types.

If S is a subtype of T, any program using T must work correctly with S.

**Violations:**
- Overriding a method to throw `UnsupportedOperationException`
- Narrowing preconditions (requiring more from callers than the base type)
- Widening postconditions (promising less to callers than the base type)
- `Rectangle`/`Square` problem: `Square.setWidth()` changes both dimensions, violating `Rectangle`'s contract

**Smell:** `isinstance` checks in client code. `if type(animal) == Dog`. Type-testing is a LSP alarm bell.

---

## I — Interface Segregation Principle

> Clients should not be forced to depend on interfaces they do not use.

Fat interfaces force implementors to provide dummy implementations of methods they don't need.

**Example:**
```python
# Fat — all implementors must handle all methods
class Worker:
    def work(self): ...
    def eat(self): ...  # Robots don't eat

# Segregated
class Workable:
    def work(self): ...

class Feedable:
    def eat(self): ...

class HumanWorker(Workable, Feedable): ...
class RobotWorker(Workable): ...  # No dummy eat()
```

**Smell:** Classes that implement an interface but leave some methods empty or raising `NotImplementedError`.

---

## D — Dependency Inversion Principle

> High-level modules should not depend on low-level modules. Both should depend on abstractions.
> Abstractions should not depend on details. Details should depend on abstractions.

**Smell:**
```python
# Violation — high-level policy depends on low-level detail
class OrderProcessor:
    def __init__(self):
        self.db = MySQLDatabase()   # ← concrete dependency
        self.mailer = SendGridMailer()  # ← concrete dependency
```

**Fix:**
```python
class OrderProcessor:
    def __init__(self, db: Database, mailer: Mailer):
        self.db = db        # ← depends on abstraction
        self.mailer = mailer
```

Now `OrderProcessor` is testable without a real DB or mailer.

---

## SOLID Smell Checklist

```
[ ] S: Class name contains "And", "Or", "Manager" — may have multiple responsibilities
[ ] S: Test requires mocking >3 collaborators — too many responsibilities
[ ] O: Adding a new variant requires modifying existing classes
[ ] O: switch/if-elif on a type discriminator (type codes)
[ ] L: Client code uses isinstance/type checks
[ ] L: Subclass overrides method to throw "not supported"
[ ] L: Subclass ignores parameters the base type uses
[ ] I: Interface methods left empty or raising NotImplementedError
[ ] I: Client imports an interface but only uses 2 of 8 methods
[ ] D: Concrete class instantiated inside another class's __init__
[ ] D: import of a database driver / HTTP client in a domain class
[ ] D: Hard to test because collaborators are hard-coded
```
