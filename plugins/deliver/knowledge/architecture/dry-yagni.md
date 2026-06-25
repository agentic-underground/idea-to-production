# DRY / YAGNI / KISS Reference

> For CODE_QUALITY skill — Lens: DRY / YAGNI / KISS.
> Load when reviewing any codebase for duplication, over-engineering, or unnecessary complexity.

---

## DRY — Don't Repeat Yourself

> *"Every piece of knowledge must have a single, unambiguous, authoritative representation within a system."*
> — The Pragmatic Programmer

DRY is about knowledge duplication, not code duplication. Two identical loops are not a DRY violation if they represent different concepts. Two identical functions that enforce the same business rule *are* a DRY violation.

### DRY Violations to Look For

| Pattern | Description | Smell |
|---|---|---|
| Duplicated logic | Same condition, computation, or transformation in ≥ 2 places | Any change requires changing N files |
| Magic literals | Same string/number repeated across files with no shared constant | `"admin"` appears 14 times; change one, miss the rest |
| Parallel class hierarchies | Two inheritance trees that always change together | New type X requires changes in hierarchy A and B |
| Copy-paste with variation | Blocks that are 90% identical, differing in one variable | Extract with parameter |
| Repeated test setup | The same `before_each` logic duplicated across test files | Shared fixture or factory missing |
| Documentation drift | Comments that duplicate (and diverge from) the code they describe | "This comment is lying to me" |

### DRY in Practice

**Rule of Three:** Tolerate duplication once. The second time, note it. The third time, extract it.

**Finding duplication:**
```bash
# Files with suspicious similarity (adjust min-lines)
diff <(sort file1.py) <(sort file2.py)

# Repeated string literals in Python
grep -rn '"your-literal"' src/

# Similar function signatures
grep -rn "def process_" src/
```

**Extraction strategies:**
- Shared value → named constant or config entry
- Shared logic → extracted function or method
- Shared type → base class, mixin, or protocol
- Shared test setup → fixture, factory, or helper

### DRY Anti-DRY (Wrong Extractions)

Not all duplication should be eliminated. Premature DRY creates coupling:

- **Accidental duplication**: Two functions look the same today but will diverge. Don't extract.
- **Context-sensitive logic**: Same formula, different semantic meaning. Don't extract.
- **Test clarity**: Tests sometimes repeat setup explicitly for readability. Tolerate it.

---

## YAGNI — You Aren't Gonna Need It

> *"Always implement things when you actually need them, never when you just foresee that you need them."*
> — Ron Jeffries

YAGNI forbids building for hypothetical future requirements. Every premature feature adds maintenance burden, increases the surface area for bugs, and makes the codebase harder to understand.

### YAGNI Violations to Look For

| Pattern | Signal phrase | Finding |
|---|---|---|
| Unused parameters | Function takes `mode` but only `mode="default"` is ever passed | Remove the parameter |
| Speculative abstraction | Interface with one implementation, no planned second | Flatten to concrete class |
| Unused flags / feature toggles | `if feature_enabled("new_ui")` never toggles to True in tests | Remove the branch |
| Over-generalised config | Config system supports 12 options; 2 are ever set | Simplify to what's used |
| Placeholder code | `# TODO: implement caching here` with no ticket | Delete the comment |
| Pre-emptive pagination | API returns paginated response for a dataset of 50 items | Add when needed |

### YAGNI Evaluation Questions

For each abstraction, ask:
1. Is there more than one concrete user of this today?
2. Is there a committed roadmap item that will need this within 2 weeks?
3. Would removing it require changing anything that works?

If all three answers are "no", it's YAGNI. Propose removal.

### YAGNI Exception: Genuine Extension Points

YAGNI does not forbid designing for change at known seams. If:
- The team has committed to multiple implementations (SOLID OCP)
- The extension point costs almost nothing to keep
- Removing it would require a later refactor of significant scope

...then keeping the extension point is justified. Document why it exists.

---

## KISS — Keep It Simple, Stupid

> *"Simplicity is the ultimate sophistication."* — misattributed to many, lived by few

Complexity is the primary driver of bugs, slow onboarding, and maintenance cost. KISS demands that every design decision prefer the simplest solution that works.

### Complexity Indicators

| Signal | Description |
|---|---|
| Deep nesting | `if` inside `for` inside `try` inside `with` — cognitive load increases exponentially |
| Long functions | > 20 lines is a signal; > 40 lines is a smell; > 80 lines is a problem |
| Many parameters | > 4 parameters: consider a data class or builder |
| Boolean parameters | `send_email(user, True)` — what does `True` mean? |
| Clever code | Code that requires a comment to explain what it does |
| Indirect reads | Reaching through 4 layers of objects to get a value |
| Unnecessary state | Mutable state that could be computed from inputs |

### Cyclomatic Complexity

Cyclomatic complexity counts the number of linearly independent paths through a function.

| Complexity | Risk |
|---|---|
| 1–5 | Simple, low risk |
| 6–10 | Moderate; consider splitting |
| 11–15 | High; split required |
| 16+ | Untestable; redesign required |

```bash
# Python: radon
pip install radon
radon cc src/ -s -a

# JavaScript: plato or eslint complexity rule
# Go: gocyclo
```

### KISS Refactoring Moves

| Problem | Fix |
|---|---|
| Deep nesting | Early return / guard clause |
| Long function | Extract function with descriptive name |
| Boolean parameter | Replace with two named functions |
| Complex expression | Extract to named variable |
| State mutation | Convert to pure function returning new value |
| Over-engineering | Delete the abstraction; use the concrete type |

---

## Integrated Lens: DRY × YAGNI × KISS

The three principles reinforce each other:

- **DRY** prevents maintenance burden from scattered knowledge
- **YAGNI** prevents speculative complexity before it's needed
- **KISS** cuts complexity after it accumulates

When reviewing code, ask for each module:
1. **DRY**: Is the same knowledge expressed in more than one place?
2. **YAGNI**: Is there code that exists for a use case that doesn't exist yet?
3. **KISS**: Is there a simpler way to express what this code does?

---

## Finding Format

When reporting DRY/YAGNI/KISS findings:

```
### DRY / YAGNI / KISS
**Status:** [✅ / 🟡 / 🟠 / 🔴]

**Findings:**
- [file:line] [Pattern name]. [What is duplicated/unnecessary/complex].
  [Specific refactor recommended].

**Coverage impact:** [How coverage affects the risk of this refactor]
```
