# Pillar 2 — Quality as a First-Class Concern

> **Bindings:** *quality-first* ≡ *quality-confidence*. (See the core language in [`../glossary.md`](../glossary.md) and [`../first-principles.md`](../first-principles.md) §1.)

Quality is **built in**, not inspected in. It is engineered across a full assurance chain,
and every layer is strengthened by a **performance-delta gate**. Quality is not a phase at the
end; it is a property of every station.

## The assurance chain
Each layer asserts something the layer above cannot, and none may be skipped:

```
EARS spec ──▶ FEATURE docs (BDD) ──▶ UNIT assertions ──▶ COMPONENT assertions
          ──▶ CONNECTED-SYSTEM assertions ──▶ STORY proofs
                         every layer ⊣ perf-delta gate
```

| Layer | Asserts | Owned by |
|---|---|---|
| **EARS** | the requirement is unambiguous and testable | `specs/ears.md` |
| **FEATURE (BDD)** | the behaviour — happy, unhappy, abuse — is specified | `specs/bdd-gherkin.md` |
| **UNIT** | one pure function/type is correct in isolation (a *coordinate*, see VALUE_FLOW §7) | `testing/test-policy.md` |
| **COMPONENT** | one module's public surface holds together | `testing/test-policy.md` |
| **CONNECTED-SYSTEM** | the seams between modules carry their contracts | `testing/test-policy.md` |
| **STORY** | a user-meaningful journey works through the real interface | `testing/test-policy.md` |

## Coverage is the floor, not the goal
- **100% line coverage** of changed code is the definition of done, not an aspiration.
- The only legitimate path below it is an explicit `# pragma: no cover` (or stack equivalent)
  with a **documented reason** (untestable seam, platform shim, legacy boundary).
- **99% is a bug, not "nearly done."** An unexplained uncovered line is treated exactly like a
  missing test. See `testing/test-policy.md` and `testing/coverage-commands.md`.

## The performance-delta gate
Every test level emits a **performance sample** (time; and where meaningful: allocation,
wasm-bundle delta, payload size). The **STORY** level runs with a **gated perf-delta check**:

> A STORY whose performance regresses past the configured budget versus the recorded baseline
> **does not merge.** The gate runs *with* the STORY tests, not as a separate afterthought.

This makes performance a **blocking** quality dimension, owned by the `PERFORMANCE-REVIEWER`
role on the `reviewer` panel. A significant regression at any instrumented layer halts the line
the same way a failing assertion does. The perf budget and baseline source are declared per
project in its QA definition.

## The gate is the certifying station — never weaken it

> **GUARDRAIL — the single most important process rule:** **Never weaken a gate to make the line
> go green.** Not an `#[allow(...)]`/`# noqa` to silence a linter, not an `#[ignore]`/`skip` on a
> failing test, not dropping a `-D warnings`-class strictness. The gate is the station that
> *certifies* freight; a weakened gate certifies broken freight. **Fix the code, never the gate.**

A gate is a *station*, not an afterthought: freight may not advance without its exit certificate.
This is why the assurance chain above is mechanical rather than aspirational.

## Verify against the deployed artefact, not localhost

> **IMPORTANT — THE ONLY WAY:** A slice is "done" only when its behaviour is verified against the
> **deployed** artefact, through the real interface — not against a local dev server. The line gains
> two terminal stations, **DEPLOY** and **VERIFY**, and VERIFY runs a fixed verification matrix
> against production (`skills/lifecycle-states/states/production-readiness.md`; concrete example in
> `skills/rust-webapp-rollout/`). "It works on my machine" is not an exit certificate.

## The adversarial roles

Quality is also *defended*, not just measured. Beyond the `reviewer` panel, two adversarial stances
carry every risky slice: a **reviewer** whose job is to *find reasons not to merge* (and who
**actually runs the gate**, never trusting a claim), and a **security-auditor** who assumes
**inputs are hostile and dependencies guilty until proven innocent** — a reachable panic in a
request path is an availability **BLOCKER**. When the `security` plugin is installed, its
`/security:scan-all` is that auditor made mechanical.

## Why first-class
Tying back to Pillar 3 (`pillars/waste-elimination.md`): **a bug found in development is far
less wasteful than a bug found in production.** Every gate here is an early, cheap place to
catch a defect before it becomes an expensive one. More (early) testing is *less* waste. The
determinism that makes a gate's verdict trustworthy is its own pillar-facet
(`pillars/determinism-and-pinning.md`): a gate can only certify if the same input yields the same
output.
