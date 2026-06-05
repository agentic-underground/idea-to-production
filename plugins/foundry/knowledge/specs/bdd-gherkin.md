# TDD / BDD Reference

---

## Test-Driven Development

### The Three Laws (Robert C. Martin)

1. You may not write production code until you have written a failing unit test.
2. You may not write more of a unit test than is sufficient to fail.
3. You may not write more production code than is sufficient to make the test pass.

### Red-Green-Refactor

```
RED   → Write the smallest failing test
GREEN → Write the simplest code to make it pass (even if ugly)
REFACTOR → Clean up, with tests as safety net
```

> **Why RED comes first — a test is a coordinate.** The failing test *locates* the code you are about
> to write in logical space; it is the **reason** to write code, and that code must produce only
> **PASS**. A Gherkin scenario is the same idea in the user's language — it **locates a behaviour**,
> with happy / unhappy / abuse as its **axes**. The sum of all coordinates *is* the SOLUTION. (Canon:
> [`../first-principles.md`](../first-principles.md) §2 ·
> [`../testing/test-policy.md`](../testing/test-policy.md) §Coordinates in practice.)

**Refactor means:** improve structure, not add features. Tests stay green throughout.

### Test Anatomy — Arrange / Act / Assert

```python
def test_order_total_includes_tax():
    # Arrange
    order = Order(items=[Item(price=100)], tax_rate=0.1)
    
    # Act
    total = order.calculate_total()
    
    # Assert
    assert total == Decimal("110.00")
```

One assertion concept per test. Not one `assert` statement — one *concept*.

### Test Quality Checklist

```
[ ] Test name describes behaviour, not implementation ("test_order_total_includes_tax" not "test_calculate")
[ ] Test is independent — does not rely on other tests' side effects
[ ] Test is deterministic — same result every run
[ ] Test is fast — unit tests run in milliseconds
[ ] Test has exactly one reason to fail
[ ] Test is readable without reading the production code
[ ] Failure message is self-explanatory
[ ] No production logic in tests (no if/for in assertions)
```

### The Test Pyramid

```
        /\
       /  \   E2E (few, slow, high confidence)
      /────\
     /      \  Integration (some, medium speed)
    /────────\
   /          \ Unit (many, fast, pinpoint feedback)
  /────────────\
```

Inversion of this pyramid (many E2E, few unit) is a quality smell.

---

## Behaviour-Driven Development

BDD is TDD with a shared language between developers and domain experts.

### Gherkin Format

```gherkin
Feature: Order total calculation

  Scenario: Tax is included in the total
    Given an order with one item priced at £100
    And a tax rate of 10%
    When I calculate the total
    Then the total should be £110

  Scenario: Free shipping applies over £50
    Given an order with items totalling £60
    When I calculate the total
    Then free shipping should be applied
```

### BDD Smell Checklist

```
[ ] Scenarios describe implementation steps ("click button X") not behaviour ("user places order")
[ ] Scenario names start with "test" instead of describing a business event
[ ] Scenarios have more than ~5 steps (too much, split it)
[ ] Given/When/Then mixed within a step
[ ] No non-technical stakeholder could read and validate the scenario
```
