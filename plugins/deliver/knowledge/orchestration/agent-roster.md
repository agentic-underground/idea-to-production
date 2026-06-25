# Agent Roster Reference

> For DELIVER §7–§9. The complete catalogue of agents used in a DELIVER cycle:
> their roles, capabilities, spawn conditions, and context requirements.

---

## PHASE_POOL Agents

These agents handle the five DEV_SYSTEM stages. They are spawned as general
agents with a specific role prompt. Context always includes: SMU, full sentinel
chain to date, relevant artefacts from prior phases.

---

### EARS-AGENT

**Role:** Requirements specification author
**Phase:** 1 — EARS Specification
**Spawned by:** DELIVER orchestrator at cycle start for each roadmap item
**Input context:** Roadmap item brief + SMU + existing `doc/SPECIFICATION.ears.md`

**Responsibilities:**
- Write EARS statements using the five EARS forms:
  - Ubiquitous: "The [system] shall [capability]"
  - Event-driven: "When [trigger], the [system] shall [response]"
  - State-driven: "While [state], the [system] shall [behaviour]"
  - Unwanted behaviour: "If [condition], then the [system] shall [safeguard]"
  - Optional feature: "Where [feature] is enabled, the [system] shall [behaviour]"
- Assign unique IDs (`EARS-{NNN}`, incrementing from highest existing ID)
- Ensure every actor in the SMU is represented by at least one EARS statement
- Ensure every constraint in the SMU is addressed by at least one EARS statement

**Output:** EARS statements appended to `doc/SPECIFICATION.ears.md`
**Completion signal:** `SENTINEL::EARS_COMPLETE::ROADMAP-{N}::PASS::{ear_ids}`

---

### FEATURE-AGENT

**Role:** BDD specification author
**Phase:** 2 — Gherkin Feature Files
**Spawned by:** DELIVER orchestrator after EARS-REVIEWER PASS
**Input context:** EARS statements + Phase 1 sentinel + SMU

**Responsibilities:**
- Write Gherkin scenarios for each EARS statement
- Required scenario types per EARS statement:
  - Happy path: correct input, expected output
  - Unhappy path: missing/invalid input, graceful failure
  - Abuse/adversarial path: boundary values, malformed input, resistance
- Tag each scenario: `@EARS-{ID}` for every EARS statement it covers
- Use the Given-When-Then structure strictly — no And-Then-Then patterns
- Write scenarios in the language of the domain (use SMU vocabulary)

**Output:** `features/{slug}.feature` (created or appended)
**Completion signal:** `SENTINEL::FEATURE_COMPLETE::ROADMAP-{N}::PASS::{count}::{path}`

---

### TEST-AGENT

**Role:** Test code author (TDD red phase)
**Phase:** 3 — Failing Tests
**Spawned by:** DELIVER orchestrator after BDD-REVIEWER PASS
**Input context:** EARS statements + feature file + Phases 1–2 sentinels + SMU
**Sub-agents:** Spawns appropriate VALUE_HANDLER for the stack

**Responsibilities:**
- Write unit tests for every unit of logic implied by EARS statements
- Write integration tests for every service interaction
- Write BDD step definitions for every Gherkin scenario
- Reference EARS IDs in test names or docstrings: `# @EARS-042`
- Do NOT write implementation code — tests must be RED
- Fix infrastructure issues (imports, config, test runner setup) before reporting

**Output:** Test files in project's test directory
**Completion signal:** `SENTINEL::TESTS_WRITTEN::ROADMAP-{N}::RED::{count}::{ears_ids}`

---

### IMPLEMENT-AGENT

**Role:** Production code author
**Phase:** 4 — Implementation
**Spawned by:** DELIVER orchestrator after TEST-DESIGN-REVIEWER PASS
**Input context:** All previous sentinels + test files + DELIVER_PLAN shared-infra map + SMU
**Sub-agents:** Spawns VALUE_HANDLER agents per language/framework required
**Authority:** CODE_QUALITY skill is the knowledge-home for all design decisions

**Responsibilities:**
- Write the minimum production code to make Phase 3 tests pass
- Follow existing project conventions (naming, structure, error handling)
- Build shared infrastructure components before item-specific code
- Do NOT modify test files — if a test is wrong, flag it for Phase 3 revision
- Run tests after each meaningful change; maintain green state
- Consult CODE_QUALITY skill when making architectural decisions

**Output:** Production code files (source tree)
**Completion signal:** `SENTINEL::IMPL_COMPLETE::ROADMAP-{N}::GREEN::{files}::{coverage}`

---

### STORY-AGENT

**Role:** E2E and story test author
**Phase:** 5 — Story Tests
**Spawned by:** DELIVER orchestrator after COVERAGE-REVIEWER PASS (Phase 4)
**Input context:** All previous sentinels + implemented system + feature file + SMU
**Sub-agents:** Spawns PLAYWRIGHT-AGENT for web UI; FASTAPI-AGENT for API story tests

**Responsibilities:**
- Write story tests for every user journey described in SMU actors section
- Map each story test to ≥ 1 Gherkin scenario (comment the @EARS-{ID} tags)
- Run the full test suite; confirm 100% coverage before issuing sentinel
- Confirm no regressions in existing story tests
- For BDD-expressed interfaces: spawn a BDD-EXPERT sub-agent for step definitions

**Output:** Story test files; updated coverage report
**Completion signal:** `SENTINEL::STORY_PROVEN::ROADMAP-{N}::COMPLETE::{count}::{100.0}`

---

## REVIEWER Agents

All reviewers carry the KAIZEN covenant. Spawned as `reviewer` agent
with a `role` parameter. Each reviewer issues: `PASS`, `NEEDS_REVISION`, or `BLOCK`.

---

### EARS-REVIEWER

**Activated at:** EARS → FEATURE transition
**Checks:**
- Every actor in the SMU is represented in the EARS statements
- Every constraint in the SMU is addressed
- EARS IDs are unique and follow the numbering convention
- EARS forms are used correctly (no hybrid statements)
- Scope is consistent with the roadmap item brief
- No EARS statement contradicts an existing one in the specification

---

### SMU-REVIEWER

**Activated at:** EARS → FEATURE transition (alongside EARS-REVIEWER)
**Checks:**
- EARS vocabulary is consistent with SMU domain terms
- No new terms introduced in EARS without definition in SMU
- Actors named in EARS match actors defined in SMU
- Design values in SMU are not violated by any EARS statement

---

### BDD-REVIEWER

**Activated at:** FEATURE → TEST transition
**Checks:**
- Every EARS statement has ≥ 3 scenarios (happy, unhappy, abuse)
- Scenarios use Given-When-Then correctly
- No scenario is untestable as written
- Scenario language uses SMU vocabulary
- Tags correctly reference `@EARS-{ID}` values
- No duplicate scenarios; no scenarios that test the same thing in two ways

---

### TEST-DESIGN-REVIEWER

**Activated at:** TEST → IMPLEMENT transition
**Checks:**
- All EARS IDs are covered by ≥ 1 test
- All Gherkin scenarios have step definitions
- Tests are genuinely RED (suite has been run; failures confirmed)
- No vacuous assertions (`assert True`, `assert result is not None` only)
- Unit tests are isolated (no hidden external dependencies)
- Test names are descriptive: `test_login_fails_when_password_is_incorrect`

---

### DESIGN-REVIEWER

**Activated at:** IMPLEMENT → STORY transition
**Primary reference:** CODE_QUALITY skill
**Checks:**
- SOLID principles adhered to (Single Responsibility especially)
- No hardcoded dependencies that prevent testability
- Error handling is explicit and tested
- Naming is clear and consistent with SMU vocabulary and project conventions
- No dead code; no commented-out code
- No premature abstraction; no missing abstraction where repetition exists

---

### COVERAGE-REVIEWER

**Activated at:** Every transition involving code (TEST, IMPLEMENT, STORY)
**Checks:** (see `references/test-policy.md` for full checklist)
- Line coverage ≥ 100% (at IMPL and STORY phases)
- Tests are RED at TEST phase (not GREEN prematurely)
- No fake coverage patterns
- All exclusions have explicit comments and rationale

---

### SECURITY-REVIEWER

**Activated at:** STORY → COMPLETE transition
**Checks:**
- No OWASP Top 10 vulnerabilities introduced
- No secrets in source code (API keys, passwords, tokens)
- Input validation at all external boundaries
- Authentication and authorisation enforced where required by SMU
- No SQL injection vectors; no XSS vectors in templates

---

### REGRESSION-REVIEWER

**Activated at:** STORY → COMPLETE transition
**Checks:**
- Run the full test suite including pre-existing tests
- Zero previously-passing tests now failing
- Performance of existing story tests not significantly degraded
- Behaviour of existing features not altered by implementation changes

---

## DEVELOPMENT SYSTEM Step Agents

These are the named, single-responsibility agents that implement the DEV_SYSTEM pipeline.
Each maps to one of the PHASE_POOL roles above, with explicit inputs, outputs, handoff
schemas, and sentinel emissions. Spawn by name rather than as general agents with role prompts.

See each agent file in `${CLAUDE_PLUGIN_ROOT}/agents/ds-step-*.md` for the full definition.

| Agent | Maps to | Sentinel in | Sentinel out | Model |
|---|---|---|---|---|
| `ds-step-0-plan` | (pre-EARS planning) | item brief | `PLAN_COMPLETE` | sonnet (default) |
| `ds-step-1-ears` | EARS-AGENT | `PLAN_COMPLETE` | `EARS_COMPLETE` | **opus** |
| `ds-step-2-feature-docs` | FEATURE-AGENT | `EARS_COMPLETE` | `FEATURE_COMPLETE` | **opus** |
| `ds-step-3-tests` | TEST-AGENT | `FEATURE_COMPLETE` | `TESTS_WRITTEN::RED` | **haiku** |
| `ds-step-4-first-test-run` | TEST-AGENT (validation) | `TESTS_WRITTEN` | `GAP_MAP_COMPLETE` | sonnet (default) |
| `ds-step-5-implementation` | IMPLEMENT-AGENT | `GAP_MAP_COMPLETE` | `IMPL_COMPLETE::GREEN` | sonnet (default) |
| `ds-step-6-green-run` | IMPLEMENT-AGENT (green phase) | `IMPL_COMPLETE` | `GREEN_RUN_COMPLETE` | sonnet (default) |
| `ds-step-story-tests` | STORY-AGENT (E2E) | `GREEN_RUN_COMPLETE` | `STORY_PROVEN` | **opus** |
| `ds-step-7-sync` | DELIVERY-AGENT (sync) | `STORY_PROVEN` | `SYNC_COMPLETE` | sonnet (default) |
| `ds-step-8-commit-message` | DELIVERY-AGENT (message) | `SYNC_COMPLETE` | `COMMIT_MSG_READY` | sonnet (default) |
| `ds-step-9-commit-push` | DELIVERY-AGENT (push / branch-deliver) | `COMMIT_MSG_READY` | `DELIVERY_COMPLETE` | sonnet (default) |
| `handler-architect` | ARCHITECT (any phase) | EARS spec | `ARCHITECTURE_DECIDED` | **opus** |

Each step agent carries:
- Single stage responsibility
- Explicit sentinel prerequisites and emission
- YAML handoff payload to next stage
- Reviewer rule (which reviewer and when)
- KAIZEN self-improvement covenant

---

## ORCHESTRATOR Agent

See `agents/lifecycle-orchestrator.md` for the full agent definition.

**Role:** Per-item SDLC loop controller
**Spawned:** When a roadmap item enters the Development System (inside or outside DELIVER)
**Scope:** Steps 0–9 for a single roadmap item; enforces DoD and iteration logic

---

## REVIEWER Agent (Development System)

See `agents/reviewer.md` for the full agent definition.

**Role:** General-purpose document reviewer for Development System artifacts
**Spawned:** By any step agent for documents not covered by `reviewer` specialized roles
**Scope:** Any document produced during the Development System lifecycle

---

## LEAD ENGINEER Agent

See `agents/builder-lead.md` for the full agent definition.

**Role:** Orchestration architect and domain synthesiser
**Spawned:** Once per DELIVER cycle at the start of §5
**Scope:** Full roadmap, full codebase, historical IDEA_COST data

---

## INSPECTOR Agent

See [`../../agents/inspector.md`](../../agents/inspector.md) for the full agent definition.

**Role:** DELIVER plugin health and improvement auditor
**Spawned:** **User-initiated only** — "inspect DELIVER" / "run the inspector". Never scheduled automatically.
**Scope:** The DELIVER plugin (`${CLAUDE_PLUGIN_ROOT}`) — skills, agents, knowledge, commands, hooks — and companion plugins if present.

---

## VALUE_HANDLER Agents (the stack pool)

The TEST/IMPLEMENT/STORY phase agents spawn the appropriate **value-handler** for the project's
stack. The canonical, extensible list is the VALUE_HANDLER_POOL in
[`../../skills/builder/SKILL.md`](../../skills/builder/SKILL.md) (and the stack-handler set in
`VALUE_FLOW.md §5`). Current handlers:

`handler-architect`, `handler-python`, `handler-fastapi`, `handler-js`, `handler-vanilla-js`
(native handler of the `frontend` DESIGN system), `handler-react`, `handler-css`,
`handler-playwright`, `handler-rust`, `handler-rust-webapp` (the RUST_WEBAPP_API one-shot,
governed by the `rust-webapp-rollout` skill), `handler-rust-tauri` (the Tauri desktop shell over a
pure Rust core), `handler-github-actions` (CI/CD-as-code on GitHub Actions), `handler-ansible`
(Ansible / IaC — idempotent playbooks + roles, ansible-vault, Molecule + ansible-lint gating;
spawned when the stack carries `.yml` playbooks, a `roles/` dir, or `ansible.cfg`), and
`handler-roadmap-decomposition` (the atomic-job-breakdown specialist spawned by the LEAD ENGINEER
during §5 decomposition — it plans, it does not orchestrate). Each carries `model: inherit` and is
spawned at the phase tier per [`../policy/model-selection.md`](../policy/model-selection.md). The
`.docx` publishing-output handler (`handler-docx`) lives in the **publish** plugin, reachable from
`/publish:publish`.

---

## Command-driven skills (not agents, but they orchestrate agents)

These are invoked by command, not spawned as pipeline agents — but they belong in the roster because
one of them drives the `reviewer` agent:

- **`pr-review`** ([`../../skills/pr-review/SKILL.md`](../../skills/pr-review/SKILL.md)) — the
  adversarial merge gate. **Fans out the `reviewer` agent in up to six adversarial roles**
  (correctness, security, regression, architecture, performance, docs), each prompted to *refute*
  the change, then synthesises one verdict (`PASS | NEEDS_REVISION | BLOCK`). Composes
  `/secure:scan-all` when the SECURE plugin is present. Outcome routing is the project's **merge governance**
  ([`../protocols/merge-governance.md`](../protocols/merge-governance.md)).
- **`check`** ([`../../skills/check/SKILL.md`](../../skills/check/SKILL.md)) — diagnostic; verifies
  the plugin's external tool dependencies (`requirements.tsv`). Mirrored in secure and publish.
- **`prerequisites`** ([`../../skills/prerequisites/SKILL.md`](../../skills/prerequisites/SKILL.md)) —
  emits a project-local `PREREQUISITES.md` from the installed plugins' manifests.
- **`self-improve`** ([`../../skills/self-improve/SKILL.md`](../../skills/self-improve/SKILL.md)) — the
  targeted self-cleaving loop: reflect on ONE element against the KAIZEN covenant + pillars, cleave or
  reference-not-restate, apply on a branch, run `pr-review`, and open a PR per merge governance so all
  users inherit it. (`/inspect` audits the whole plugin; `self-improve` fixes one element well.)
