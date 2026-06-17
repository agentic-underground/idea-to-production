# The idea-to-production product lifecycle

> The organising spine of the marketplace. Every plugin is a **phase** or a **cross-cutting concern** of one
> lifecycle that carries a product from **the search for an idea** to **IN PRODUCTION** — realised, live, and
> operated. This document is the canonical articulation; the statusline phase widget, `/i2p:help`, and
> `/i2p:lifecycle` all read it.

![The nine-phase value cycle building up stage by stage — DISCOVER, IDEATE, DELIVER, DESIGN, then the BUILD ⇄ ASSURE ⇄ SECURE loop, then PUBLISH and OPERATE — then the return arc glows as OPERATE's learnings re-enter DISCOVER, closing the loop.](../../../docs/images/lifecycle-cycle.gif)

## What "product lifecycle" means here

The academic literature uses *two distinct* "product life cycles", and conflating them causes drift:

- **The market life cycle** (marketing): *introduction → growth → maturity → decline.* This is the
  product's life **in the market** — how it sells over time.
- **The creation arc** (engineering PLM + New Product Development): *Fuzzy Front End → development →
  commercialization → **operation**.* This is how the product is **brought into being and kept alive**.

**idea-to-production is the creation arc, carried through into operation.** It begins in the **Fuzzy Front
End** — "the search for an idea" — runs through **commercialization / realization** (the idea is **IN
PRODUCTION** — realised & live), and does not stop there: it includes **OPERATE**, the living phase where the
product is monitored, kept healthy, and iterated. The market life cycle runs *alongside* OPERATE, and OPERATE's
learnings **loop back to DISCOVER** to open the next value cycle. The lifecycle is therefore a **cycle, not a
dead-end**.

> Vocabulary note: in manufacturing PLM, "production" means *making units*; in idea-to-production,
> **IN PRODUCTION** means *realised and operating* — the software/operational sense, matching the NPD
> "commercialization" endpoint and extending into the PLM **service/operate** stage. We keep the
> idea-to-production philosophy and **annotate** it with the state-of-the-art frames below; we do not migrate
> to any single school.

## Two kinds of lifecycle element

A product is not built by phases alone. Some value is added **once, in sequence** (you discover, then ideate,
then build); other value must be **present from the first moment and woven through every phase** (a product is
not "made usable" or "made secure" at one station — those are properties built in from the start and *certified*
at a gate). So the lifecycle has two kinds of element:

1. **Phases** — the linear value-creation spine. Each transforms the product and has one primary owner.
2. **Cross-cutting concerns** — first-class properties present from the beginning, woven through every phase,
   each owned by one plugin and **certified at a dedicated gate**. There are three: **usability**, **quality**,
   and **security**.

This is why `DESIGN`, `ASSURE`, and `SECURE` are *both* listed as phases (their certifying gate) *and* called
out as cross-cutting — they begin long before their gate and never really stop. The spine is mostly linear, but
the three realisation phases — **BUILD ⇄ ASSURE ⇄ SECURE** — form a **loop**: a failed quality or security gate
sends the work *back* to BUILD, and only when all three are satisfied does the lifecycle advance to PUBLISH (see
[The BUILD ⇄ ASSURE ⇄ SECURE loop](#the-build--assure--secure-loop) below).

## The phases

The lifecycle is **nine working phases** that form a cycle, each owned by one plugin and grounded in the named
canon. (State-file token in brackets — see `skills/lifecycle/`.) The order is **DISCOVER ▸ IDEATE ▸ DELIVER ▸
DESIGN ▸ BUILD ⇄ ASSURE ⇄ SECURE ▸ PUBLISH ▸ OPERATE↻** — note the new **DELIVER** phase between IDEATE and
DESIGN, and the **BUILD/ASSURE/SECURE loop** (the ⇄).

| # | Phase `[token]` | Owner | Value added | Canon lineage |
|---|---|---|---|---|
| ① | **DISCOVER** `[DISCOVER]` | market-scanner | find a problem worth solving; kill weak ideas early | Fuzzy Front End (opportunity identification) · Double Diamond **Discover** (diverge: problem) |
| ② | **IDEATE** `[IDEATE]` | ideator | turn the opportunity into a build-ready IDEA package at knowledge-parity | Double Diamond **Define** (converge: concept) · NPD concept development · design-thinking *empathize/define* |
| ③ | **DELIVER** `[DELIVER]` | flow + `foundry:roadmapper` | turn the IDEA package into a roadmap: intake → EARS/feature authoring → decomposition into atomic, dependency-ordered build-ready items | NPD planning · PLM **plan** · Kahn topological work-ordering · agile backlog decomposition (INVEST, vertical slices) |
| ④ | **DESIGN** `[DESIGN]` | atelier | make the experience usable, elegant, accessible | Double Diamond **Develop** (diverge: solution) · design thinking *ideate/prototype* |
| ⑤ | **BUILD** `[BUILD]` | foundry | realise it test-first through the value conveyor (IDEA▶…▶SHIP) — *loop entry* | Double Diamond **Deliver** · NPD development · PLM **Realize** |
| ⑥ | **ASSURE** `[ASSURE]` | foundry | **certify quality** — adversarial V&V: tests green, coverage density, perf-delta, regression, architecture; *fail → re-enter BUILD* | Verification & Validation · quality gate (PDCA *check* / DMAIC *control*) |
| ⑦ | **SECURE** `[SECURE]` | security | **certify security** — PII, secrets, supply-chain clear before exposure; *fail → re-enter BUILD*, *pass (all three) → exit loop to PUBLISH* | secure-by-design · supply-chain integrity · the security gate |
| ⑧ | **PUBLISH** `[PUBLISH]` | publish | announce & document it for its audience | commercialization / launch communication |
| ⑨ | **OPERATE** `[OPERATE]` | operate | keep it alive & improving: observe, respond to incidents, iterate, maintain | PLM **service/operate** · SRE · the market life cycle (introduction→growth) · DMAIC *control* in production |
| ↻ | *(re-entry)* | market-scanner | OPERATE's learnings open the **next** value cycle | continuous discovery · build-measure-learn |

**ASSURE and SECURE are separate — deliberately.** Quality and security are *different* concerns and must not
be conflated under one gate. **Quality** (ASSURE) asks *"is it correct, tested, performant, regression-free?"*;
**security** (SECURE) asks *"is it safe to expose — no leaked secrets, no PII, no vulnerable deps, no exploitable
code?"* A product can be high-quality and insecure, or secure and broken. Each gets its own owner, its own
verdict, and its own gate.

## DELIVER — from IDEA package to a dependency-ordered roadmap

**DELIVER** is the planning phase between IDEATE and DESIGN. IDEATE produces a build-ready **IDEA package**;
DELIVER turns that package into a **roadmap of atomic, EARS-specified, dependency-ordered build-ready items**
before any surface or code is built. It is a true **phase** (linear value-creation spine, one owner) — not a
cross-cutting concern.

- **Value added** — roadmap **intake** (capture the IDEA package's scope as roadmap items) → **EARS / feature
  authoring** (each item gets a formal EARS specification and `.feature` behaviour) → **decomposition** into
  atomic, dependency-ordered items (right-sized vertical slices, topologically ordered so each item's
  prerequisites land first).
- **Owner** — the new **flow** plugin (the roadmap board + intake surface) together with **`foundry:roadmapper`**
  (the skill that authors EARS specs, generates `.feature` files, and drives decomposition).
- **Entry signal** — IDEATE completes: a **handoff-contract-complete IDEA package** at knowledge-parity (the
  same artifact that READY from the ideator's independent challenger certifies).
- **Exit signal** — a **decomposed, dependency-ordered set of build-ready items** exists (an EARS-specified,
  topologically ordered roadmap). On that signal the lifecycle enters **DESIGN**, which makes those items'
  surfaces usable before BUILD realises them.

## The BUILD ⇄ ASSURE ⇄ SECURE loop

The three realisation phases — **BUILD**, **ASSURE**, and **SECURE** — do **not** form a one-way linear chain.
They form a **loop**, because that is what actually happens: a failed quality review or a failed security gate
sends the work *back* to BUILD to be fixed, not forward to PUBLISH.

- **The loop states** — `BUILD` (realise / fix), `ASSURE` (certify quality), `SECURE` (certify security). The
  lifecycle enters the loop at BUILD when DESIGN completes.
- **The back-edge** — **WHEN ASSURE or SECURE fails, the lifecycle re-enters BUILD** (records the iteration) and
  does **not** advance. A failed gate is a first-class transition, not a manual reset: the owner signals the
  failure and the loop state returns to BUILD.
- **The exit signal — "all three satisfied."** The loop exits to PUBLISH **only when BUILD reaches SHIP**
  (implementation in, tests green, story proven), **ASSURE's quality review PASSES** (foundry's adversarial
  reviewer panel / `/pr-review`), **and SECURE's security-gate PASSES** (PII, secrets, supply-chain clear). When
  — and only when — all three are satisfied, the SECURE transition advances to PUBLISH.

So BUILD/ASSURE/SECURE are a sub-cycle inside the larger value cycle: iterate BUILD → ASSURE → SECURE until the
product is simultaneously shipped, quality-certified, and security-certified, then leave the loop for PUBLISH.

## The three cross-cutting concerns

Woven through *every* phase from the start, each certified at the gate named above:

- **Usability (DESIGN, atelier)** — present from IDEATE (you shape the experience as you define the concept);
  atelier also reviews surfaces produced during BUILD. Certified at the **DESIGN** gate (design-fitness rubric).
- **Quality (ASSURE, foundry)** — *first-class, built-in not inspected-in.* The test-first conveyor means
  quality is engineered from the first line of BUILD (indeed from the EARS spec); the **ASSURE** gate is where
  foundry's adversarial reviewer panel *certifies* it. Quality is a pillar of the whole suite, not a late check.
- **Security (SECURE, security)** — *baked in from the beginning.* Secure-by-design starts at DISCOVER
  (don't pursue opportunities you can't operate safely) and IDEATE (threat-model the concept); the **SECURE**
  gate is security's pre-exposure certification. Security is never bolted on at the end.

## Binding the domain — five lenses on one arc

idea-to-production deliberately speaks five vocabularies at once, because a product is all of them:

- **product / engineering** — PLM conceive→design→realize→**operate**; the conveyor, its gates, and the
  living-product loop (BUILD, ASSURE, OPERATE).
- **manufacture** — "realize / make"; the test-first conveyor is the production line (BUILD).
- **artistic expression** — conception → study → composition → critique → exhibition; the designer↔reviewer
  loop and the publishing craft (DESIGN, PUBLISH).
- **commerce** — opportunity → willingness-to-pay → go-to-market → growth; the front end, launch, and operate
  (DISCOVER, PUBLISH, OPERATE).
- **quality & safety** — built-in not inspected-in; PDCA/DMAIC; the adversarial quality gate and the security
  gate as two distinct first-class concerns (ASSURE, SECURE, and the quality pillar throughout).

## Entry / exit signals

A phase is *entered* when its predecessor's exit signal fires, and *exited* when its artifact exists. The three
loop phases (BUILD, ASSURE, SECURE) are a special case — their **transitions are loop edges**, marked below:

- DISCOVER → IDEATE: a **kept OPPORTUNITY** (market-scan verdict, upheld by the independent challenger).
- IDEATE → DELIVER: a **handoff-contract-complete IDEA package** (foundry discovery exit criteria; READY from the
  independent challenger).
- DELIVER → DESIGN: a **decomposed, dependency-ordered set of build-ready items** (EARS-specified, topologically
  ordered roadmap from flow + `foundry:roadmapper`).
- DESIGN → BUILD: design-reviewed surfaces clear the **design-fitness rubric** (when UI is in scope) — *enters the
  loop at BUILD*.
- BUILD → ASSURE *(loop)*: the conveyor reaches **SHIP** (implementation in, tests green, story proven).
- ASSURE → SECURE *(loop)*: foundry's adversarial **quality review PASSES** (`/pr-review` / reviewer panel).
- ASSURE / SECURE **fail** → **BUILD** *(loop back-edge)*: a failed quality or security gate re-enters BUILD and
  records the iteration — it does **not** advance.
- SECURE → PUBLISH *(loop exit)*: fires **only when all three are satisfied** — BUILD at SHIP, ASSURE PASS, and
  security's **scan-all PASSES**. This is the single edge out of the loop.
- PUBLISH → OPERATE: the release artefacts are out; the idea is **realised & live**.
- OPERATE → DISCOVER (↻): an operate learning (a metric, an incident, a feedback signal) becomes a **new
  opportunity** — the next cycle begins.

## How the marketplace aligns to this spine

- The **state file** `.i2p/lifecycle.json` records `current_phase`, and — additively — `loop_state` (the live
  BUILD/ASSURE/SECURE position) and `loop_pass` (the loop iteration count). Each owning plugin **advances it at
  its own exit signal** by calling `/i2p:lifecycle done <its-phase>` (by capability — only when i2p is installed).
  `done` is **order-safe & idempotent**: it advances *only if* the lifecycle is at that phase, so a plugin can
  never jump it out of order or auto-start it. The loop's **back-edge** is a distinct verb,
  `/i2p:lifecycle fail <ASSURE|SECURE>`, which re-enters BUILD and records the iteration. Helper:
  `skills/lifecycle/scripts/lifecycle.sh` (`init|get|status|done|fail|set|advance`).
- The **statusline** phase widget (shipped by i2p) reads it and shows the current phase out of the nine, with the
  BUILD ⇄ ASSURE ⇄ SECURE loop reflected when the lifecycle is in it.
- **Token cost is tracked per phase** with a self-calibrating estimator — see
  [`instrumentation.md`](instrumentation.md). `/i2p:lifecycle init` seeds estimates; each phase's
  actual-vs-estimate is measured (i2p Stop hook) and folded back so estimates improve over time.
  The HUD shows `◇ session` spend and `◈ life actual/~estimate (Δ%) · $`.
- **`/i2p:help`** explains this lifecycle and offers to **kick one off**; **`/i2p:lifecycle`** initialises
  and reports it.
- This doc is referenced by `foundry/VALUE_FLOW.md` and the glossary so the whole suite shares one spine.

> **Graceful degradation.** An owner plugin may be absent (e.g. `operate` for OPERATE). The lifecycle
> still advances by hand (`done`/`advance`), and surfaces say what installing the owner would unlock — a gap is
> named, never silently skipped.

> Self-improvement covenant: if a phase, owner, concern, or lineage here drifts from how the plugins actually
> behave, fix it **here once** — every surface that renders the lifecycle inherits the correction.
