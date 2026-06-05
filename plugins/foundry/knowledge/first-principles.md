# FOUNDRY — First Principles (the philosophical spine)

> **What this is.** `VALUE_FLOW.md` is the **operational** spine — *how* value moves. This is the
> **philosophical** spine — *why* the system is shaped the way it is. Every meta-principle below is
> stated once, **bound** to its other names (so you can recognise it however it surfaces), and linked
> to its canonical home. This doc **names and binds**; it does not restate the homes' detail
> (token-efficiency). When a worker or an orchestrator needs alignment, it reads here.

> **Bindings.** Each principle carries multiple **bindings** — a *formal* definition, *aliases*, and a
> *metaphor* — because a principle you can only name one way is a principle you will fail to recognise
> when it wears a different coat. (Precedent: the certainty-markers protocol binds one truth four ways.)

---

## 0. The driving force — *the conveyor*

**Formal:** FOUNDRY is one capability — *a conveyor that carries **VALUE** from **IDEA** to
**PRODUCTION***, staffed by role-tuned agents. · **Aliases:** the value-flow; idea→production; the
production facility. · **Metaphor:** a factory line, not a filing cabinet — it does not *store*
configuration, it *carries* value. · **Home:** [`VALUE_FLOW.md`](../VALUE_FLOW.md).

Everything else exists to make that carriage **aligned**, **confident**, and **waste-free**.

---

## 1. The three pillars (+ their bindings) and the one overarching constraint

The pillars govern the behaviour of **every** element. The user's phrasings are first-class bindings.

| Pillar (canonical) | Binding (alias) | Formal essence | Home |
|---|---|---|---|
| **Knowledge-parity** | **knowledge-alignment** | The agent fully and clearly understands the ask **before** it acts; recurring questions become written answers, never asked twice. | [`pillars/knowledge-parity.md`](pillars/knowledge-parity.md) |
| **Quality-first** | **quality-confidence** | Quality is **built in, not inspected in** — engineered across the whole assurance chain and strengthened by a performance-delta gate; a gate is never weakened to make progress. | [`pillars/quality-first.md`](pillars/quality-first.md) |
| **Waste-elimination** | (waste-elimination) | The systematic identification and removal of waste in all seven forms — *including rediscovery*: a bug found in development is far less wasteful than one found in production. | [`pillars/waste-elimination.md`](pillars/waste-elimination.md) |

> **The overarching constraint — token-efficiency.** Passing context to a model is a potentially
> wasteful operation. *Thin skills, fat references · define-once, reference-many · station-scoped
> loading.* It is the hard design rule that rides the whole carriage alongside the pillars.
> **Home:** [`token-efficiency.md`](token-efficiency.md). · **Binding:** progressive disclosure.

---

## 2. Tests are coordinates — the code philosophy

**Formal:** a well-formed failing test is a **coordinate in multidimensional logical space** — a
precise `input → expected output` assertion against a *pure* function that pins the exact working code
in the space of all possible implementations. · **Aliases:** a *pin*; a *location*; a *proof
obligation*; **the reason to write code**. · **Metaphor:** a surveyor's fix, not a description drawn
afterward.

> **IMPORTANT — THE ONLY WAY:** A test provides the **reason** to write code, and that code must, by
> necessity, produce **only a PASS**. You do not write code and then check it; you place the
> coordinate, then write the one implementation that turns it green. A test written *after* the code
> is a description; one written *before* is a location.

**The SOLUTION (a deliberate double binding, homed here).** It is the **sum and combination of all the
coordinates** that causes the code to provide the **SOLUTION** — meaning *both* (a) the **problem
solved**, *and* (b) the **solvent-matrix** in which component additives dissolve: each coordinate is a
compound dissolved into the code until the mixture, taken whole, *is* the answer. Code is a solution in
both senses at once. The *coordinate / location* reading is canonical in
[`testing/test-policy.md`](testing/test-policy.md) §Coordinates in practice and
[`../VALUE_FLOW.md`](../VALUE_FLOW.md) §7; the **solvent-matrix** reading originates here. Every
test-producing agent **will carry** a short pointer to this framing (the weave lands in a follow-up).

---

## 3. Pure core — the geometry that makes coordinates possible

**Formal:** extract the **decidable core** (the logic that must be correct) into a pure module — no
I/O, no UI, no platform, no panics — and let everything else be **thin wiring** that consumes it;
dependencies flow **one way only, inward**. · **Aliases:** the decidable core; the sacred core;
one-way dependency. · **Metaphor:** a clean room — coordinates can only be placed where no side effect
blurs the location. · **Why it matters:** pure ⇒ testable ⇒ coordinate-able ⇒ **maximally parallel**.
· **Home:** [`architecture/pure-core.md`](architecture/pure-core.md).

---

## 4. The SOLID covenant — SOLID applied to *agent documents*

**Formal:** the marketplace applies the SOLID rules of **code** design to its own **documents** —
Single-Responsibility, Open/Closed, Liskov-substitution, Interface-segregation, Dependency-inversion —
so an agent file is engineered like a well-formed module. · **Prime law:** each iteration must at
least **halve the remaining distance to perfection**. · **Self-cleaving:** when the defect is
*breadth* (an element does more than one thing), it **cleaves** into smaller, more SOLID-adherent
elements and rewrites itself — shipping the improvement to all users via PR (§6). · **Aliases:** the
covenant; halve-the-distance; self-cleaving. · **Home:**
[`architecture/solid-covenant.md`](architecture/solid-covenant.md).

---

## 5. Reasoning travels with the rule — markers & the ledger

**Formal:** every consequential statement is tagged so the *why* travels with the *what* —
`THE ONLY WAY` / `GUARDRAIL` / `ANTI-PATTERN` / `WORKED EXAMPLE` — and every known failure becomes a
ledger entry **symptom → cause → fix**, so the cost of a bug is paid **once**. · **Aliases:** certainty
markers; the guardrails ledger; the FORBIDDEN list; pay-the-cost-once. · **Metaphor:** a scar that
teaches — written *after* the mistake, so when a marker and your instinct disagree, **the marker
wins**. · **Homes:** [`protocols/certainty-markers.md`](protocols/certainty-markers.md) ·
[`protocols/guardrails-ledger.md`](protocols/guardrails-ledger.md).

This is the **worker tier's memory**: the record of *what works and what does not, and why* (§7).

---

## 6. The self-improving marketplace — fix upstream once, ship to all

**Formal:** when an element learns something by making (or catching) a mistake, the fix is folded
**back into the marketplace at its source** — a guardrail, a sharper rule, a template, or a
**self-cleave** — so no future build pays for it again; the change lands via branch →
**`/foundry:pr-review`** (always-on adversarial gate) → **PR under merge-governance**, so **every user
of the marketplace inherits the enhancement**. · **Aliases:** fix-upstream-once; self-cleave-and-PR;
the self-improving marketplace. · **Homes:** [`architecture/solid-covenant.md`](architecture/solid-covenant.md)
· [`protocols/merge-governance.md`](protocols/merge-governance.md) · the `pr-review` skill and the
`inspector` agent (with a dedicated `self-improve` skill as the planned driver of the self-cleave loop).

---

## 7. Two altitudes of guidance — workers and orchestrators

The conveyor aligns at **two altitudes**, and both are required:

| Altitude | Who | Bound by | Carries |
|---|---|---|---|
| **Workers (pragmatic)** | the value-handlers, the `ds-step-*` implementers | **exact patterns** | stack-precise habits, guardrails ledgers, FORBIDDEN lists, the *what-works / what-doesn't & why* record |
| **Orchestrators (aligned)** | `founder` · `builder-lead` · `lifecycle-orchestrator` · `reviewer` | **shared philosophy** | the pillars, the shared language (this doc + the glossary), the procedures and exit-certificates |

> High-level guidance (philosophy, procedure, language) **couples with** low-level pragmatics (exact
> code patterns, ledgers). A worker without patterns drifts; an orchestrator without shared language
> fragments. The marketplace keeps **both** taut. · **Binding:** the two altitudes; managers &
> makers. · See [`architecture/self-architecture.md`](architecture/self-architecture.md).

---

## How this doc is governed

It obeys what it preaches: it does **one** thing (name & bind the meta-principles), **references**
every home instead of restating it, and is **substitutable** for a hand-written first-principles
brief. The marketplace browses its **core language** in [`glossary.md`](glossary.md) §Core language.
