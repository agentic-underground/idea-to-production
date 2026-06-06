# The idea-to-production product lifecycle

> The organising spine of the marketplace. Every plugin is a **phase** of one lifecycle that carries a
> product from **the search for an idea** to **IN PRODUCTION** — realised and live. This document is the
> canonical articulation; the statusline phase widget, `/i2p-help`, and `/i2p-lifecycle` all read it.

## What "product lifecycle" means here

The academic literature uses *two distinct* "product life cycles", and conflating them causes drift:

- **The market life cycle** (marketing): *introduction → growth → maturity → decline.* This is the
  product's life **after** it launches — how it sells over time.
- **The creation arc** (engineering PLM + New Product Development): *Fuzzy Front End → development →
  commercialization.* This is how the product is **brought into being**.

**idea-to-production is the creation arc.** It begins in the **Fuzzy Front End** — "the search for an
idea" — and ends at **commercialization / realization**: the idea is **IN PRODUCTION** (realised & live).
The market life cycle begins exactly where idea-to-production ends, and is **downstream / out of scope**
here (acknowledged, not tooled).

> Vocabulary note: in manufacturing PLM, "production" means *making units*; in idea-to-production,
> **IN PRODUCTION** means *realised and operating* — the software/operational sense, matching the NPD
> "commercialization" endpoint. We keep the idea-to-production philosophy and **annotate** it with the
> state-of-the-art frames below; we do not migrate to any single school.

## The phases

The lifecycle is **six working phases** → a terminal state, each owned by one plugin and grounded in the
named canon. (State-file token in brackets — see `skills/lifecycle/`.)

| # | Phase `[token]` | Owner | Value added | Canon lineage |
|---|---|---|---|---|
| ① | **DISCOVER** `[DISCOVER]` | market-scanner | find a problem worth solving; kill weak ideas early | Fuzzy Front End (opportunity identification) · Double Diamond **Discover** (diverge: problem) |
| ② | **IDEATE** `[IDEATE]` | ideator | turn the opportunity into a build-ready IDEA package at knowledge-parity | Double Diamond **Define** (converge: concept) · NPD concept development · design-thinking *empathize/define* |
| ③ | **DESIGN** `[DESIGN]` | atelier | make the experience usable, elegant, accessible | Double Diamond **Develop** (diverge: solution) · design thinking *ideate/prototype* |
| ④ | **BUILD** `[BUILD]` | foundry | realise it test-first through the value conveyor (IDEA▶…▶SHIP) | Double Diamond **Deliver** · NPD development · PLM **Realize** |
| ⑤ | **ASSURE** `[ASSURE]` | sentinel | prove it is safe & sound before it ships | Verification & Validation · quality gate (PDCA *check* / DMAIC *control*) |
| ⑥ | **PUBLISH** `[PUBLISH]` | pressroom | announce & document it for its audience | commercialization / launch communication |
| ★ | **IN PRODUCTION** `[IN_PRODUCTION]` | — | the idea is realised & live | NPD commercialization endpoint; entry to the market life cycle (downstream) |

**DESIGN cross-cuts.** atelier also reviews surfaces produced during BUILD; the table lists each plugin
at its *primary* phase.

## Binding the domain — five lenses on one arc

idea-to-production deliberately speaks five vocabularies at once, because a product is all of them:

- **product / engineering** — PLM conceive→design→realize; the conveyor and its gates (BUILD, ASSURE).
- **manufacture** — "realize / make"; the test-first conveyor is the production line (BUILD).
- **artistic expression** — conception → study → composition → critique → exhibition; the designer↔reviewer
  loop and the publishing craft (DESIGN, PUBLISH).
- **commerce** — opportunity → willingness-to-pay → go-to-market; the front end and launch (DISCOVER, PUBLISH).
- **quality** — built-in not inspected-in; PDCA/DMAIC; the perf-delta and security gates (ASSURE, and the
  quality pillar throughout).

## Entry / exit signals

A phase is *entered* when its predecessor's exit signal fires, and *exited* when its artifact exists:

- DISCOVER → IDEATE: a **kept OPPORTUNITY** (market-scan verdict).
- IDEATE → DESIGN/BUILD: a **handoff-contract-complete IDEA package** (foundry discovery exit criteria).
- DESIGN → BUILD: design-reviewed surfaces clear the **design-fitness rubric** (when UI is in scope).
- BUILD → ASSURE: the conveyor reaches **SHIP** (tests green, story proven).
- ASSURE → PUBLISH: a **PASS** security-gate verdict.
- PUBLISH → IN PRODUCTION: the release artefacts are out; the idea is **realised & live**.

## How the marketplace aligns to this spine

- The **state file** `.i2p/lifecycle.json` records `current_phase`. Each owning plugin **advances it at
  its own exit signal** by calling `/i2p-lifecycle done <its-phase>` (by capability — only when i2p is
  installed). `done` is **order-safe & idempotent**: it advances *only if* the lifecycle is at that phase,
  so a plugin can never jump it out of order or auto-start it. Helper:
  `skills/lifecycle/scripts/lifecycle.sh` (`init|get|status|done|set|advance`).
- The **statusline** phase widget (shipped by `concierge`) reads it and shows `◆ lifecycle … (n/7)`.
- **`/i2p-help`** explains this lifecycle and offers to **kick one off**; **`/i2p-lifecycle`** initialises
  and reports it.
- This doc is referenced by `foundry/VALUE_FLOW.md` and the glossary so the whole suite shares one spine.

> Self-improvement covenant: if a phase, owner, or lineage here drifts from how the plugins actually
> behave, fix it **here once** — every surface that renders the lifecycle inherits the correction.
