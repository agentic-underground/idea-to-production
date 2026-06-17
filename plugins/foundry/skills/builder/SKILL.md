---
name: builder
description: >
  FOUNDRY — Technical Tooling for Software Evolution. The production orchestrator
  for this production system. Ingests a complete ROADMAP.md, tiers all items by
  PRIORITY_STATUS against a token budget, decomposes the full backlog into
  parallelised expert subagents (PHASE_POOL + VALUE_HANDLER_POOL), drives every
  item through the full DEV_SYSTEM pipeline (EARS → FEATURE → TEST → IMPLEMENT →
  STORY), and records every completion in IDEA_COST.jsonl. FOUNDRY is the engine
  of the idea-to-production conveyor.
  Trigger when the user says: "run the foundry", "process the roadmap",
  "orchestrate the roadmap", "ship the backlog", "build everything", "start
  FOUNDRY", "run a foundry cycle", "what would this cost?", "estimate the
  backlog", or "inspect FOUNDRY".
---

# FOUNDRY

> Agent-internal — invoked by the FOUNDRY conveyor, not typed directly.

> *Technical Tooling for Software Evolution*

FOUNDRY is the production orchestrator of the idea-to-production conveyor. It takes a fully
populated `ROADMAP.md`, tiers all pending items by token budget and priority,
decomposes the work into parallelised specialist subagents, drives every item
through the complete DEV_SYSTEM pipeline, and records the cost of every
completion in `IDEA_COST.jsonl` so the system gets smarter with every cycle.

---

## 0. STRUCTURAL GUARDRAIL — READ THIS FIRST

> **FOUNDRY orchestrates. It does not implement.**
>
> FOUNDRY spawns agents, sequences phases, invokes reviewers, and records costs.
> It does not write EARS statements, Gherkin, test code, or production code
> directly. All artefact production is delegated to PHASE_POOL and
> VALUE_HANDLER_POOL agents. FOUNDRY's only direct writes are to
> `docs/internal/FOUNDRY_PLAN.md` and `IDEA_COST.jsonl`.
>
> **CODE_QUALITY is the knowledge-home for all code design and review decisions.**
> FOUNDRY defers to it at every implementation and review stage.
>
> **Token scarcity is a first-class constraint.** Every orchestration decision
> must account for token budget. Tiering, parallelisation, and batching are all
> in service of maximising FEATURE value per token spent.
>
> **KAIZEN applies to all documents, agents, and artefacts produced by FOUNDRY.**
> The covenant in `${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/kaizen-covenant.md` travels with everything.

---

## 1. TRIGGERS & ENTRY POINTS

| User says / does | Entry point |
|---|---|
| "run the foundry" / "process the roadmap" / "orchestrate" | → §3 ROADMAP INGESTION |
| "ship the backlog" / "build everything" / "start FOUNDRY" | → §3 ROADMAP INGESTION |
| "run a foundry cycle" / "full send" | → §3 ROADMAP INGESTION |
| "what would this cost?" / "estimate the backlog" | → §4.3 TOKEN ESTIMATION only |
| "inspect FOUNDRY" / "run the inspector" | → §13 INSPECTION PROTOCOL |
| "add to FOUNDRY" / "update FOUNDRY knowledge" | → §14 SELF-IMPROVEMENT |
| "what tier is [item]?" / "reprioritise" | → §4 TIER ASSIGNMENT only |

---

## 2. PRE-FLIGHT SCAN

Before any processing, silently check:

1. Locate `ROADMAP.md` or `doc/ROADMAP.md`. If absent, stop and tell the user:
   > "No ROADMAP.md found. FOUNDRY requires a populated roadmap. Run IDEATOR
   > then ROADMAPPER to create one, then return here."
2. Read `IDEA_COST.jsonl` (project root or `doc/`) if it exists — extract
   average token cost per item type for budget estimation.
3. Identify the project stack: scan `package.json`, `pyproject.toml`,
   `Cargo.toml`, `go.mod`, dominant file extensions. Note languages and
   frameworks — this informs VALUE_HANDLER_POOL selection.
4. Check for `doc/SUBJECT_MATTER_UNDERSTANDING.md`. If absent, note it — LEAD
   ENGINEER will create it during §5.
5. Check for existing `doc/SPECIFICATION.ears.md` and `features/` directory.
   Note what already exists — completed items should not be reprocessed.

Record findings. Narrate only if something requires user attention (e.g., no
roadmap, or a conflict between existing artefacts and roadmap status).

---

## 3. ROADMAP INGESTION

Read the full roadmap. For each entry extract:

```
ID, TITLE, STATUS, PRIORITY_STATUS, BRIEF, SLUG
```

**Filter:** Only process items with STATUS = `PENDING` or `BACKLOG`.
Skip: `COMPLETE`, `DEFERRED`, `IN PROGRESS` (unless user explicitly says to resume).

Present the filtered list to the user:

```
FOUNDRY — Roadmap Ingestion
────────────────────────────
Found N items eligible for processing:

  #1  [TITLE]  PRIORITY: HIGH    Est. tokens: ~N
  #3  [TITLE]  PRIORITY: MEDIUM  Est. tokens: ~N
  #7  [TITLE]  PRIORITY: LOW     Est. tokens: ~N
  ...

Proposed tier structure: [see §4]
Proceed with full cycle, or adjust tiers first?
```

Wait for user confirmation or adjustments before proceeding to §5.

---

## 4. TIER ASSIGNMENT (PRIORITY_STATUS → TIERS)

See `${CLAUDE_PLUGIN_ROOT}/knowledge/orchestration/tier-assignment.md` for the full assignment matrix.

### 4.1 Assignment rules

| PRIORITY_STATUS | Default tier | Override condition |
|---|---|---|
| `CRITICAL` | PRIMARY | — |
| `HIGH` | PRIMARY | Unless token budget exhausted |
| `MEDIUM` | SECONDARY | May promote to PRIMARY if it unblocks HIGH items |
| `LOW` | TERTIARY | — |
| `BACKLOG` | TERTIARY+ | Processed only when all higher tiers complete |

Items with shared infrastructure dependencies are promoted to the earliest tier
that needs them — a MEDIUM item that provides a data layer for three HIGH items
moves to PRIMARY.

### 4.2 Tier budget cap

Each tier has a token budget cap (default: 40% of total estimated session budget
for PRIMARY, 35% for SECONDARY, remainder for TERTIARY+). The LEAD ENGINEER may
adjust these caps during §5 based on item complexity analysis.

### 4.3 Token estimation

Use `IDEA_COST.jsonl` history if available. Estimation heuristics when no
history exists:

| Item complexity | Estimated tokens |
|---|---|
| Trivial (1 EARS statement, 1 scenario) | 8k–15k |
| Small (2–4 EARS, 3–6 scenarios) | 15k–35k |
| Medium (5–8 EARS, 6–12 scenarios) | 35k–80k |
| Large (9+ EARS, 12+ scenarios) | 80k–200k |

Record estimates. Compare against actuals in IDEA_COST.jsonl after completion
to refine future estimates.

---

## 5. LEAD ENGINEER DEEP DIVE

Spawn `builder-lead` agent with:
- Full roadmap text (all items, all tiers)
- Codebase scan output (stack, existing artefacts, test structure)
- Historical IDEA_COST.jsonl (if available)
- Proposed tier structure from §4

LEAD ENGINEER is responsible for producing `docs/internal/FOUNDRY_PLAN.md` containing:

```markdown
# FOUNDRY Plan — [project] — [date]

## Stack Manifest
[Languages, frameworks, test runners, BDD tools, E2E tools]

## Subject Matter Understanding
[Domain context carried by all agents — see ${CLAUDE_PLUGIN_ROOT}/knowledge/orchestration/subject-matter-understanding.md]

## Shared Infrastructure Map
| Component | Used by items | Build in item | Notes |
|---|---|---|---|
| [e.g. User model] | #3, #5, #7 | #3 | Items #5, #7 depend on #3 |

## Work Decomposition
### Item #N — [TITLE]
- Tier: PRIMARY / SECONDARY / TERTIARY
- Token budget estimate: ~Nk
- Tasks: [ordered list of sub-tasks]
- Dependencies: [item IDs this depends on]
- Parallel-safe with: [item IDs that can run concurrently]

## Parallel Grouping
[Which items run concurrently within each tier]

## Build Order
[Dependency graph across all items]

## VALUE_HANDLER_POOL Required
[List of language/stack agents to spawn: PYTHON-AGENT, JS-AGENT, etc.]
```

LEAD ENGINEER also creates `doc/SUBJECT_MATTER_UNDERSTANDING.md` if absent.
See `${CLAUDE_PLUGIN_ROOT}/knowledge/orchestration/subject-matter-understanding.md` for the template.

> **Heavy items — delegate the breakdown.** When a roadmap item is too large to decompose into atomic
> vertical slices by hand, the LEAD ENGINEER may spawn the `handler-roadmap-decomposition` value-handler
> to produce the INVEST-sized, dependency-ordered, phase-mapped job list that fills the **Work
> Decomposition** and **Build Order** sections above. That handler **plans only** — it returns the job
> breakdown; the LEAD ENGINEER remains the orchestrator that sequences and dispatches.

---

## 6. TIERED PRODUCTION

Process tiers in sequence. Within each tier, process items concurrently where
the FOUNDRY_PLAN marks them as parallel-safe.

```
For each TIER in [PRIMARY, SECONDARY, TERTIARY, ...]:
  1. Display tier start banner:
     ══════════════════════════════════════
     FOUNDRY — Tier: PRIMARY (N items)
     Token budget: ~Nk
     ══════════════════════════════════════

  2. For each ITEM in TIER (parallel where parallel-safe):
     → §7 PHASE_POOL PIPELINE for this item

  3. On item completion:
     → §12 IDEA_COST RECORDING for this item

  4. After all items in tier complete:
     - Compare actual vs estimated token costs
     - Adjust next tier estimates accordingly
     - Display tier summary before proceeding
```

Between tiers, pause and report:
```
Tier [NAME] complete.
  Items completed: N
  Actual tokens: ~Nk (estimated: ~Nk, delta: ±N%)
  
Proceed to [NEXT TIER]? (N items, est. ~Nk tokens)
```

---

## 7. PHASE_POOL PIPELINE

Each roadmap item passes through 6 phases in strict sequence. Between every
phase, the REVIEWER panel evaluates the output (§9) before the next phase begins.

**Preferred:** Use the named DS step agents from `${CLAUDE_PLUGIN_ROOT}/agents/ds-step-*.md`
rather than spawning general agents with role prompts. Named agents carry explicit
inputs, outputs, handoff schemas, sentinel emissions, and reviewer rules — they
are single-responsibility and cold-start safe.

The full pipeline and per-item orchestration loop is documented in
`${CLAUDE_PLUGIN_ROOT}/knowledge/orchestration/orchestration-loop.md`. The PHASE_POOL maps to the DS steps as follows:

| FOUNDRY Phase | DS Steps | Named Agents | Model |
|---|---|---|---|
| Pre-cycle (plan) | step-0 | `ds-step-0-plan` | sonnet (default) |
| EARS-AGENT | step-1 | `ds-step-1-ears` | **opus** (EARS) |
| FEATURE-AGENT | step-2 | `ds-step-2-feature-docs` | **opus** (stories) |
| TEST-AGENT | step-3 + step-4 | `ds-step-3-tests`, `ds-step-4-first-test-run` | **haiku** (test code) |
| IMPLEMENT-AGENT | step-5 + step-6 | `ds-step-5-implementation`, `ds-step-6-green-run` | sonnet (default) |
| STORY-AGENT | step-story | `ds-step-story-tests` | **opus** (stories) |
| DELIVERY-AGENT | step-7 + step-8 + step-9 | `ds-step-7-sync`, `ds-step-8-commit-message`, `ds-step-9-commit-push` | sonnet (default) |
| REVIEWER | every gate | `reviewer`, `reviewer` | **opus** (review) |
| ARCHITECT | LEAD §5 or IMPLEMENT §4 boundary | `handler-architect` | **opus** (review-class judgement) |

---

### Phase 0 — PLAN (ds-step-0-plan)

**Spawn:** `ds-step-0-plan`
**Input:** Roadmap item brief + SUBJECT_MATTER_UNDERSTANDING + codebase scan
**Output:** `doc/[FEATURE_SLUG]_PLAN.md` with checklist and resumption instructions

**Context sentinel on completion:**
```
SENTINEL::PLAN_COMPLETE::ROADMAP-{N}::PASS::{plan_path}
```

→ No reviewer panel required (LEAD ENGINEER reviewed the item in §5)

---

### Phase 1 — EARS-AGENT (ds-step-1-ears)

**Spawn:** `ds-step-1-ears`
**Input:** Plan + SUBJECT_MATTER_UNDERSTANDING + existing EARS spec
**Output:** EARS statements appended to `doc/SPECIFICATION.ears.md`
**Test policy anchor:** Each EARS statement gets a unique ID (`EARS-{NNN}`)

**Context sentinel on completion:**
```
SENTINEL::EARS_COMPLETE::ROADMAP-{N}::PASS::{EARS-042,EARS-043,...}
```

→ REVIEWER panel (EARS-REVIEWER, SMU-REVIEWER) evaluates before Phase 2

---

### Phase 2 — FEATURE-AGENT (ds-step-2-feature-docs)

**Spawn:** `ds-step-2-feature-docs`
**Input:** EARS statements + sentinel from Phase 1 + SUBJECT_MATTER_UNDERSTANDING
**Output:** Gherkin scenarios in `features/{slug}.feature`
**Required scenarios per EARS statement:**
- Happy path
- Unhappy path (bad/missing input)
- Abuse/adversarial path (boundary, malformed)

Each scenario tagged `@EARS-{ID}`.

**Context sentinel on completion:**
```
SENTINEL::FEATURE_COMPLETE::ROADMAP-{N}::PASS::{scenario_count}::{feature_file_path}
```

→ REVIEWER panel (BDD-REVIEWER, COVERAGE-REVIEWER) evaluates before Phase 3

---

### Phase 3 — TEST-AGENT (ds-step-3-tests + ds-step-4-first-test-run)

**Spawn:** `ds-step-3-tests` then `ds-step-4-first-test-run` + appropriate VALUE_HANDLER(s)
**Input:** EARS statements + feature file + sentinels from Phases 1–2
**Output:** Failing tests (unit + integration; BDD harness as appropriate) + gap map
**Constraint:** Tests must be RED at end of this phase. No implementation yet.

**Context sentinels on completion:**
```
SENTINEL::TESTS_WRITTEN::ROADMAP-{N}::RED::{test_count}::{ear_ids_covered}
SENTINEL::GAP_MAP_COMPLETE::ROADMAP-{N}::RED::{failing_count}::{ears_ids_exposed}
```

→ REVIEWER panel (TEST-DESIGN-REVIEWER, COVERAGE-REVIEWER) evaluates before Phase 4

---

### Phase 4 — IMPLEMENT-AGENT

**Spawn:** `builder-lead` delegates to VALUE_HANDLER_POOL agents per stack
**Input:** All previous sentinels + test files + FOUNDRY_PLAN shared-infra map
**Primary reference:** CODE_QUALITY skill — consulted for all design decisions
**Output:** Production code making all Phase 3 tests pass
**Constraint:** Do not modify test files. If a test is wrong, return to Phase 3.

**Context sentinel on completion:**
```
SENTINEL::IMPL_COMPLETE::ROADMAP-{N}::GREEN::{files_changed}::{line_coverage_pct}
```

→ REVIEWER panel (DESIGN-REVIEWER, COVERAGE-REVIEWER) evaluates before Phase 5

---

### Phase 5 — STORY-AGENT (ds-step-story-tests)

**Spawn:** `ds-step-story-tests` + interface-appropriate VALUE_HANDLER(s)
**Prerequisite:** IMPL_COMPLETE sentinel must be present — story tests run only against working code.
**Input:**
- `SENTINEL::IMPL_COMPLETE` (confirms unit + integration tests green)
- EARS specification (for traceability — every story test references an EARS-{ID})
- FEATURE docs (Gherkin scenarios — story tests must cover every scenario)
- Original IDEA / PLAN (usage coverage — ensures the human interface layer is exercised)

**Medium (case-by-case):** browser tests, terminal tests, E2E, or API journey tests —
determined by the feature's interface type. Soft rule: more tests means more defects found.
Spawn PLAYWRIGHT-AGENT for browser features; use CLI/subprocess harness for terminal features;
use httpx/curl harness for API-only features.

**Output:** Story/journey tests that exercise the feature end-to-end through its actual interface.
Every test references its EARS-{ID} and the Gherkin scenario it satisfies.

**Coverage gate:** Total line coverage must be ≥ 100% before this phase completes.

**Context sentinel on completion:**
```
SENTINEL::STORY_PROVEN::ROADMAP-{N}::PASS::{story_test_count}::{final_line_coverage_pct}::{final_branch_coverage_pct}
```

→ REVIEWER panel (SECURITY-REVIEWER, REGRESSION-REVIEWER, COVERAGE-REVIEWER, PERFORMANCE-REVIEWER) evaluates before Phase 6

---

### Phase 6 — DELIVERY-AGENT (ds-step-7-sync + ds-step-8-commit-message + ds-step-9-commit-push)

**Spawn:** `ds-step-7-sync`, then `ds-step-8-commit-message`, then `ds-step-9-commit-push` in sequence
**Prerequisite:** STORY_PROVEN sentinel must be present.
**Input:** All accumulated sentinels + final green test run output
**Output:** Feature committed and pushed; roadmap STATUS updated to COMPLETE

Steps within this phase:
1. **Sync** (`ds-step-7-sync`): rebase against upstream; re-run tests after rebase
2. **Commit message** (`ds-step-8-commit-message`): write WHY/WHAT/TESTING/ROADMAP message per
   `${CLAUDE_PLUGIN_ROOT}/knowledge/protocols/commit-message.md`
3. **Commit + push** (`ds-step-9-commit-push`): stage, commit, push; update roadmap STATUS → COMPLETE

**Context sentinel on completion:**
```
SENTINEL::DELIVERY_COMPLETE::ROADMAP-{N}::COMPLETE::{commit_hash}
```

→ Item is marked COMPLETE in roadmap. IDEA_COST recording (§12) is triggered.

---

## 8. VALUE_HANDLER_POOL

Stack-specific agents spawned on demand by IMPLEMENT-AGENT and STORY-AGENT.
Each handler carries: STACK knowledge, SUBJECT_MATTER_UNDERSTANDING, KAIZEN covenant.

Extend the pool without modifying this file — add new handlers as agent files
in `${CLAUDE_PLUGIN_ROOT}/agents/handler-{stack}.md`.

| Handler | Stack | Spawned when |
|---|---|---|
| handler-architect | Pattern decision (language-agnostic) | LEAD ENGINEER §5 or IMPLEMENT-AGENT when a new boundary/context is introduced |
| PYTHON-AGENT | Python + pytest | Backend Python work |
| JS-AGENT | JavaScript/TypeScript + jest/vitest | Frontend or Node work |
| CSS-AGENT | CSS/SCSS + accessibility | Styling and layout |
| REACT-AGENT | React + React Testing Library | Component work |
| VANILLA-JS-AGENT | Vanilla JS + DOM + @testing-library/dom | Vanilla-JS / `frontend` design-system work |
| FASTAPI-AGENT | FastAPI + httpx + pytest | Python API work |
| PLAYWRIGHT-AGENT | Playwright (npx playwright test) | E2E story tests |
| RUST-AGENT | Rust + thiserror + proptest + clippy -D warnings | Rust libraries, CLIs, services, domain cores |
| RUST-WEBAPP-AGENT | Rust/WASM (Dioxus) + Vercel official Rust runtime | Full Rust web app + serverless API one-shot rollout (via the `rust-webapp-rollout` skill) |
| handler-rust-tauri | Tauri v2 desktop shell over a pure Rust core (IPC, capability ACL, webview) | A `src-tauri/` crate / `tauri.conf.json` desktop app |
| handler-github-actions | GitHub Actions CI/CD-as-code (workflow YAML, matrix, OIDC, SHA-pinned actions) | `.github/workflows/*.yml`, composite/reusable actions |
| handler-roadmap-decomposition | Atomic-job breakdown of a ROADMAP item (INVEST slices, dependency graph, phase mapping) | LEAD ENGINEER §5 when a heavy roadmap item must be split into parallelisable jobs — it plans, it does not orchestrate |

When the LEAD ENGINEER identifies a stack not in the pool above, the missing handler is a **PAUSE, not a
silent degrade**. Note it in `docs/internal/FOUNDRY_PLAN.md` under `## VALUE_HANDLER_POOL Required` with a
description of what knowledge the new handler needs — then **STOP and surface the 3-way decision gate**
(BUILD HANDLER FIRST · MVP WITH EXISTING + `DEGRADED_CAPABILITIES` · BOTH) per the governing protocol
[`../../knowledge/orchestration/missing-handler-gate.md`](../../knowledge/orchestration/missing-handler-gate.md).
**Never route the item to the nearest handler on the orchestrator's own authority.** The BUILD path
authors `handler-<stack>` under the handler-authoring discipline
([`../../knowledge/orchestration/handler-authoring-discipline.md`](../../knowledge/orchestration/handler-authoring-discipline.md):
pinned version matrix + FORBIDDEN list); the MVP path discloses `DEGRADED_CAPABILITIES` in
`FOUNDRY_PLAN.md`; the BOTH path raises the gap via `/operate:gemba`, files a DEFERRED
"Create handler-<stack>" item, and marks the original **awaiting-handler** (§14 formalises the agent file
once the BUILD/handler-creation work runs).

---

## 9. REVIEWER PANEL

A REVIEWER panel is invoked at every phase transition. Panels are composable —
each transition uses a specific subset of reviewers. All reviewers carry the
KAIZEN covenant. Spawn using `reviewer` agent with a role parameter.

### 9.1 Panel compositions per transition

| Transition | Reviewers invoked |
|---|---|
| → ADR (when architect spawned) | ARCHITECTURE-REVIEWER |
| → FEATURE (after EARS) | EARS-REVIEWER, SMU-REVIEWER |
| → TEST (after FEATURE) | BDD-REVIEWER, COVERAGE-REVIEWER |
| → IMPLEMENT (after TEST) | TEST-DESIGN-REVIEWER, COVERAGE-REVIEWER |
| → STORY (after IMPLEMENT) | DESIGN-REVIEWER, COVERAGE-REVIEWER, PERFORMANCE-REVIEWER |
| → DELIVERY (after STORY) | SECURITY-REVIEWER, REGRESSION-REVIEWER, COVERAGE-REVIEWER, PERFORMANCE-REVIEWER |

### 9.2 Review verdicts

| Verdict | Meaning | Action |
|---|---|---|
| `PASS` | Output accepted | Pipeline continues to next phase |
| `NEEDS_REVISION` | Specific issues found | Feedback returned to phase agent; phase reruns |
| `BLOCK` | Critical issue | Escalates to LEAD ENGINEER; pipeline pauses |

### 9.3 Revision limit

If a phase receives `NEEDS_REVISION` 3 times in sequence, escalate to `BLOCK`
automatically and surface the issue to the user.

---

## 10. CONTEXT SENTINEL PROTOCOL

See `${CLAUDE_PLUGIN_ROOT}/knowledge/protocols/context-sentinel.md` for full format specification.

Sentinels are structured strings appended to agent context at each phase
boundary. They accumulate — by Phase 6 every agent holds the full chain:

```
SENTINEL::EARS_COMPLETE::ROADMAP-7::PASS::EARS-042,EARS-043,EARS-044
SENTINEL::FEATURE_COMPLETE::ROADMAP-7::PASS::9::features/user-auth.feature
SENTINEL::TESTS_WRITTEN::ROADMAP-7::RED::27::EARS-042,EARS-043,EARS-044
SENTINEL::IMPL_COMPLETE::ROADMAP-7::GREEN::4::98.3
SENTINEL::STORY_PROVEN::ROADMAP-7::PASS::6::100.0
SENTINEL::DELIVERY_COMPLETE::ROADMAP-7::COMPLETE::a1b2c3d
```

This chain provides every downstream agent with a traceable record of what was
produced at each stage, without requiring conversation history.

---

## 11. TEST POLICY

See `${CLAUDE_PLUGIN_ROOT}/knowledge/testing/test-policy.md` for full detail.

**100% line coverage is the floor, not the goal.**

The test pyramid above that floor:

| Layer | Tool | Gate |
|---|---|---|
| Unit | pytest / jest | 100% line coverage required |
| Integration | pytest / jest + test doubles | All service interactions exercised |
| Behavioural (BDD) | pytest-bdd / cucumber / behave | Every Gherkin scenario passing |
| Story (E2E) | Playwright / Selenium | Every user journey exercised |

Every test must reference its EARS ID. Every story test must trace to a Gherkin
scenario. The COVERAGE-REVIEWER enforces this at every review gate.

---

## 12. IDEA_COST RECORDING

On `STORY_PROVEN` for any roadmap item, append one JSON line to `IDEA_COST.jsonl`
(at project root or `doc/`). File is append-only — never modify existing records.

### 12.1 Record schema

See `${CLAUDE_PLUGIN_ROOT}/knowledge/orchestration/idea-cost-schema.md` for the full authoritative schema with all
fields, nested structure, type definitions, and example records.

Do not use an inline schema here — any divergence from the reference creates
split-brain records that break the estimation feedback loop. When writing a
record, open `${CLAUDE_PLUGIN_ROOT}/knowledge/orchestration/idea-cost-schema.md` and follow it exactly.

### 12.2 Accuracy feedback loop

After each item, compute `estimation_accuracy_pct`:
```
accuracy = (1 - abs(actual_tokens - estimated_tokens) / estimated_tokens) * 100
```

Surface accuracy trends at tier boundaries. Over time, LEAD ENGINEER uses this
data to improve estimates. See §14 (self-improvement).

### 12.2a Fold the BUILD actual into the product lifecycle (by capability)

If the **i2p** plugin is installed and the project has an active lifecycle (`.i2p/lifecycle.json` exists),
record this item's authoritative all-agent token total into the lifecycle's **BUILD** phase so the
status-line `◈ life` widget and the estimate↔actual calibration reflect real build cost (not just the
main-thread transcript the Stop hook sees):

```bash
bash <i2p>/skills/lifecycle/scripts/cost.sh record . BUILD <token_accounting.tokens_total>
```

Resolve `<i2p>` by capability (the installed i2p plugin root); skip silently if i2p is absent. This is the
authoritative BUILD actual — see `i2p/knowledge/instrumentation.md`.

### 12.3 Milestone scorecard

`IDEA_COST.jsonl` is the *only* place real tokens/wall-clock are captured (here, mid-cycle). At the same
`STORY_PROVEN` milestone, run the **`scorecard` skill** (`/foundry:scorecard`) to snapshot the project's
artifact-measured quality — `scorecard.sh` reads this record for the real cost fields and combines it with
coverage, corpus FP-rate, rule/test counts, and the SECURITY verdict into `SCORECARD.json`. That snapshot,
compared run-over-run, is the proof the product is getting better. Schema:
[`${CLAUDE_PLUGIN_ROOT}/knowledge/orchestration/scorecard-schema.md`](../../knowledge/orchestration/scorecard-schema.md).

---

## 13. INSPECTION PROTOCOL

Inspection is **user-initiated only**. Say "inspect FOUNDRY" / "run the
inspector" to trigger. There is no scheduled or automatic invocation.

### 13.1 What the inspector does

See [`agents/inspector.md`](../../agents/inspector.md) for full behaviour. In summary:

1. Reads the installed FOUNDRY plugin (`${CLAUDE_PLUGIN_ROOT}`) — skills, agents, knowledge,
   commands, hooks, manifests — and the companion plugins (`security`/`publish`) if present.
2. Builds a fresh critical-analysis persona (domain expert + covenant auditor).
3. Analyses each document against: clarity, accuracy, covenant compliance, coverage **density**,
   outdated patterns, and **portability** (zero machine-specific home/config-dir coupling).
4. Produces `FOUNDRY_INSPECTION_REPORT.md` in the **current project** (never outside it) with
   severity-ranked findings.
5. Surfaces CRITICAL findings to the user; captures WARNING/SUGGESTION in the report.

> **Note:** there is **no git lock** — a plugin install is read-only, not a shared mutable repo,
> so there is nothing to lock or push. The inspector mutates files only when run inside the
> marketplace's own source repository, and never commits/pushes unless the user asks.

---

## 14. SELF-IMPROVEMENT PROTOCOL

FOUNDRY carries the KAIZEN self-improvement covenant. At the end of any full
roadmap cycle, or when the daily inspector surfaces proposals:

1. **Review IDEA_COST.jsonl** for patterns: which items took most tokens?
   Which stages caused the most review cycles? Which stacks were slowest?
2. **LEAD ENGINEER proposes improvements** to agent compositions, tier logic,
   reviewer checklists, or VALUE_HANDLER_POOL entries.
   - **Missing-handler gate.** When a roadmap stack has no handler, that gap is **not** quietly degraded —
     it is paused and decided through the 3-way gate
     ([`../../knowledge/orchestration/missing-handler-gate.md`](../../knowledge/orchestration/missing-handler-gate.md)).
     New handlers authored on the BUILD path follow the handler-authoring discipline
     ([`../../knowledge/orchestration/handler-authoring-discipline.md`](../../knowledge/orchestration/handler-authoring-discipline.md):
     pinned matrix + FORBIDDEN list). The BOTH path raises the gap via `/operate:gemba` so it
     becomes a tracked self-improvement item rather than evaporating.
3. **Inspector proposals** are collated from `FOUNDRY_INSPECTION_REPORT.md`.
4. Present proposed changes to the user for approval.
5. On approval, apply the change in the marketplace's source repository and commit it with the
   standard format ([`commit-message.md`](../../knowledge/protocols/commit-message.md)):
   ```bash
   git add <files>
   git commit -m "skill: <description of improvement>"
   ```
   (Never modify or push any repo that is not the marketplace source; improvements land in the plugin's source repo.)
6. The covenant compliance check from IDEATOR §8.3 applies to all improvements.

---

## 15.5 TOKEN EFFICIENCY MODEL POLICY

The model-tier policy is **canonical in exactly one place** —
[`${CLAUDE_PLUGIN_ROOT}/knowledge/policy/model-selection.md`](../../knowledge/policy/model-selection.md).
It carries: which work class runs on which **tier** (opus / sonnet / haiku) and why; how the
`model: inherit` value-handlers are spawned **per phase** (TEST → haiku, IMPLEMENT → sonnet,
STORY → opus); and the tier → concrete-model-ID mapping (resolved at spawn time, never hardcoded).

**Do not restate that table here.** Reference it, so the whole fleet re-tiers in one edit and no
pinned ID can silently age out. (This pointer deliberately replaces a former duplicate of the policy,
whose independent ageing is exactly what produced a stale-model-ID drift across 13 sites.)

A handler asked to write test code on opus, or stories on haiku, must refuse
and surface the model mismatch to the orchestrator.

---

## 16. STORY PHASE IS MANDATORY

Phase 5 (`ds-step-story-tests`) emits the `STORY_PROVEN` sentinel and is the
only step authorised to do so. No item may advance to Phase 6 (DELIVERY) without
`STORY_PROVEN` in its sentinel chain.

| Sentinel | Owner | Status when emitted |
|---|---|---|
| `STORY_PROVEN` | `ds-step-story-tests` (Phase 5) | `PASS` (line+branch coverage = 100%, UI gate passed, performance assertions pass) |
| `DELIVERY_COMPLETE` | `ds-step-9-commit-push` (Phase 6) | `COMPLETE` (commit pushed, roadmap closed) |

`STORY_PROVEN` and `DELIVERY_COMPLETE` are different signals. Past versions of
this pipeline conflated them by having step-9 emit STORY_PROVEN — that was a
bug. IDEA_COST.jsonl is written only when both are present in the chain.

---

## 17. REFERENCE FILES

| File | Purpose | When to read |
|---|---|---|
| `${CLAUDE_PLUGIN_ROOT}/knowledge/orchestration/tier-assignment.md` | PRIORITY_STATUS → tier logic + budget caps | Before §4 |
| `${CLAUDE_PLUGIN_ROOT}/knowledge/orchestration/idea-cost-schema.md` | IDEA_COST.jsonl field definitions + examples | Before §12 |
| `${CLAUDE_PLUGIN_ROOT}/knowledge/orchestration/subject-matter-understanding.md` | SMU document template | Before §5 (LEAD ENGINEER) |
| `${CLAUDE_PLUGIN_ROOT}/knowledge/protocols/context-sentinel.md` | Sentinel format and accumulation protocol | Before §10 |
| `${CLAUDE_PLUGIN_ROOT}/knowledge/testing/test-policy.md` | Test pyramid + coverage standards + enforcement | Before §11 |
| `${CLAUDE_PLUGIN_ROOT}/knowledge/orchestration/agent-roster.md` | All agent roles, capabilities, spawn conditions | Before §7–§9 |
| `${CLAUDE_PLUGIN_ROOT}/knowledge/orchestration/missing-handler-gate.md` | Missing-handler PAUSE → 3-way gate (BUILD / MVP+DEGRADED / BOTH) + awaiting-handler deferral/resumption | On a §8 / Phase 4.5 handler gap |
| `${CLAUDE_PLUGIN_ROOT}/knowledge/orchestration/handler-authoring-discipline.md` | Pinned version matrix + FORBIDDEN list + four-wave pipeline for authoring a new value-handler | Before authoring `handler-<stack>` (BUILD path) |
| `${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/kaizen-covenant.md` | KAIZEN replication covenant | Carried by all artefacts |
| `${CLAUDE_PLUGIN_ROOT}/knowledge/protocols/definition-of-done.md` | Project DoD template — copy to project root | Before §7 (per-item) |
| `${CLAUDE_PLUGIN_ROOT}/knowledge/orchestration/orchestration-loop.md` | Per-item loop state model + stage routing table | Before §7 (per-item) |
| `${CLAUDE_PLUGIN_ROOT}/skills/lifecycle-states/states/discovery.md` | Pre-step-0 readiness exit criteria | Before spawning step-0 |
| `${CLAUDE_PLUGIN_ROOT}/skills/lifecycle-states/states/specification.md` | EARS and Gherkin exit criteria (steps 1–2) | Before advancing to step-3 |
| `${CLAUDE_PLUGIN_ROOT}/skills/lifecycle-states/states/verification.md` | Test-first and green-run exit criteria (steps 3–6) | Before advancing to step-7 |
| `${CLAUDE_PLUGIN_ROOT}/skills/lifecycle-states/states/delivery.md` | Sync, commit, and push exit criteria (steps 7–9) | Before global DoD audit |
| `${CLAUDE_PLUGIN_ROOT}/skills/lifecycle-states/states/production-readiness.md` | Final DoD certification (post step-9) | Global DoD audit |

---

<!-- KAIZEN REPLICATION FRAGMENT v2.0 -->
<!-- This skill is part of the idea-to-production marketplace. -->
<!-- All documents, agents, and artefacts it produces carry the covenant below. -->

## ♻️ KAIZEN Self-Improvement Covenant

This document is part of the **FOUNDRY** skill in the idea-to-production marketplace.
All artefacts produced by FOUNDRY — plans, specs, feature files, test files,
cost records, and inspection reports — carry this covenant. Its spirit is **kaizen** —
continuous improvement, never finished.

1. **Halve the distance** — each pass moves every agent, phase, and reviewer measurably closer to perfection.
2. **PDCA** — change against a measured hypothesis: plan, do, check, act.
3. **Standardize, then improve** — capture the current best as the standard, then raise the floor in small, reversible steps.
4. **Eliminate muda · mura · muri** — waste, unevenness, and overburden across the pipeline's artefacts.
5. **Fix upstream, once** — a recurring gap is repaired at its source, so no future build pays for it again.

*Skill: FOUNDRY — idea-to-production marketplace*

## Product lifecycle (by capability)

When the conveyor delivers a shippable item (it reaches **SHIP** / the item is marked COMPLETE), and the **i2p** plugin is installed, mark the **BUILD** phase done so the marketplace
product lifecycle and the status line advance to ASSURE:

```bash
/i2p:lifecycle done BUILD   # order-safe & idempotent — a no-op unless a lifecycle is running at BUILD
```

Degrades silently when i2p is absent. The canonical model is `i2p/knowledge/product-lifecycle.md`.
