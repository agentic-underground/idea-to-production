# Clean Code Reference

*Robert C. Martin — Clean Code: A Handbook of Agile Software Craftsmanship*

---

## Names

| Principle | Bad | Good |
|---|---|---|
| Reveal intent | `d` | `elapsedTimeInDays` |
| No noise words | `ProductInfo`, `ProductData` | `Product` |
| Pronounceable | `genymdhms` | `generationTimestamp` |
| Searchable | `7` | `MAX_RETRIES` |
| No encodings | `m_name`, `iCount` | `name`, `count` |
| Class = noun | `Manager`, `Processor` | `Account`, `Parser` |
| Method = verb | `getName()` | `getName()` / `save()` |
| One concept per word | `fetch`, `retrieve`, `get` (all meaning the same) | pick one and stick to it |

**Smell signals:** abbreviations, single letters (outside `i` in loops), numeric suffixes (`str1`, `str2`), type-encoded names, inconsistent vocabulary across the codebase.

---

## Functions

- **One thing only.** If you can extract a sub-function with a name that is not a restatement of its body, you have more than one thing.
- **One level of abstraction per function.** Don't mix `getHtml()` with `StringBuilder.append("\n")`.
- **Command-Query Separation.** A function either does something OR answers something. Never both.
- **No side effects.** A function named `checkPassword()` should not initialise a session.
- **Prefer exceptions to error codes.** Error codes pollute the call site with if-chains.
- **Don't repeat yourself.** Duplication is the root of all evil in software.
- **Max ~20 lines** (guideline, not rule). If you're scrolling, something's wrong.
- **Max 2–3 parameters.** More → consider a parameter object.

---

## Comments

**Comments are a failure to express intent in code.**

| Acceptable | Unacceptable |
|---|---|
| Legal headers | Noise: `// Default constructor` |
| Intent explanation (why, not what) | Redundant: `i++; // increment i` |
| Warning of consequences | Mandated: JavaDoc on every method |
| TODO (with ticket reference) | Journaling: `// Changed 2020-03-04` |
| Public API documentation | Commented-out code |

**If you feel the need to explain *what* the code does, rewrite the code.**

---

## Error Handling

- Use exceptions, not return codes.
- Create informative error messages (context, intent, failure type).
- Don't return `null` — prefer Optional, empty collections, or throw.
- Don't pass `null` — design APIs that don't accept it.
- Wrap third-party APIs — define your own exception hierarchy.

---

## Objects and Data Structures

- **Objects** expose behaviour, hide data (getters/setters are not OO).
- **Data structures** expose data, have no significant behaviour.
- The Law of Demeter: a method should only call methods of:
  - Its own class
  - An object it created
  - An object passed to it as argument
  - An object it holds as a field
- Avoid train wrecks: `a.getB().getC().doSomething()` — each `.` is a violation.

---

## Classes

- **Single Responsibility:** a class has one reason to change.
- **Small.** Measured by responsibilities, not lines.
- **High cohesion:** class variables used by most methods.
- **Open/Closed:** open for extension, closed for modification.
- **Organise for change:** group things that change together.

---

## Systems

- **Separate construction from use.** Don't build the world in `main()`.
- **Dependency injection** over manual construction.
- **Cross-cutting concerns** (logging, transactions) belong in aspects/middleware, not tangled through business code.
- **Delay decisions** until the last responsible moment — you'll have more information.

---

## Smell Checklist (use during code review)

```
[ ] Long method (> 20–30 lines)
[ ] Long parameter list (> 3)
[ ] Duplicated code
[ ] Shotgun surgery (one change → many classes touched)
[ ] Feature envy (method uses another class's data more than its own)
[ ] Data clumps (same 3 fields always appear together → extract object)
[ ] Primitive obsession (string for email, int for money → value objects)
[ ] Switch statements on type codes → polymorphism
[ ] Parallel inheritance hierarchies
[ ] Lazy class (does nothing → merge or delete)
[ ] Speculative generality (code for hypothetical future needs)
[ ] Temporary field (field only set in some cases)
[ ] Message chains (train wrecks)
[ ] Middle man (delegates everything → remove)
[ ] Inappropriate intimacy (classes know each other's internals)
[ ] Alternative classes with different interfaces
[ ] Incomplete library class
[ ] Data class (only getters/setters, no behaviour)
[ ] Refused bequest (subclass doesn't use parent's interface)
[ ] Comments explaining what, not why
```
