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
└── pressroom  (PLUGIN · PUBLISHING companion) — writer · diagram-studio · rich-pdf-with-diagrams · /publish
```

The two companions are **cross-cutting**: foundry uses them *by capability* when installed
(graceful enhancement) and degrades to markdown when they are not. See `../VALUE_FLOW.md §4`.

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
| **FORGE** | **NOT part of this marketplace.** It is the author's *private* `~/.claude` development environment ("production facility") where these plugins were originally built. | External. Any in-plugin reference to "the FORGE" was drift and has been removed. |
| **`forge`** (lowercase, in the rust references) | The shipped **worked-example project** (a Rust/WASM + Vercel app) used to illustrate `rust-webapp-rollout`. | A sample project name, not a system. |

**Rule of thumb:** if a document inside a plugin says "the FORGE" as if it were *this* system, that
is a bug — it should say **FOUNDRY** (the plugin) or name the specific companion. The `inspector`
audits for exactly this (`../agents/inspector.md`).

---

## 3. Flat glossary

### Marketplace & plugins
- **idea-to-production** — the marketplace; the repository and the `marketplace.json` `name`.
- **foundry / sentinel / pressroom** — the three plugins (core conveyor / security / publishing).

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
  **phase-sensor** (infra; PostToolUse hook) · **rust-webapp-rollout** (Rust/WASM/Vercel one-shot).

### Commands
- foundry: **/foundry** · **/inspect** · **/coverage-loop** · **/phase-sensor** · **/rust-webapp-rollout**
- sentinel: **/security-gate** · **/pii-audit** · **/secret-scan** · **/dependency-audit**
- pressroom: **/publish**

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

### Artefacts
- **FOUNDRY_PLAN.md** (cycle plan) · **IDEA_COST.jsonl** (cost ledger) · **SUBJECT_MATTER_UNDERSTANDING.md**
  (SMU) · **FOUNDRY_INSPECTION_REPORT.md** (inspector output, written to the project) ·
  **SECURITY-REPORT.md** (sentinel verdict) · sentinels (machine-readable phase state).

---

## 4. Where to look next
- The system, end-to-end → [`../VALUE_FLOW.md`](../VALUE_FLOW.md)
- A canonical fact → [`README.md`](README.md) (the "which doc answers which question" index)
- Who staffs what → [`orchestration/agent-roster.md`](orchestration/agent-roster.md) +
  the `builder` VALUE_HANDLER_POOL.
- Worked examples of the dev system → [`../examples/README.md`](../examples/README.md)
- How the system came to be → [`../docs/HISTORY.md`](../docs/HISTORY.md)
