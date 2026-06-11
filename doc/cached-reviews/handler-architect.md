# Cached review — FOUNDRY handler-architect

**Target file:** `plugins/foundry/agents/handler-architect.md`  
**Unit:** `handler-architect`  
**Findings:** 10 · **Capability-uplift proposals:** 6

> Cached output from the adversarial Review stage — raw reviewer findings BEFORE the refute/verify pass and BEFORE any edits were applied. Severity: CRITICAL / HIGH / MEDIUM / LOW / SUGGESTION.

## Findings

### 1. [HIGH] ADR review routed to the wrong reviewer role — DESIGN-REVIEWER cannot review an ADR

**Evidence:** plugins/foundry/agents/handler-architect.md line ~227: "reviewed: false  # ADR review is by DESIGN-REVIEWER at the next phase gate". But plugins/foundry/agents/reviewer.md (~line 408) assigns ADR review to ARCHITECTURE-REVIEWER: "### ARCHITECTURE-REVIEWER — You are a senior architect. You evaluate whether the pattern recorded in any ADR produced by `handler-architect` is a sound fit for the SMU and EARS spec." DESIGN-REVIEWER (reviewer.md ~line 272) evaluates *implementation code* against SOLID, not ADRs.

**Recommendation:** Change the handoff comment to "ADR review is by ARCHITECTURE-REVIEWER at the next phase gate" and add an explicit next_agent_instruction telling the orchestrator to invoke reviewer with role=ARCHITECTURE-REVIEWER before any downstream stage consumes the ADR. As written, the review gate is misrouted and the ADR-specific checklist (concrete paths, all-five-layer test table, rejected alternatives) is never applied.

### 2. [HIGH] builder-lead routes IDEA_COST high-variance investigations to this handler, but the handler carries zero doctrine for that task

**Evidence:** plugins/foundry/agents/builder-lead.md (~line 222, P2-9): "Flag it in the decomposition (`estimation_basis: HIGH_VARIANCE`) and route it to `handler-architect` for investigation before committing a budget". handler-architect.md's frontmatter (~lines 8-11) names only two spawn triggers ("Spawned by builder-lead during §5 planning... and again by IMPLEMENT-AGENT (Phase 4)"); Phase 0 (~lines 74-84) never reads IDEA_COST.jsonl, and no phase, output contract, or sentinel exists for a variance investigation.

**Recommendation:** Either add an explicit estimation-variance investigation mode to handler-architect (inputs: IDEA_COST.jsonl comparables + the flagged decomposition entry; output: an ADR or a DECISION_NEEDED note back to builder-lead), or change builder-lead's P2-9 routing. Today the caller dispatches work the callee's cold-start definition cannot execute — the spawned agent will improvise.

### 3. [HIGH] No failure mode anywhere: missing/malformed inputs and unredesignable boundaries have no escalation path or failure sentinel

**Evidence:** Phase 0 (~lines 74-84) mandates reading `doc/SUBJECT_MATTER_UNDERSTANDING.md` and `doc/SPECIFICATION.ears.md` with no instruction for when they are absent or malformed — even though the builder skill itself anticipates absence (skills/builder/SKILL.md ~line 77: "Check for `doc/SUBJECT_MATTER_UNDERSTANDING.md`. If absent, note it"). The only sentinel defined (~line 206) is the success form "SENTINEL::ARCHITECTURE_DECIDED::ROADMAP-{N}::PASS::..."; the test-first mandate (~line 56) says "your job is to **redesign the boundary**" but gives no path when the EARS spec itself forces an untestable boundary (the spec is upstream of this agent and not its to edit).

**Recommendation:** Add a Phase 0 validation preamble (missing/ID-less EARS spec, missing SMU → emit SENTINEL::ARCHITECTURE_DECIDED::ROADMAP-{N}::BLOCK::{missing_input} and a handoff back to the spawning agent) and a bounded escalation rule: if the three test-first answers cannot all be made yes by redesigning the boundary within this item, emit NEEDS_REVISION toward ds-step-1-ears via the orchestrator rather than silently shipping or stalling.

### 4. [MEDIUM] ARCHITECTURE_DECIDED sentinel is not registered in the canonical sentinel protocol

**Evidence:** handler-architect.md ~line 206 emits SENTINEL::ARCHITECTURE_DECIDED, and knowledge/orchestration/agent-roster.md:250 lists it, but knowledge/protocols/context-sentinel.md's "Phase Codes and Payloads" registry (the doc downstream agents use to "confirm prerequisite stages are complete") contains no ARCHITECTURE entry (grep for ARCHITECTURE in that file returns nothing).

**Recommendation:** Register ARCHITECTURE_DECIDED (phase code, payload shape {adr_path}::{primary_pattern}, and the BLOCK variant) in context-sentinel.md, and have handler-architect cite that registry entry — otherwise sentinel-validating consumers treat the architect's output as an unknown phase code.

### 5. [MEDIUM] ADR template hardcodes Status: Accepted before any review, contradicting the reviewer gate

**Evidence:** The template (~line 126) fixes "**Status:** Accepted" while the same file's handoff (~line 227) declares "reviewed: false". skills/reviewer-gate/SKILL.md: "No document advances to the next stage without passing this gate." The deciding agent self-accepts its own decision record pre-gate, and the template offers no Proposed/Superseded states despite "Do not introduce new layers without amending this ADR first" (~line 234) implying a lifecycle.

**Recommendation:** Template should emit **Status:** Proposed; ARCHITECTURE-REVIEWER's PASS flips it to Accepted. Add Superseded-by linkage rules for amendments.

### 6. [MEDIUM] ADR number allocation is undefined — parallel FOUNDRY items will collide on {NNN}

**Evidence:** ~line 120: "Write `doc/architecture/ADR-{NNN}-{slug}.md` (create the directory if absent)" — no rule for choosing NNN. FOUNDRY explicitly parallelises items (builder-lead decomposes into "parallelisable tasks"), and handler-architect can be spawned concurrently by builder-lead §5 and IMPLEMENT-AGENT for different items, so two spawns can both compute ADR-003.

**Recommendation:** Add a deterministic allocation rule: Glob doc/architecture/ADR-*.md, take max+1 zero-padded to 3 digits, and on a write-time collision re-scan and re-number; record the roadmap item in the filename slug to make collisions detectable.

### 7. [MEDIUM] Frontmatter omits the SUBJECT_MATTER_UNDERSTANDING contract that sibling handlers carry

**Evidence:** handler-architect.md frontmatter (~line 11) ends "Carries the SOLID covenant and the test-first mandate." Sibling handlers state the full house contract — handler-rust.md ~line 10 and handler-ansible.md ~line 10: "Carries the SOLID self-improvement covenant and the project's SUBJECT_MATTER_UNDERSTANDING." Reading the SMU file in Phase 0 is not the same as carrying the knowledge-parity contract in the agent's discoverable description.

**Recommendation:** Append "and the project's SUBJECT_MATTER_UNDERSTANDING" to the description so the contract is uniform across the VALUE_HANDLER_POOL and discoverable by the spawning orchestrator.

### 8. [LOW] Model-pin directive does not cite the canonical model-selection policy

**Evidence:** The directive (~lines 20-25) justifies `claude-opus-4-8` inline ("Architecture decisions are opus work...") but never links knowledge/policy/model-selection.md, which says "This is the single source of truth: agents reference this table instead of pinning model IDs" and explicitly carries handler-architect's exception. Sibling ds-step-1-ears.md does cite it: "Pinned to `claude-opus-4-8` per the model-selection policy ([`../knowledge/policy/model-selection.md`])".

**Recommendation:** Add the policy cross-reference to the directive blockquote so a fleet re-tier (one-table edit) reaches this file's rationale and the inspector can verify agreement mechanically.

### 9. [LOW] Spawner list is inconsistent between frontmatter and body

**Evidence:** Frontmatter (~lines 8-10) names builder-lead (§5) and IMPLEMENT-AGENT (Phase 4) only; the body (~line 27) says "spawned when the LEAD ENGINEER, IMPLEMENT-AGENT, or STORY-AGENT needs an explicit architectural pattern decision", and the ADR template (~line 129) offers "{LEAD-ENGINEER | IMPLEMENT-AGENT | STORY-AGENT}" with a matching ds-step-story-tests handoff target (~line 214).

**Recommendation:** Reconcile: either add STORY-AGENT (and the P2-9 variance route) to the frontmatter description, or remove STORY-AGENT from the body/template. The frontmatter description is what the orchestrator matches on; drift here under- or over-spawns the handler.

### 10. [SUGGESTION] Handler underuses its own architecture knowledge corpus

**Evidence:** Phase 0 (~lines 80-82) loads only clean-architecture.md, hexagonal.md, and ddd.md, yet the decision matrix adjudicates 10 patterns and the corpus at plugins/foundry/knowledge/architecture/ also contains untestable-patterns.md and pure-core.md — both directly load-bearing for the test-first mandate — plus solid.md backing the covenant. Seven of ten matrix patterns rest on parametric knowledge alone.

**Recommendation:** Add `${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/untestable-patterns.md` (anti-pattern screen for the three mandatory questions) and `pure-core.md` to the Phase 0 list; longer term, back the Event-Driven/CQRS/Microservices rows with corpus docs so matrix judgments are grounded.

## Capability-uplift proposals

### 1. Estimation-variance investigation mode (the P2-9 contract builder-lead already depends on)

**Proposal:** Add a section after Phase 1: "## Phase 1V — Estimation-Variance Investigation (spawned via builder-lead P2-9). When spawned with `estimation_basis: HIGH_VARIANCE`, do not write an ADR yet. Read `IDEA_COST.jsonl` and extract the comparable records builder-lead flagged; for each, diff the `architecture_decisions_recorded`, stack, and boundary count against the current item. Produce `doc/architecture/VARIANCE-{roadmap}.md` naming the unresolved architectural decision driving the spread (new boundary, undecided persistence, mixed patterns in comparables) or stating NONE FOUND. If a decision is unresolved, proceed to Phase 1/2 and settle it with an ADR; emit SENTINEL::ARCHITECTURE_DECIDED::ROADMAP-{N}::PASS as usual. If NONE FOUND, hand back to builder-lead with next_agent_instructions: re-estimate from the closest single comparable, not the noisy mean."

**Rationale:** builder-lead.md P2-9 routes high-variance items "to handler-architect for investigation before committing a budget", but the handler's definition has no inputs, procedure, output, or sentinel for that job — the dispatched agent improvises today.

### 2. Failure/escalation doctrine: input validation, BLOCK sentinel, and a bounded path when the spec forces an untestable boundary

**Proposal:** Add to Phase 0: "Validation preamble — if `doc/SPECIFICATION.ears.md` is absent or contains no EARS IDs, or `doc/SUBJECT_MATTER_UNDERSTANDING.md` is absent, STOP: emit SENTINEL::ARCHITECTURE_DECIDED::ROADMAP-{N}::BLOCK::{missing_input} and a handoff to the spawning agent with next_agent_instructions naming exactly which input to produce. Never invent domain facts to fill a missing SMU." Add to the Test-First Mandate: "If a `no` answer cannot be converted to `yes` by redesigning a boundary you own — because the EARS spec itself mandates the untestable shape — emit SENTINEL::REVISION::ROADMAP-{N}::ARCHITECTURE_DECIDED::NEEDS_REVISION::1::handler-architect, hand off to the orchestrator targeting ds-step-1-ears with the offending EARS IDs quoted, and stop. You may not edit the spec yourself."

**Rationale:** The handler defines only the success path; missing/malformed inputs and spec-forced untestability are the two failure modes it will actually meet, and today both end in improvisation or a caveated ADR the mandate forbids.

### 3. Architectural conformance tests (fitness functions) — the ADR's dependency rules are prose, never pinned by a test

**Proposal:** Add to the ADR template's Consequences: "### Conformance tests (mandatory). Name the stack-appropriate dependency-rule enforcer and the exact rule: Python → import-linter contract forbidding `entities` from importing `adapters`; JS/TS → eslint-plugin-boundaries or dependency-cruiser config; Rust → workspace crate separation + cargo-deny / a `#![forbid]` lint crate; JVM → ArchUnit test class. Add a Downstream instruction: 'TEST-AGENT: add the conformance test FIRST — it is the architectural coordinate; it must fail if any inner layer imports an outer one.'" Extend the test placement table with a `Conformance | {path} | static import-graph assertion` row.

**Rationale:** The handler's whole value is the dependency direction, yet nothing it emits causes that direction to be enforced; one careless downstream import silently dissolves the pattern, and no test in the five-level contract catches it.

### 4. Deterministic brownfield architecture detection before choosing a pattern

**Proposal:** Replace Phase 0 item 8 with a recipe: "## Phase 0b — Detect the incumbent pattern (brownfield). (a) Glob for layout markers: `src/domain|core|entities` + `adapters|infrastructure|ports` → Hexagonal/Clean; `models|views|controllers` or framework manifests (manage.py, Gemfile+app/, angular.json) → MVC; multiple deployable manifests (Dockerfiles, serverless configs) → service-per-deploy. (b) Grep the import direction on 5 sampled domain files: any `import`/`use` of a framework or driver inside the domain layer is evidence AGAINST an existing clean core. (c) Record the verdict (INCUMBENT: {pattern|none|violated-{pattern}}) in the ADR Context. If the incumbent contradicts your recommendation, the ADR must contain a Migration note and you must obtain LEAD ENGINEER dispensation before Status can leave Proposed."

**Rationale:** Line ~83 says "DO NOT invent a pattern that contradicts an established one" but gives no method for establishing what the established pattern IS — the single judgment most likely to differ between an opus architect and a guess.

### 5. ADR lifecycle management: numbering, status transitions, supersession, amendment

**Proposal:** Add after Phase 2: "## ADR lifecycle rules. Numbering: Glob `doc/architecture/ADR-*.md`, NNN = max existing + 1, zero-padded to 3; if the write collides (parallel item), re-scan and re-number. Status machine: emit **Proposed**; ARCHITECTURE-REVIEWER PASS → Accepted (the reviewer or orchestrator flips it, never you); a later ADR that changes the boundary sets the old one to **Superseded by ADR-{MMM}** and links both ways. Amendment: a downstream agent needing a new layer requests an amendment via the orchestrator; you append a Revision-history row and re-run the test-first checklist — an amendment that flips any checklist answer to `no` is a rejection, not a revision."

**Rationale:** The template ships a Revision-history table and the rule "Do not introduce new layers without amending this ADR first", but the handler defines no procedure for numbering, status transitions, supersession, or who may amend — so the first parallel cycle and the first amendment both go off-script.

### 6. Quality-attribute extraction from the EARS spec — consistency, latency, and audit requirements never systematically feed the matrix

**Proposal:** Add to Phase 1, before the matrix: "### Quality-attribute screen (run first, cite EARS IDs). From the EARS spec extract: (1) Transactional consistency — any requirement where two state changes must succeed or fail together; if present, Event-Driven and CQRS rows require a written transaction-boundary justification or are disqualified. (2) Latency — any response-time requirement; if p95 budgets exist, the chosen pattern must name which layer the performance tests (test placement row 5) pin them at. (3) Audit/traceability — 'system shall record/log every…' requirements favour Event-Driven or an event-sourced Repository; say so or rebut. (4) Data residency/compliance — constrains Microservices topology. The ADR's 'Why this pattern' section must show this screen's output; a pattern chosen without citing the screen is an unjustified decision."

**Rationale:** The matrix's Choose/Avoid columns mention consistency and staleness, but nothing forces the handler to mine the EARS spec for these attributes — the inputs that actually disqualify Event-Driven/CQRS — so the highest-stakes rows of the matrix are decided on vibes rather than cited requirements.
