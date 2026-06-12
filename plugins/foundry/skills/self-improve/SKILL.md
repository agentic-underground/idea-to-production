---
name: self-improve
description: >
  Reflect on ONE marketplace element (an agent, skill, command, or knowledge doc) against the KAIZEN
  covenant and the three pillars, and improve it — most often by SELF-CLEAVING an over-broad element
  into smaller, more single-purpose ones, or by replacing restated knowledge with a reference. Trigger
  with /foundry:self-improve <path|name> (or "self-improve the X agent", "this skill does too much —
  cleave it", "make this single-purpose"). Applies the change on a branch, runs /foundry:pr-review, and —
  under pr-approval governance — opens a PR for the human to merge, so every marketplace user inherits
  the improvement. Targeted at one element; for a whole-plugin audit use /foundry:inspect.
metadata:
  type: producer
  output: a cleaved/improved element on a branch → adversarial review → PR (per merge governance)
  composes: [inspector (criteria), pr-review (gate), merge-governance (delivery)]
model: inherit
---

# FOUNDRY — Self-Improve (the self-cleaving loop)

The marketplace is **self-improving**: when an element learns it could be better, it folds the fix
back into itself and ships it to all users. This skill is that loop, **targeted at one element**. It
is the operational form of the KAIZEN covenant's *self-cleaving* clause
([`../../knowledge/architecture/kaizen-covenant.md`](../../knowledge/architecture/kaizen-covenant.md))
and the §6 self-improving principle
([`../../knowledge/first-principles.md`](../../knowledge/first-principles.md) §6).

> **Self-improve vs inspect.** `/foundry:inspect` audits the **whole plugin** and reports a
> severity-ranked list. `/foundry:self-improve` takes **one element** and *makes it better* — usually
> by cleaving it. Inspect *sweeps the whole plugin*; self-improve *takes one element and makes it
> better*. (Both can apply fixes; the axis is **scope**, not who-fixes.)

> **GUARDRAIL — never self-merge.** A self-improvement is still a covenant change: it is **proposed,
> reviewed, and merged**, never silently self-applied. Under `pr-approval`
> ([`../../knowledge/protocols/merge-governance.md`](../../knowledge/protocols/merge-governance.md))
> this skill stops at an open PR; it does not merge its own work.

---

## Quick start

```bash
/foundry:self-improve agents/founder.md          # reflect on one element and improve/cleave it
/foundry:self-improve handler-python             # by name
/foundry:self-improve --dry-run skills/builder   # propose only; write no changes
```

---

## 1. Reflect — is this element honouring the covenant?

Read the target and judge it against the same lenses the `inspector` uses
([`../../agents/inspector.md`](../../agents/inspector.md)), focused on **this one element**:

- **Single-Responsibility (the cleave trigger).** Does it do **more than one thing**? Name each
  distinct responsibility you can find. Two or more ⇒ a cleave candidate.
- **Knowledge-restatement.** Does it **restate** canon that lives in `knowledge/` instead of
  referencing it? (The standing drift named in
  [`../../knowledge/architecture/self-architecture.md`](../../knowledge/architecture/self-architecture.md).)
  ⇒ replace the copy with a reference + a certainty marker.
- **Clarity / Interface-segregation.** Must a reader parse the whole thing to use one part? ⇒ split
  into self-contained sections or files.
- **Drift / freshness.** Stale names, dead links, outdated patterns, a `model:` disagreeing with
  [`../../knowledge/policy/model-selection.md`](../../knowledge/policy/model-selection.md)?
- **Portability.** Any machine-specific or `~/.claude`-style coupling, or a load-bearing relative link
  that escapes the plugin root? (Per the inspector's portability sweep.)

If the element is already tight and single-purpose, **say so and stop** — a forced cleave that trades
one clean element for two tangled ones violates the covenant. Not every element needs splitting.

## 2. Decide — cleave, refactor, or reference

| Defect | Move |
|---|---|
| **Breadth** (does N things) | **Cleave**: split into N smaller elements that each do one thing; leave a pointer from the old location; preserve every behaviour (Liskov — no downstream consumer breaks). |
| **Restated knowledge** | **Reference**: delete the copy, link the canonical home, tag the link with a certainty marker if it is consequential. |
| **Tangled section** | **Segregate**: make sections self-contained so a reader loads only what they need. |
| **Drift** | **Repair at the source**: fix the name/link/model, and if it recurs, fold a guardrail upstream so it cannot return. |

> **THE ONLY WAY — cleave along the seam of responsibility, not down the middle of a sentence.** A
> good cleave produces elements a cold-start agent can use independently; a bad one scatters one
> coherent idea across two files. When in doubt, prefer a smaller, sharper element over a clever split.

For a cleave, also **rewire**: update every reference to the old element (agent-roster, VALUE_FLOW,
the glossary, any skill that spawned it) so nothing dangles — and register any **new** element exactly
as the propagation checklist in
[`../../knowledge/protocols/context-sentinel.md`](../../knowledge/protocols/context-sentinel.md) requires.

> **Auto-stub docs + glossary on cleave (P2-12 — yes-heal, a stub is acceptable).** A cleave is not done
> until every **newly born** agent/skill has its documentation and **glossary** entry. A new element that
> exists in `agents/`/`skills/` but is absent from the glossary
> ([`../../knowledge/glossary.md`](../../knowledge/glossary.md)) is undiscoverable and will fail the
> doc-link / glossary-coverage checks. So when this cleave creates a new element, **auto-stub** in the
> same change: a minimal one-line glossary entry (name → what it denotes, placed in the right section of
> the conceptual-domain tree) and any docs entry the propagation checklist names (agent-roster row,
> VALUE_FLOW mention). The stub is deliberately minimal — a placeholder a later pass fleshes out — but it
> **must exist and resolve**; an honest stub beats a dangling reference. This is the glossary/`docs` line
> of the context-sentinel propagation checklist applied to *new elements*, automated at cleave time.

## 3. Apply — on a branch, behind the gate

1. If `--dry-run`: present the proposal (what cleaves into what, or what becomes a reference) and stop.
2. Otherwise, on a **feature branch**, make the surgical change — one element's improvement, no
   unrelated edits.
3. Run **`/foundry:pr-review`** ([`../pr-review/SKILL.md`](../pr-review/SKILL.md)). A
   `NEEDS_REVISION`/`BLOCK` verdict loops back to revision; only a **PASS** proceeds.
4. Deliver per **merge governance**: under `pr-approval`, push the branch and **open a PR** (targeting
   `main`) whose body carries the reflection + the review verdict, then **stop — the human merges**;
   under `direct-merge`, merge to `main`. Either way, **every marketplace user inherits the
   improvement** on merge.

## 4. The loop closes

Each self-improve pass must leave the element **measurably closer to flawless** — at least halving the
remaining distance (the covenant's prime law). A pass that does not is not done. Record any recurring
defect class as a guardrail so the next element of that class is born without it.

---

## Self-improvement covenant

This skill is itself subject to the covenant it runs. If `/foundry:self-improve` ever finds it is
doing more than one thing — say, *reflection* and *delivery* have grown into two jobs — it should
**cleave itself**, the same way it cleaves any other element. Flag recurring patterns for the
self-improvement covenant ([`../../knowledge/architecture/kaizen-covenant.md`](../../knowledge/architecture/kaizen-covenant.md)).
