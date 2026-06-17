# Glossary & Conceptual Map — the idea-to-production marketplace

The single place that names every concept, plugin, agent, skill, command, and metaphor in the
marketplace and says what each one denotes. Read [`../VALUE_FLOW.md`](../VALUE_FLOW.md) to
understand the *system*; read here to disambiguate a *name*.

> **Naming convention:** **UPPERCASE** = a station, concept, or certified gate (IDEA, EARS, TEST,
> STORY, DEPLOY, VERIFY, GOVERNANCE). **lowercase** = an installable artefact — a plugin, skill,
> agent, or command (`foundry`, `founder`, `handler-rust`, `/publish`).

---

## 1. The conceptual-domain tree

![Conceptual-domain map of the idea-to-production marketplace, grouped by role: UPSTREAM — market-scanner (DISCOVERY front door) → ideator (REFINEMENT, the IDEA package); CORE — foundry (the value-flow conveyor) holding its substructure: THE CONVEYOR (IDEA▶ROADMAP▶…▶DEPLOY▶VERIFY), THE ORCHESTRATION HIERARCHY (founder▶builder-lead▶lifecycle-orchestrator▶ds-step-*/handler-*▶reviewer), THE VALUE-HANDLERS (handler-architect/python/…/rust-webapp), THE PILLARS (knowledge-parity · quality-first+perf-delta · waste-elimination — muda·mura·muri), THE KNOWLEDGE CORPUS (pillars/architecture/specs/testing/protocols/orchestration/policy), DESIGN station 6b (the frontend design system), and GOVERNANCE (code-quality, reviewer-gate, reviewer, inspector); COMPANIONS (cross-cutting, composing into the whole of foundry by capability) — security (SECURE), pressroom (PUBLISH), atelier (DESIGN/usability), operate (OPERATE).](diagrams/01-domain-tree.png)

The companions are **cross-cutting**: foundry/ideator use them *by capability* when installed
(graceful enhancement) and degrade to markdown when they are not. See `../VALUE_FLOW.md §4`. The full arc
is the eight-phase product-lifecycle **cycle**: **DISCOVER (market-scanner) → IDEATE (ideator) →
DESIGN (atelier) → BUILD (foundry) → ASSURE (foundry, quality) → SECURE (security) →
PUBLISH (pressroom) → OPERATE (operate) ↻** (OPERATE loops back to DISCOVER). Three concerns
cross-cut every phase — usability (atelier), quality (foundry), security (the security plugin).

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
- **idea-to-production** — the marketplace; the repository and the `marketplace.json` `name`. Its
  organising spine is the **product lifecycle** (below).
- **product lifecycle** — the *creation arc* the suite is organised around: **eight phases forming a
  cycle** — **DISCOVER → IDEATE → DESIGN → BUILD → ASSURE → SECURE → PUBLISH → OPERATE ↻** (OPERATE loops
  back to DISCOVER), each owned by one plugin. **ASSURE** (quality V&V, foundry) and **SECURE** (security,
  the security plugin) are separate first-class gates; three concerns cross-cut every phase — usability (atelier),
  quality (foundry), security (the security plugin). The canonical model (owners, academic lineage, entry/exit
  signals) is `i2p/knowledge/product-lifecycle.md`; tracked per-project in `.i2p/lifecycle.json` and shown
  on the concierge status line. Distinct from the *marketing* product life cycle
  (introduction→growth→maturity→decline), which runs alongside OPERATE.
- **ASSURE** (lifecycle phase ⑤; gate, owner foundry) — the **quality** certification gate: adversarial
  V&V (tests green, coverage density, perf-delta, regression, architecture). Distinct from SECURE — a
  product can be high-quality and insecure. *(Built-in not inspected-in: quality is engineered from the
  first line of BUILD; ASSURE certifies it.)*
- **SECURE** (lifecycle phase ⑥; gate, owner security) — the **security** certification gate: PII,
  secrets, supply-chain clear before exposure. Distinct from ASSURE (quality). *(Baked in from the
  beginning — secure-by-design from DISCOVER; SECURE is the pre-exposure certification.)*
- **OPERATE** (lifecycle phase ⑧; owner `operate`) — the living phase: observe, respond to
  incidents, iterate, and maintain the realised & live product; its learnings open the **next** cycle
  (↻ → DISCOVER). `operate` may not be installed yet — surfaces name what installing it unlocks.
- **i2p** — the marketplace **front door / meta-layer**: marketplace-level meta-commands (`/i2p-help`,
  `/i2p-review`, `/i2p-check`, `/i2p-flow`) plus session-start onboarding. A thin orchestrator that
  composes the seven specialists by capability and never re-implements them.
- **first-order instrumentation** — the HUD's always-on instruments, fed by deterministic hooks: the
  **⚔ adversarial-catch counter** (times a reviewer caught something) and the **token-cost tracker**
  (per-phase actual vs a self-calibrating estimate, tokens + $). Canonical:
  `i2p/knowledge/instrumentation.md`; state under `~/.claude/state/` and `<project>/.i2p/cost.json`.
- **concierge** — the **arrival / greeter**: a SessionStart hook renders a repo's
  `.claude/welcome.md` to greet and route whoever opens it; `/concierge:define-welcome` authors that
  welcome; also offers the idea-to-production status line on first activation.
- **market-scanner / ideator / foundry / security / pressroom / atelier / operate** — the seven
  specialist plugins: DISCOVERY (find a worth-building opportunity) / REFINEMENT (the IDEA package) / the
  core conveyor (BUILD + the ASSURE quality gate) / SECURITY companion (the SECURE gate) / PUBLISHING
  companion / DESIGN companion (make + adversarially review the visuals) / OPERATE companion (run the live
  product — observe, respond, iterate, maintain — and loop learnings back to DISCOVER).

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
  security, pressroom, atelier, operate).

### Skills (companion plugins)
- market-scanner: **goal-setter** · **market-scan** · **self-improve** · **check**.
- ideator: **ideate** (the IDEA package) · **self-improve** · **check**.
- security: **scan-for-pii** · **scan-for-secrets** · **scan-dependencies** · **scan-all** · **check**.
- pressroom: **writer** · **diagram-studio** · **mermaid-specialist** (full Mermaid taxonomy + theming + ELK) ·
  **rich-pdf-with-diagrams** · **design-reviewer** (print/DTP + data-viz adversarial review; agents
  **typographic-reviewer**, **dataviz-reviewer**, **image-aesthetic-reviewer**, **layout-reviewer** — the
  at-a-glance legibility gate run before taste) · **check**. Agent **handler-composite** genuinely **owns
  animated-diagram craft** at BOTH altitudes: the frame-level **Motion canon** — the house linger/timing policy,
  now codified in [`raster-toolchain.md`](../../pressroom/knowledge/raster-toolchain.md) (no longer trapped as
  script comments) — and the element-level **diagramming/animation language** (below).
- **motion-language.md** — the element-level diagramming/animation language: a named-element registry
  (**NODE · TOKEN · GATE · RAIL · ARC · SWEEP · STAMP · HALO**) + each element's **motion verbs** (token *rides*,
  gate *latches*/*flips*, sweep *rotate-surfaces*, arc *glows-on*, node *arrives*/*breathes*/*dissolves*, stamp
  *resolves*, halo *attention-pulses*) — the sibling of the frame-level Motion canon (it answers "what KIND of
  thing is this and how does a thing of THIS kind move?", where the Motion canon answers "how long does this FRAME
  hold?"). Owned by **handler-composite**. → study-repo
  [`docs/internal/image-craft-study/craft/motion-language.md`](../../../docs/internal/image-craft-study/craft/motion-language.md).
- **diagram-primitives.sh** — the shared **crafted-primitive library** (`prim_node`/`prim_token`/`prim_gate`/
  `prim_rail`/`prim_arc`/`prim_sweep`/`prim_stamp`/`prim_halo` + the shared `prim_defs`/palette/geometry). The
  single home for in-vector line-art craft: generators **source** it instead of re-hand-rolling SVG and copying
  `<defs>`, so the craft uplift (shading, rim light, soft shadow — pure SVG, no raster) lands ONCE and every
  generator inherits it. Names match motion-language.md's registry. → study-repo
  [`docs/internal/image-craft-study/toolchain/src/diagram-primitives.sh`](../../../docs/internal/image-craft-study/toolchain/src/diagram-primitives.sh).
- **Cost-tier doctrine** ≡ **cheap-checks-first** ≡ **vision-on-suspicion** — shared reviewer canon for every
  graphical review: the free deterministic checks (the layout machine) run first, and an expensive pixel/vision
  Read is spent **only when something cheap has flagged a suspect**, never by default. Specified for layout in
  [`layout-canon.md`](../../pressroom/skills/design-reviewer/references/layout-canon.md) §3; governs all lenses
  via the critique-loop canon.
- atelier: **ui-review** (crawl + critique any SPA) · **mockup** (design + converge) · **self-improve** ·
  **check**; agent **ui-design-reviewer** (adds a **LAYOUT-REVIEWER** lens — the legibility gate run before
  taste, composing PRESSROOM's layout canon by capability).

### Commands
- foundry: **/foundry** · **/inspect** · **/coverage-loop** · **/phase-sensor** · **/rust-webapp-rollout** ·
  **/foundry:pr-review** · **/foundry:self-improve** · **/foundry:check** · **/foundry:prerequisites**
- market-scanner: **/market-scan** · **/discovery-goal** · **/market-scanner:check**
- ideator: **/ideate** · **/ideator:check**
- security: **/scan-all** · **/scan-for-pii** · **/scan-for-secrets** · **/scan-dependencies** · **/security:check**
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
- **Graceful enhancement** — foundry uses security/pressroom *by capability if installed*, else
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
  **SECURITY-REPORT.md** (security verdict) · sentinels (machine-readable phase state).

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
- **Waste-elimination** ≡ **muda · mura · muri** — remove waste in every form, *including
  rediscovery*; the three Ms are *muda* (waste), *mura* (unevenness), *muri* (overburden).
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
- **The KAIZEN covenant** ≡ **halve-the-distance** ≡ **self-cleaving** ≡ *kaizen* — continuous
  improvement applied to *agent documents* (PDCA · standardize-then-improve · small steps · gemba ·
  eliminate muda/mura/muri); each pass at least halves the distance to perfection; an over-broad
  element cleaves into smaller single-purpose ones. → [`architecture/kaizen-covenant.md`](architecture/kaizen-covenant.md).
- **Reasoning travels with the rule** — certainty markers (`THE ONLY WAY`/`GUARDRAIL`/`ANTI-PATTERN`/
  `WORKED EXAMPLE`) + the guardrails ledger (symptom→cause→fix; pay-the-cost-once). The worker tier's
  memory. → [`protocols/certainty-markers.md`](protocols/certainty-markers.md),
  [`protocols/guardrails-ledger.md`](protocols/guardrails-ledger.md).
- **The self-improving marketplace** ≡ **fix-upstream-once** ≡ **self-cleave-and-PR** — learn from a
  mistake → fold the fix back at the source → ship to all users via PR. → [`first-principles.md`](first-principles.md) §6.
  Its graphics arm is now the **general graphics+animation review→rule→canon loop** (no longer diagram-only):
  every generalisable finding — *especially* an expensive vision finding — folds into the *right* canon
  (layout → [`layout-canon.md`](../../pressroom/skills/design-reviewer/references/layout-canon.md); animation →
  the **Motion canon** in [`raster-toolchain.md`](../../pressroom/knowledge/raster-toolchain.md); composition →
  `charting-matrix.md`), so the bar rises once and never recurs →
  [`../../pressroom/skills/rich-pdf-with-diagrams/references/self-improvement.md`](../../pressroom/skills/rich-pdf-with-diagrams/references/self-improvement.md).
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
