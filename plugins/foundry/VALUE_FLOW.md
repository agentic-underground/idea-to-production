# FOUNDRY — The Value-Flow System

> **This is the spine.** Every station, handler, and agent in the FOUNDRY plugin links
> back to a section here. If a change to FOUNDRY cannot be reconciled with this document,
> the change is wrong or this document is out of date — resolve that before proceeding.
> FOUNDRY is a **production facility**: it does not store configuration, it carries value.

> **Marketplace spine.** FOUNDRY owns the **BUILD** phase *and* the **ASSURE** quality gate of the
> marketplace-wide **product lifecycle** — eight phases forming a cycle: DISCOVER → IDEATE → DESIGN →
> **BUILD** → **ASSURE** → SECURE → PUBLISH → OPERATE ↻ (OPERATE loops back to DISCOVER). ASSURE (quality
> V&V, foundry) and SECURE (security, the security plugin) are separate first-class gates. The canonical lifecycle
> model is [`../i2p/knowledge/product-lifecycle.md`](../i2p/knowledge/product-lifecycle.md).

FOUNDRY is one cohesive capability: a **conveyor that carries VALUE from IDEA to
PRODUCTION**, staffed by role-tuned agents, governed by three pillars and one overarching
constraint. It is greater than the sum of its parts — the user interacts with the IDEA
layer to reach the clearest picture of the shippable value, and every value-station can,
if it must, ask a question back up the line until the answer is found.

> This document is the **operational** spine (*how* value moves). The **philosophical** spine (*why*
> the system is shaped this way — the pillars, tests-as-coordinates, the KAIZEN covenant, the two
> altitudes, the self-improving loop, each with its bindings) is
> [`knowledge/first-principles.md`](knowledge/first-principles.md). The marketplace's **own**
> architecture (a deliberate hybrid, distinct from the hexagonal form it builds *with*) is
> [`knowledge/architecture/self-architecture.md`](knowledge/architecture/self-architecture.md).

---

## 1 · The conveyor (the picture)

![The FOUNDRY conveyor, three layers: THE IDEA above the line (the user ⇄ IDEATOR / PRODUCT_MANAGER, knowledge-parity before build) feeds a clear agent-readable brief DOWN into THE CONVEYOR, whose nine value-stations carry value left→right — IDEA (ideator) ▶ ROADMAP (roadmapper) ▶ PLAN ▶ EARS (spec) ▶ FEATURE ▶ TEST (tests) ▶ IMPLEMENT +DESIGN (builder/handlers) ▶ STORY ▶ SHIP (deliver) — with cross-cutting GOVERNANCE (reviewers · perf-delta gates · inspector, in foundry) and companions when installed (PUBLISHING → pressroom · SECURITY → security · DESIGN → atelier) riding the whole carriage; questions flow UP, value flows DOWN.](diagrams/02-conveyor.png)

Three layers:
- **THE IDEA (above):** what we are building, and why. Owned by the PRODUCT_MANAGER.
- **THE CONVEYOR (below):** the disciplines that govern the whole carriage of value.
- **THE STATIONS (along it):** each a stage with its own processes, owning handler, and
  exit gate.

---

## 2 · THE IDEA — knowledge parity before production

The **IDEATOR** is the **PRODUCT_MANAGER**. Before production begins, the IDEATOR must reach
**full parity of understanding with the user** about the shippable value piece. The IDEATOR
asks clarifying questions — one at a time, conversationally — until the brief is
unambiguous, actionable, and self-contained (a fresh agent with no history can act on it).

**Upstream front end (graceful enhancement).** When the **`ideator` plugin** is installed, parity is
reached *upstream*: `market-scanner` discovers a worth-building opportunity and the `ideator` plugin
refines it into an **IDEA package** (agent-facing brief + SMU-seed + first slice + handoff contract)
already challenged to knowledge-parity. FOUNDRY's IDEA station then **receives that package by
capability** and verifies the discovery exit criteria — it does *not* re-interrogate. When the plugin is
absent, the inline `ideator` skill runs the dialogue itself (the fallback). Either way the station's exit
gate is identical: a stable, parity-reached brief. Detection is by capability, never by cross-plugin path.

**Questions flow up.** Any value-station that hits an ambiguity it cannot resolve from its
inputs asks the PRODUCT_MANAGER. If the PRODUCT_MANAGER cannot answer satisfactorily, **the
user is consulted.** Production never improvises around a knowledge gap; it surfaces it.

Once parity is reached and the spec is authorized, the spec is **frozen** — implementation
conforms to it, not the other way around. A genuine spec gap found downstream is surfaced
back up the line (DISCUSS mode), never patched in place. See
`knowledge/pillars/knowledge-parity.md`.

---

## 3 · THE CONVEYOR — the disciplines that govern everything

Every station inherits these. They are not optional and they are not re-stated per station;
they are referenced from `knowledge/` so they are defined **once** and obeyed **everywhere**.

- **The three pillars** (§5) — knowledge parity, quality-first, waste elimination.
- **Token efficiency** (§6) — pass only the required context to each subagent.
- **The implementation covenant** — `knowledge/pillars/implementation-covenant.md`: think
  before coding, simplicity first, surgical changes, tests are the contract, spirit not just
  letter.
- **The KAIZEN self-improvement covenant** — `knowledge/architecture/kaizen-covenant.md`:
  every artefact is designed to improve itself; recurring gaps signal an upstream fix.

---

## 4 · VALUE STATIONS — the line

Each station has an **input contract** (what must arrive), an **owning skill/handler**, an
**exit gate** (what must be true to leave), and an **artifact** (what it produces next).
A station with no handler is a defect FOUNDER reports. A gate without a check is forbidden.

| # | Station | Value it adds | Owning skill | Staffed by | Exit gate |
|---|---------|---------------|--------------|------------|-----------|
| 0 | **IDEA** | a candidate worth pursuing, understood | `ideator` (receives the `ideator` plugin's IDEA package by capability when installed; inline dialogue is the fallback) | founder | brief stable; parity reached |
| 1 | **ROADMAP** | agent-readable backlog, tiered | `roadmapper`, `builder` | builder-lead | item self-contained; tiered to budget |
| 2 | **PLAN** | per-item plan + resumption | `development-system-core` | ds-step-0-plan | PLAN_COMPLETE; DoD drafted |
| 3 | **EARS** | unambiguous requirements | `lifecycle-states` | ds-step-1-ears | EARS-IDs; EARS/SMU reviewers PASS |
| 4 | **FEATURE** | behaviour as Gherkin | `lifecycle-states` | ds-step-2-feature-docs | ≥3 scenarios/EARS (happy/unhappy/abuse); BDD-REVIEWER PASS |
| 5 | **TEST** | failing tests = solution coordinates | `lifecycle-states` | ds-step-3-tests, ds-step-4-first-test-run | genuinely RED; gap map complete |
| 6 | **IMPLEMENT** | minimal code to green | `lifecycle-states`, `code-quality` | ds-step-5/6, handler-* | all gap-map tests green; 100% coverage floor |
| 6b| **DESIGN** *(cross-cuts IMPLEMENT)* | usable, accessible surfaces | `frontend` | handler-vanilla-js, handler-css | INTENT-marked; a11y + privacy held |
| 7 | **STORY** | proof through the real interface | `lifecycle-states` | ds-step-story-tests, handler-playwright | STORY_PROVEN; perf-delta gate passed |
| 8 | **DELIVERY** | shipped + traceable | `lifecycle-states` | ds-step-7/8/9 | synced; commit narrative; roadmap COMPLETE |
| 9 | **DEPLOY** *(where the product deploys)* | a live artefact | `lifecycle-states` (stack skill, e.g. `rust-webapp-rollout`) | stack handler | built + deployed; live URL/endpoint exists |
| 10| **VERIFY** *(where the product deploys)* | proof in production | `lifecycle-states`, stack skill | stack handler | the verification matrix passes against the **deployed** artefact (not localhost) |

> **GUARDRAIL:** A station's **exit certificate is mandatory** — freight may not advance without it.
> Do not BUILD/DEPLOY before the gate is green; do not call a slice done before VERIFY passes against
> the *deployed* artefact. Skipping a station is how silent breakage reaches production. (DEPLOY and
> VERIFY apply to any item that ships to a runtime; for pure libraries the line ends at DELIVERY.)

**Cross-cutting stations** are available to the whole line, not a single position. One is
built into foundry; three are **companion plugins** that foundry uses *if installed* and degrades
cleanly without (**graceful enhancement** — foundry's value artefact is markdown):

- **GOVERNANCE** *(in foundry)* — `code-quality`, `reviewer-gate`; staffed by `reviewer`
  (role-parametrised panel), `inspector` (self-improvement audit), `coverage-loop-agent`,
  `flaky-test-fixer`. A reviewer gate and, where relevant, a **performance-delta gate** sit at
  every transition.
- **PUBLISHING** *(companion: `pressroom` plugin)* — when installed, foundry hands off to its
  `writer`, `diagram-studio` / `mermaid-specialist`, `rich-pdf-with-diagrams`, and `design-reviewer`
  skills (via the `/publish` command) for narrative + print-quality artefacts, themed diagrams, and an
  adversarial print/data-viz design review. When absent, foundry delivers markdown and notes that
  rich publishing was skipped. Reference by capability/skill-name, never by `${CLAUDE_PLUGIN_ROOT}`
  path across the plugin boundary.
- **SECURITY** *(companion: `security` plugin)* — when installed, foundry's release path can run
  `/security:scan-all` (PII + secret + dependency audit → `SECURITY-REPORT.md`, verdict
  PASS/REVIEW/BLOCK) before DELIVERY. When absent, the gate is skipped with a noted recommendation
  to install `security`.
- **DESIGN** *(companion: `atelier` plugin)* — when installed, foundry's rendered UI surfaces can be
  put under `/ui-review` (crawl + adversarial, canon-grounded critique with an accessibility gate), and
  user-flows/mockups composed via `/mockup` in a convergent designer↔reviewer loop. It **composes with**
  foundry's source-level `frontend` design-system (the DESIGN station 6b) by capability — extending the
  rendered-experience review, never duplicating it. When absent, the `frontend` self-critique still runs.

The canonical per-station input/exit contracts live in
`knowledge/protocols/handoff-schema.md` (human-readable intent) and
`knowledge/protocols/context-sentinel.md` (machine-readable state). Handlers consult them;
they do not improvise gates.

---

## 5 · VALUE HANDLERS — who staffs the stations

A **value-handler** is the agent that owns a station's work. Handlers carry **only their
station's references** (token efficiency, §6). The house's handlers:

- **Stack handlers** — `handler-{python,js,react,fastapi,css,playwright,vanilla-js,rust,rust-webapp}`:
  author tests (TEST), implement (IMPLEMENT), and prove stories (STORY) in their stack. They carry
  the implementation covenant and the project's SUBJECT_MATTER_UNDERSTANDING, nothing more.
  `handler-vanilla-js` is the native handler of the `frontend` design system (DESIGN);
  `handler-react` staffs React-stack IMPLEMENT work, not the vanilla-JS design system.
  `handler-rust` staffs general Rust; `handler-rust-webapp` staffs the full Rust/WASM + Vercel
  one-shot rollout (governed by the `rust-webapp-rollout` skill).
- **`handler-architect`** — selects the architectural pattern when a non-trivial decision
  arises; writes the ADR; carries the KAIZEN covenant.
- **`reviewer`** — the adversarial gate-keeper, parametrised by role (EARS, SMU, BDD,
  COVERAGE, TEST-DESIGN, DESIGN, SECURITY, REGRESSION, PERFORMANCE, ARCHITECTURE, DOCUMENT).
- **`inspector`** — audits FOUNDRY itself; finds drift, gaps, and improvable patterns.

Handler model selection is governed centrally by `knowledge/policy/model-selection.md`
(haiku for high-volume test code, sonnet for implementation, opus for spec/story/review) —
defined once so the whole fleet can be re-tiered in a single edit.

---

## 6 · THE THREE PILLARS

### Pillar 1 — Knowledge parity
The agent fully and clearly understands the ask before it acts. Briefs, roadmap entries,
sentinels, and handoffs are all **self-contained** so any agent joining mid-line can proceed
without conversation history. Ambiguity is surfaced, never assumed.
→ `knowledge/pillars/knowledge-parity.md`

### Pillar 2 — Quality as a first-class concern
Quality is built in across a full assurance chain — **EARS spec → FEATURE docs (BDD) → UNIT →
COMPONENT → CONNECTED-SYSTEM → STORY proofs** — each layer strengthened by a **performance-delta
gate** that blocks the line on a significant regression:

![The quality assurance chain: EARS spec → FEATURE docs (BDD) → UNIT assertions → COMPONENT assertions → CONNECTED-SYSTEM assertions → STORY proofs, an ordered chain where every transition is strengthened by a performance-delta gate; 100% coverage is the floor (not the goal), and the perf-delta gate runs with the STORY tests — a story whose performance regresses past budget does not merge.](diagrams/03-quality-chain.png)

- **100% coverage is the floor, not the goal.** The only path below it is an explicit
  `# pragma: no cover` with a documented reason. 99% is a bug, not "nearly done."
- **A failing unit test is a coordinate** (§7).
- The perf-delta gate runs *with* the STORY tests: a story whose performance regresses past
  the configured budget versus baseline **does not merge**.
→ `knowledge/pillars/quality-first.md`, `knowledge/testing/test-policy.md`

### Pillar 3 — Waste elimination
The persistent, systematic identification and elimination of the **seven wastes** applied to
software. The governing intuition: **a bug found in development is far less wasteful than a
bug found in production** — so more (cheap, early) testing is *less* waste. Parallelism,
just-in-time specification, reviewer gates, and token budgets all serve this pillar.
→ `knowledge/pillars/waste-elimination.md`

---

## 7 · THE CODE PHILOSOPHY — tests as coordinates

> A well-formed failing unit test is a **coordinate in multidimensional logical space** — a
> precise `input → expected output` assertion against a *pure* function that pins one point
> (or a tightly-constrained region) in the space of all possible implementations. The path
> from specification to product is navigated by turning each coordinate green. The test is
> not a check applied after the fact; it is the **unequivocal location of the solution.**

This reframes how work decomposes, and is why the line is maximally parallel:
1. **Extract pure logic first** — pull the decidable core out of DOM/IO/render/network into
   small, dependency-light modules. A coordinate can only be placed in a pure space.
   (See `knowledge/architecture/pure-core.md`.)
2. **Place the coordinate before the implementation** — write it, run it, confirm it fails for the
   *right reason*, then make it pass. A test written after the code is a description; one written
   before is a *location*.
3. **Express every requirement as failing coordinates** whose input/output pairs locate the
   correct code. **One axis per edge case** (empty, max, boundary, unicode) narrows the region to
   one implementation; a bug fix gets a coordinate that *is* the bug's negation; an invariant gets a
   property test; **parse-don't-validate** and **typed errors (never strings)** keep coordinates
   precise. (Mechanics in `knowledge/testing/test-policy.md` §Coordinates in practice.)
4. **Keep the wiring thin** — DOM/IO layers wire the proven cores; they carry no decidable
   logic and are validated at the story/system level.

The consequential rules above are tagged with the **certainty markers**
(`knowledge/protocols/certainty-markers.md`) wherever they appear in skills and handlers, so the
reasoning travels with each rule.

Because each coordinate references only its pure module, the failing-test set is a
**maximally parallel work graph**: independent handlers solve disjoint coordinates with no
shared mutable context. The only serialization points are genuinely shared files.

---

## 8 · TOKEN EFFICIENCY — the overarching constraint

Passing context to a model is a potentially wasteful operation. FOUNDRY optimises for
token-efficiency at the agent level and the value-handling level via **progressive
disclosure**:

- **Thin skills, fat references.** Each `SKILL.md` is a router: trigger, the station's value,
  the exit gate, and a *when-to-read* reference table. Bodies of knowledge live in
  `references/` or `knowledge/` and load only on demand.
- **Define once, reference many.** Canonical knowledge (EARS, BDD, test-policy, SOLID,
  commit-message, sentinels, handoff schema, model policy) lives in exactly one file under
  `knowledge/`; skills and agents point to it, never restate it.
- **Station-scoped loading.** A subagent spawned for one station receives only that station's
  references — a TEST handler gets `knowledge/testing/` + `knowledge/specs/`, not the
  architecture corpus or the frontend philosophy tree.
→ `knowledge/token-efficiency.md`

---

## 9 · Orchestration hierarchy

Three altitudes, one chain of command — no two orchestrators overlap:

```
founder (COO / portfolio)          — turns an idea into a value-stationed path; staffs the
   │                                  line; enforces the test contract; writes no domain code
   ▼
builder-lead (cycle planner)       — ingests ROADMAP, builds SMU, decomposes + tiers items,
   │                                  budgets tokens, emits FOUNDRY_PLAN.md. Plans; doesn't run.
   ▼
lifecycle-orchestrator (item run)  — drives ONE item through steps 0–9, sequencing ds-step-*
   │                                  and enforcing gates against the loop state model
   ▼
ds-step-* + handler-*              — do the station work
   ▼
reviewer (panel)                   — gates every transition (PASS / NEEDS_REVISION / BLOCK)
```

---

## 10 · The map (master index)

| Station | Skill | Agents | Knowledge |
|---------|-------|--------|-----------|
| IDEA | `ideator` | founder | pillars/knowledge-parity |
| ROADMAP | `roadmapper`, `builder` | builder-lead | orchestration/tier-assignment |
| PLAN | `development-system-core` | ds-step-0-plan | orchestration/orchestration-loop, protocols/definition-of-done |
| EARS | `lifecycle-states` | ds-step-1-ears | specs/ears |
| FEATURE | `lifecycle-states` | ds-step-2-feature-docs | specs/bdd-gherkin |
| TEST | `lifecycle-states` | ds-step-3-tests, ds-step-4-first-test-run | testing/test-policy |
| IMPLEMENT | `lifecycle-states`, `code-quality` | ds-step-5, ds-step-6, handler-* | architecture/*, pillars/implementation-covenant |
| DESIGN | `frontend` | handler-vanilla-js, handler-css | frontend resources |
| STORY | `lifecycle-states` | ds-step-story-tests, handler-playwright | testing/test-policy (perf-delta) |
| DELIVERY | `lifecycle-states` | ds-step-7/8/9 | protocols/commit-message, protocols/definition-of-done |
| GOVERNANCE | `code-quality`, `reviewer-gate` | reviewer, inspector, coverage-loop-agent, flaky-test-fixer | all pillars, testing/* |
| PUBLISHING *(companion)* | `pressroom` plugin: `writer`, `diagram-studio`, `mermaid-specialist`, `rich-pdf-with-diagrams`, `design-reviewer` (via `/publish`) | writer's reviewer · typographic/dataviz reviewers | — |
| SECURITY *(companion)* | `security` plugin: `scan-for-pii`, `scan-for-secrets`, `scan-dependencies` (via `/security:scan-all`) | (parallel audit sub-agents) | — |
| DESIGN *(companion)* | `atelier` plugin: `ui-review`, `mockup` (via `/ui-review`, `/mockup`) | ui-design-reviewer | — |
| SENSOR (infra) | `phase-sensor` | (hook) | per-phase notes |

The [`knowledge/README.md`](knowledge/README.md) index says which doc answers which question, and
[`knowledge/glossary.md`](knowledge/glossary.md) names every concept/plugin/agent/skill (including
the **foundry vs forge vs founder** distinction) and draws the conceptual-domain tree. Start at the
index for a canonical fact, the glossary for a name, and *here* to understand the system.
