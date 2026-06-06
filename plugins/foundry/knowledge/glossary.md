# Glossary & Conceptual Map — the idea-to-production marketplace

The single place that names every concept, plugin, agent, skill, command, and metaphor in the
marketplace and says what each one denotes. Read [`../VALUE_FLOW.md`](../VALUE_FLOW.md) to
understand the *system*; read here to disambiguate a *name*.

> **Naming convention:** **UPPERCASE** = a station, concept, or certified gate (IDEA, EARS, TEST,
> STORY, DEPLOY, VERIFY, GOVERNANCE). **lowercase** = an installable artefact — a plugin, skill,
> agent, or command (`foundry`, `founder`, `handler-rust`, `/publish`).

---

## 1. The conceptual-domain tree

```
idea-to-production  (the MARKETPLACE — carries software from IDEA to PRODUCTION)
│
├── market-scanner (PLUGIN · DISCOVERY front door) — goal-setter · market-scan · /goal · /market-scan
├── ideator   (PLUGIN · REFINEMENT) — ideate (the IDEA package: agent-facing + user-facing) · /ideate
│
├── foundry  (PLUGIN · the value-flow production system — the core conveyor)
│   ├── THE CONVEYOR — value-stations, in order
│   │   IDEA ▶ ROADMAP ▶ PLAN ▶ EARS ▶ FEATURE ▶ TEST ▶ IMPLEMENT (+DESIGN 6b) ▶ STORY ▶
│   │   DELIVERY ▶ DEPLOY ▶ VERIFY        (each with an entry, a transformation, an exit certificate)
│   ├── THE ORCHESTRATION HIERARCHY (three altitudes, one chain of command)
│   │   founder (COO) ▶ builder-lead (cycle planner) ▶ lifecycle-orchestrator (per-item) ▶
│   │   ds-step-* (station workers) + handler-* (value-handlers) ▶ reviewer (gate panel)
│   ├── THE VALUE-HANDLERS (staff the stations, by stack)
│   │   handler-{architect, python, fastapi, js, vanilla-js, react, css, playwright, rust, rust-webapp}
│   ├── THE PILLARS (govern everything)
│   │   knowledge-parity · quality-first (+ perf-delta gate) · waste-elimination
│   │   (+ facets: implementation-covenant, determinism-and-pinning, solid-covenant)
│   ├── THE KNOWLEDGE CORPUS (define-once canon — knowledge/)
│   │   pillars/ · architecture/ · specs/ · testing/ · protocols/ · orchestration/ · policy/
│   ├── DESIGN (station 6b) — the `frontend` design system (vanilla-JS)
│   └── GOVERNANCE (cross-cutting, in-plugin) — code-quality, reviewer-gate, reviewer, inspector
│
├── sentinel   (PLUGIN · SECURITY companion) — pii-audit · secret-scan · dependency-audit · /security-gate
├── pressroom  (PLUGIN · PUBLISHING companion) — writer · diagram-studio · mermaid-specialist · rich-pdf-with-diagrams · design-reviewer · /publish
└── atelier    (PLUGIN · DESIGN companion) — ui-review · mockup · ui-design-reviewer · /ui-review · /mockup
```

The companions are **cross-cutting**: foundry/ideator use them *by capability* when installed
(graceful enhancement) and degrade to markdown when they are not. See `../VALUE_FLOW.md §4`. The full arc
is **DISCOVER (market-scanner) → IDEATE (ideator) → BUILD (foundry) → SECURE/PUBLISH (sentinel/pressroom)**,
with **DESIGN (atelier)** cross-cutting — making and adversarially reviewing the visuals throughout.

---

## 2. foundry vs forge vs founder — read this once

These look alike and are constantly confused. They are different things:

| Name | What it is | Status |
|---|---|---|
| **`foundry`** | The core **plugin** — the value-flow production system (the conveyor). | A plugin in this marketplace. |
| **FOUNDRY** | The same system, written as a proper noun in prose. | = the `foundry` plugin. |
| **`founder`** | The **COO orchestrator agent** ([`../agents/founder.md`](../agents/founder.md)) — turns an idea into a value-stationed path and staffs the line. A *founder* operates the *foundry*. | An agent inside foundry. |
| **`founder-method`** | The **skill** holding the station model, discovery protocol, and test contract that `founder` follows. | A skill inside foundry. |
| **`builder` / `builder-lead`** | The orchestration **skill** (`builder`) and the **cycle-planner agent** (`builder-lead`) one altitude below `founder`. | Skill + agent inside foundry. |
| **FORGE** | The historical origin environment where these plugins were first built — **not part of this marketplace** and not referenced by any runtime surface. Its story is archived in [`../docs/HISTORY.md`](../docs/HISTORY.md). | External / historical. |
| **`forge`** (lowercase, in the rust references) | The shipped **worked-example project** (a Rust/WASM + Vercel app) used to illustrate `rust-webapp-rollout`. | A sample project name, not a system. |
| **`atelier`** | The **DESIGN plugin** — makes (`/mockup`) and adversarially reviews (`/ui-review`) the *rendered* visuals of any app, to a SOTA-grounded canon. | A plugin in this marketplace. |
| **`frontend`** (vs `atelier`) | A **skill inside foundry** — the *source-level* design system (the `@front-end` INTENT markers, `definition-of-good`, the build-time `design-critic`). `atelier` reviews the *rendered experience* and carries the deeper canon; it **composes with** `frontend` by capability, never duplicates it. | A skill inside foundry. |

**Rule of thumb:** if a document inside a plugin says "the FORGE" as if it were *this* system, that
is a bug — it should say **FOUNDRY** (the plugin) or name the specific companion. The `inspector`
audits for exactly this (`../agents/inspector.md`). And don't confuse **`atelier`** (the design *plugin*,
rendered-experience review) with foundry's **`frontend`** *skill* (source-level design system).

---

## 3. Flat glossary

### Marketplace & plugins
- **idea-to-production** — the marketplace; the repository and the `marketplace.json` `name`.
- **i2p** — the concierge / front door: marketplace-level meta-commands (`/i2p-help`, `/i2p-review`,
  `/i2p-check`, `/i2p-flow`) plus session-start onboarding. A thin orchestrator that composes the six
  specialists by capability and never re-implements them.
- **market-scanner / ideator / foundry / sentinel / pressroom / atelier** — the six specialist plugins:
  DISCOVERY (find a worth-building opportunity) / REFINEMENT (the IDEA package) / the core conveyor /
  SECURITY companion / PUBLISHING companion / DESIGN companion (make + adversarially review the visuals).

### Orchestration agents (foundry)
- **founder** — COO/portfolio orchestrator. - **builder-lead** — cycle planner (emits `FOUNDRY_PLAN.md`).
- **lifecycle-orchestrator** — per-item runner (drives steps 0–9 + story).
- **ds-step-{0-plan,1-ears,2-feature-docs,3-tests,4-first-test-run,5-implementation,6-green-run,7-sync,8-commit-message,9-commit-push,story-tests}** — the station workers.

### Value-handlers (foundry · staff stations by stack)
- **handler-architect** (pattern + ADR) · **handler-python** · **handler-fastapi** · **handler-js**
  · **handler-vanilla-js** (native handler of the `frontend` DESIGN system) · **handler-react**
  · **handler-css** · **handler-playwright** (story/E2E) · **handler-rust** · **handler-rust-webapp**
  (the RUST_WEBAPP_API one-shot, governed by `rust-webapp-rollout`).

### Governance agents (foundry)
- **reviewer** — adversarial gate panel, role-parametrised (EARS/SMU/BDD/COVERAGE/TEST-DESIGN/
  DESIGN/SECURITY/REGRESSION/PERFORMANCE/ARCHITECTURE/DOCUMENT). - **inspector** — audits the FOUNDRY
  plugin itself. - **coverage-loop-agent** — pins unpinned behaviour (coverage = floor, density =
  variable). - **flaky-test-fixer** — eliminates flaky tests.

### Skills (foundry)
- **builder** (orchestrator) · **founder-method** · **vertical-slice** · **value-station-handoff** ·
  **development-system-core** · **lifecycle-states** · **ideator** (IDEA) · **roadmapper** (ROADMAP) ·
  **frontend** (DESIGN) · **code-quality** · **reviewer-gate** · **handoff-protocol** ·
  **phase-sensor** (infra; PostToolUse hook) · **rust-webapp-rollout** (Rust/WASM/Vercel one-shot) ·
  **pr-review** (adversarial PR/diff review → one verdict) · **self-improve** (targeted self-cleaving →
  PR) · **prerequisites** (emit PREREQUISITES.md) ·
  **check** (verify tool dependencies). The companions add **check** too (market-scanner, ideator,
  sentinel, pressroom, atelier).

### Skills (companion plugins)
- market-scanner: **goal-setter** · **market-scan** · **self-improve** · **check**.
- ideator: **ideate** (the IDEA package) · **self-improve** · **check**.
- sentinel: **pii-audit** · **secret-scan** · **dependency-audit** · **security-gate** · **check**.
- pressroom: **writer** · **diagram-studio** · **mermaid-specialist** (full Mermaid taxonomy + theming + ELK) ·
  **rich-pdf-with-diagrams** · **design-reviewer** (print/DTP + data-viz adversarial review) · **check**.
- atelier: **ui-review** (crawl + critique any SPA) · **mockup** (design + converge) · **self-improve** ·
  **check**; agent **ui-design-reviewer**.

### Commands
- foundry: **/foundry** · **/inspect** · **/coverage-loop** · **/phase-sensor** · **/rust-webapp-rollout** ·
  **/foundry:pr-review** · **/foundry:self-improve** · **/foundry:check** · **/foundry:prerequisites**
- market-scanner: **/market-scan** · **/goal** · **/market-scanner:check**
- ideator: **/ideate** · **/ideator:check**
- sentinel: **/security-gate** · **/pii-audit** · **/secret-scan** · **/dependency-audit** · **/sentinel:check**
- pressroom: **/publish** · **/pressroom:check**
- atelier: **/ui-review** · **/mockup** · **/atelier:check**

### Core concepts
- **Value-station** — a stage on the conveyor with an entry, a transformation, and a mandatory
  **exit certificate**. - **Value-handler** — the agent that staffs a station's work in a stack.
- **Coordinate** — a failing unit test: an `input → expected output` assertion against a *pure*
  function that pins the solution in logical space. - **Coverage density** — the real testing
  variable: happy/unhappy/abuse paths per behaviour (100% coverage is the *floor* that results).
- **Vertical slice** — one thin, end-to-end, reviewable increment crossing every station.
- **The gate** — the certifying station; never weakened to go green. - **Pure core / one-way
  dependency** — the geometry that makes coordinates and parallelism possible
  ([`architecture/pure-core.md`](architecture/pure-core.md)).
- **Certainty markers** — `THE ONLY WAY` / `GUARDRAIL` / `ANTI-PATTERN` / `WORKED EXAMPLE`
  ([`protocols/certainty-markers.md`](protocols/certainty-markers.md)).
- **Graceful enhancement** — foundry uses sentinel/pressroom *by capability if installed*, else
  degrades to markdown.
- **Adversarial PR review** — `/foundry:pr-review` fans the `reviewer` agent across adversarial
  roles (each tries to *refute* the change) → one verdict `PASS | NEEDS_REVISION | BLOCK`
  ([`../skills/pr-review/SKILL.md`](../skills/pr-review/SKILL.md)).
- **Merge governance** — who merges a *passing* change: **`pr-approval`** (push branch, open PR,
  human merges) or **`direct-merge`** (agent merges on PASS). The adversarial review is always-on in
  both; only the merge hand differs. Stored in `.foundry/governance.md`; default `pr-approval`
  ([`protocols/merge-governance.md`](protocols/merge-governance.md)).
- **AWAITING MERGE** — a roadmap status / `AWAITING_MERGE` sentinel: under `pr-approval` the item is
  built and review-PASSed with its PR open, but not yet on `main` — terminal-pending, flips to
  `COMPLETE` on the human merge.
- **Live feedback (Playwright MCP)** — the `mcp__playwright__*` tools for exploratory browser
  feedback during dev; complements, never replaces, the committed test contract
  ([`tooling/live-feedback.md`](tooling/live-feedback.md)).

### Artefacts
- **FOUNDRY_PLAN.md** (cycle plan) · **IDEA_COST.jsonl** (cost ledger) · **SUBJECT_MATTER_UNDERSTANDING.md**
  (SMU) · **FOUNDRY_INSPECTION_REPORT.md** (inspector output, written to the project) ·
  **SECURITY-REPORT.md** (sentinel verdict) · sentinels (machine-readable phase state).

---

## Core language — the meta-principles (multiple bindings)

The marketplace's governing ideas, each with **multiple bindings** so you recognise the principle
however it surfaces — *formal* definition · *aliases* · *metaphor*. The depth lives in
[`first-principles.md`](first-principles.md) (the philosophical spine); this is the browse index.

> **Bindings convention:** a meta-principle carries ≥2 names by design — a principle you can name only
> one way is one you will miss when it wears a different coat. (Precedent: the certainty markers bind
> one truth four ways.)

- **The conveyor** — *the driving force.* Formal: a line that carries VALUE from IDEA to PRODUCTION.
  Aliases: value-flow; idea→production; the production facility. Metaphor: a factory line, not a filing
  cabinet. → [`first-principles.md`](first-principles.md) §0, [`../VALUE_FLOW.md`](../VALUE_FLOW.md).
- **Knowledge-parity** ≡ **knowledge-alignment** — understand the ask completely *before* acting.
  → [`pillars/knowledge-parity.md`](pillars/knowledge-parity.md).
- **Quality-first** ≡ **quality-confidence** — quality built in, not inspected in; gates never weakened.
  → [`pillars/quality-first.md`](pillars/quality-first.md).
- **Waste-elimination** — remove waste in every form, *including rediscovery*.
  → [`pillars/waste-elimination.md`](pillars/waste-elimination.md).
- **Token-efficiency** ≡ **progressive disclosure** — thin skills, fat references; define once,
  reference many; station-scoped loading. The overarching constraint. → [`token-efficiency.md`](token-efficiency.md).
- **Coordinate** ≡ **pin** ≡ **location** ≡ **proof-obligation** ≡ **the reason to write code** — a
  failing test that pins the exact code in logical space; code exists only to turn it PASS. → §Coordinates,
  [`testing/test-policy.md`](testing/test-policy.md).
- **SOLUTION** (double binding) — *both* (a) the **problem solved** *and* (b) the **solvent-matrix** in
  which component additives (coordinates) dissolve until the mixture *is* the answer. Code is a solution
  in both senses. → [`first-principles.md`](first-principles.md) §2.
- **Pure core** ≡ **decidable core** ≡ **the sacred core** ≡ **one-way dependency** — the geometry that
  makes coordinates (and parallelism) possible. → [`architecture/pure-core.md`](architecture/pure-core.md).
- **The SOLID covenant** ≡ **halve-the-distance** ≡ **self-cleaving** — SOLID applied to *agent
  documents*; each pass at least halves the distance to perfection; an over-broad element cleaves into
  smaller SOLID-adherent ones. → [`architecture/solid-covenant.md`](architecture/solid-covenant.md).
- **Reasoning travels with the rule** — certainty markers (`THE ONLY WAY`/`GUARDRAIL`/`ANTI-PATTERN`/
  `WORKED EXAMPLE`) + the guardrails ledger (symptom→cause→fix; pay-the-cost-once). The worker tier's
  memory. → [`protocols/certainty-markers.md`](protocols/certainty-markers.md),
  [`protocols/guardrails-ledger.md`](protocols/guardrails-ledger.md).
- **The self-improving marketplace** ≡ **fix-upstream-once** ≡ **self-cleave-and-PR** — learn from a
  mistake → fold the fix back at the source → ship to all users via PR. → [`first-principles.md`](first-principles.md) §6.
- **The two altitudes** ≡ **workers & orchestrators** ≡ **makers & managers** — pragmatic workers
  (exact patterns + ledgers) and aligned orchestrators (shared philosophy + language).
  → [`first-principles.md`](first-principles.md) §7, [`architecture/self-architecture.md`](architecture/self-architecture.md).
- **The marketplace's own form** — a deliberate **hybrid**: pure-core/hexagonal `knowledge/` +
  ports-and-adapters plugin composition + a pipeline/hierarchical-orchestration agent conveyor (distinct
  from the *hexagonal* form it prescribes for software it builds).
  → [`architecture/self-architecture.md`](architecture/self-architecture.md).

---

## 4. Where to look next
- The system, end-to-end → [`../VALUE_FLOW.md`](../VALUE_FLOW.md)
- A canonical fact → [`README.md`](README.md) (the "which doc answers which question" index)
- Who staffs what → [`orchestration/agent-roster.md`](orchestration/agent-roster.md) +
  the `builder` VALUE_HANDLER_POOL.
- Worked examples of the dev system → [`../examples/README.md`](../examples/README.md)
- How the system came to be → [`../docs/HISTORY.md`](../docs/HISTORY.md)
