# EARS Quick Reference

> For ROADMAPPER §8. EARS (Easy Approach to Requirements Syntax) is a structured
> natural language format for writing unambiguous, machine-readable requirements.
> Read this file before writing or reviewing any EARS statement.

---

## The Five EARS Forms

| Form | Keyword | Template |
|---|---|---|
| Ubiquitous | (none) | The system SHALL `<response>`. |
| Event-driven | WHEN | WHEN `<trigger>` THE SYSTEM SHALL `<response>`. |
| Unwanted behaviour | IF | IF `<condition>` THEN THE SYSTEM SHALL `<response>`. |
| State-driven | WHILE | WHILE `<state>` THE SYSTEM SHALL `<behaviour>`. |
| Optional feature | WHERE | WHERE `<feature>` THE SYSTEM SHALL `<behaviour>`. |
| Complex (combined) | WHEN/IF/WHILE/WHERE | Combine forms only when a single form is insufficient. |

---

## Mandatory Rules

- Use **SHALL** (mandatory), **SHOULD** (recommended), or **MAY** (optional) deliberately — never interchange them.
- Each statement covers **exactly one behaviour**. If you need "and", split into two statements.
- Every statement must be **independently testable** — if you cannot write a failing test for it, rewrite it.
- Assign a **unique ID** to each statement (e.g. `EARS-001`). IDs are permanent — never reuse a retired ID.
- Avoid vague qualifiers: "fast", "secure", "user-friendly" are not EARS. Use measurable thresholds.

---

## Good vs Bad Examples

| Bad | Why | Good |
|---|---|---|
| The system shall be fast. | Not testable | WHEN a user submits a search, THE SYSTEM SHALL return results within 500 ms. |
| The system shall handle errors and log them and notify admins. | Three behaviours in one | Split into three separate EARS statements. |
| The system should validate input. | No trigger, no actor | WHEN a user submits a form, THE SYSTEM SHALL validate all fields before processing. |

---

## ID Assignment Convention

```
EARS-{NNN}   — three-digit zero-padded integer, e.g. EARS-001, EARS-042, EARS-100
```

When appending to an existing specification, increment from the highest existing ID.
Never reorder or renumber existing IDs — downstream tests and Gherkin tags depend on them.

---

## Coverage Requirements (per ROADMAPPER §9)

Every EARS statement must be covered by:
- ≥ 1 Gherkin scenario tagged `@EARS-{ID}`
- ≥ 1 test (unit or integration) referencing `# @EARS-{ID}`
- Happy path + unhappy path + abuse/adversarial path scenarios
