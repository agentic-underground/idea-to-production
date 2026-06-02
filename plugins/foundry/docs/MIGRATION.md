# FOUNDRY Migration — traceability matrix (living record)

This file is the **anti-idea-drift contract**. It records, for every FORGE CODE artefact,
where it went and why; the provenance of every merged-away duplicate; and the canonical
path-rewrite map. It is updated as each migration step lands. Status legend:
☑ pending · ◐ in progress · ☑ done.

Source root: `~/.claude/` (the Forge repo). Target root: `~/.claude/plugins/foundry/`.
In moved files, every `~/.claude/...` reference is rewritten to `${CLAUDE_PLUGIN_ROOT}/...`.

---

## A · Canonical path-rewrite map (old → new)

| Old reference (`~/.claude/...`) | New (`${CLAUDE_PLUGIN_ROOT}/...`) |
|---|---|
| `skills/development-system-core/references/COMMIT_MESSAGE.md` | `knowledge/protocols/commit-message.md` |
| `skills/development-system-core/references/PRINCIPLE_PHILOSOPHY.md` | `knowledge/pillars/implementation-covenant.md` |
| `skills/development-system-core/SKILL.md` | `skills/development-system-core/SKILL.md` |
| `skills/foundry/references/definition-of-done.md` | `knowledge/protocols/definition-of-done.md` |
| `skills/foundry/references/test-policy.md` | `knowledge/testing/test-policy.md` |
| `skills/foundry/references/context-sentinel.md` | `knowledge/protocols/context-sentinel.md` |
| `skills/foundry/references/subject-matter-understanding.md` | `knowledge/orchestration/subject-matter-understanding.md` |
| `skills/foundry/references/agent-roster.md` | `knowledge/orchestration/agent-roster.md` |
| `skills/foundry/references/orchestration-loop.md` | `knowledge/orchestration/orchestration-loop.md` |
| `skills/foundry/references/tier-assignment.md` | `knowledge/orchestration/tier-assignment.md` |
| `skills/foundry/references/idea-cost-schema.md` | `knowledge/orchestration/idea-cost-schema.md` |
| `skills/foundry/references/solid-fragment.md` | `knowledge/architecture/solid-covenant.md` |
| `skills/foundry/SKILL.md` | `skills/builder/SKILL.md` |
| `skills/code_quality/SKILL.md` | `skills/code-quality/SKILL.md` |
| `skills/code_quality/references/solid.md` | `knowledge/architecture/solid-covenant.md` (merged) |
| `skills/code_quality/references/clean-architecture.md` | `knowledge/architecture/clean-architecture.md` |
| `skills/code_quality/references/hexagonal.md` | `knowledge/architecture/hexagonal.md` |
| `skills/code_quality/references/ddd.md` | `knowledge/architecture/ddd.md` |
| `skills/code_quality/references/tdd-bdd.md` | `knowledge/specs/bdd-gherkin.md` (merged) |
| `skills/code_quality/references/coverage-commands.md` | `knowledge/testing/coverage-commands.md` |
| `skills/roadmapper/references/ears-quick-reference.md` | `knowledge/specs/ears.md` |
| `skills/handoff-protocol/SKILL.md` | `skills/handoff-protocol/SKILL.md` (thin) + `knowledge/protocols/handoff-schema.md` |
| `skills/state-discovery/SKILL.md` | `skills/lifecycle-states/states/discovery.md` |
| `skills/state-specification/SKILL.md` | `skills/lifecycle-states/states/specification.md` |
| `skills/state-verification/SKILL.md` | `skills/lifecycle-states/states/verification.md` |
| `skills/state-delivery/SKILL.md` | `skills/lifecycle-states/states/delivery.md` |
| `skills/state-production-readiness/SKILL.md` | `skills/lifecycle-states/states/production-readiness.md` |
| `agents/ds-step-*.md` | `agents/ds-step-*.md` (unchanged names) |
| `agents/foundry-handler-{stack}.md` | `agents/handler-{stack}.md` |
| `agents/foundry-lead-engineer.md` | `agents/builder-lead.md` |
| `agents/development-system-orchestrator.md` | `agents/lifecycle-orchestrator.md` |
| `agents/foundry-reviewer.md` | `agents/reviewer.md` |
| `agents/development-system-reviewer.md` | merged into `agents/reviewer.md` (DOCUMENT-REVIEWER role) |
| `agents/foundry-daily-inspector.md` | `agents/inspector.md` |
| `skills/rich-pdf-with-diagrams/...` | **RELOCATED** → `pressroom` plugin (see §H) |
| `skills/writer/SKILL.md` | **RELOCATED** → `pressroom` plugin (see §H) |

---

## B · Skills (17) — disposition

| # | Source skill | Disposition | Target | Status |
|---|---|---|---|---|
| 1 | `foundry` | rename → **builder**; promote refs to `knowledge/` | `skills/builder/` | ☑ |
| 2 | `roadmapper` | move; promote `ears-quick-reference` | `skills/roadmapper/` | ☑ |
| 3 | `code_quality` | rename → **code-quality**; promote refs to `knowledge/architecture` & `testing` | `skills/code-quality/` | ☑ |
| 4 | `ideator` | move; delete duplicate `solid-fragment` | `skills/ideator/` | ☑ |
| 5 | `frontend` | move whole `resources/` tree intact | `skills/frontend/` | ☑ |
| 6 | `development-system-core` | move; promote COMMIT_MESSAGE + PRINCIPLE_PHILOSOPHY | `skills/development-system-core/` | ☑ |
| 7 | `handoff-protocol` | split: schema → `knowledge/protocols`, keep thin trigger skill | `skills/handoff-protocol/` | ☑ |
| 8 | `reviewer-gate` | move | `skills/reviewer-gate/` | ☑ |
| 9 | `phase-sensor` | move; hook → `hooks/hooks.json` | `skills/phase-sensor/` | ☑ |
| 10 | `state-discovery` | consolidate | `skills/lifecycle-states/states/discovery.md` | ☑ |
| 11 | `state-specification` | consolidate | `…/states/specification.md` | ☑ |
| 12 | `state-verification` | consolidate | `…/states/verification.md` | ☑ |
| 13 | `state-delivery` | consolidate | `…/states/delivery.md` | ☑ |
| 14 | `state-production-readiness` | consolidate | `…/states/production-readiness.md` | ☑ |
| 15 | `pii-audit` | **RELOCATED → `sentinel` plugin** (cross-cutting SECURITY, not value-carrying) | `plugins/sentinel/skills/pii-audit/` | ☑ §H |
| 16 | `writer` | **RELOCATED → `pressroom` plugin** (cross-cutting PUBLISHING) | `plugins/pressroom/skills/writer/` | ☑ §H |
| 17 | `rich-pdf-with-diagrams` | **RELOCATED → `pressroom` plugin** (cross-cutting PUBLISHING) | `plugins/pressroom/skills/rich-pdf-with-diagrams/` | ☑ §H |
| — | `hello-world-skill` | **deprecate** (template) | drop / `docs/` | ☑ |

### Seed plugin skills (resolve dual-presence)
**Refined decision:** the three seed skills are crisp, self-contained, and carry distinct
trigger phrases — dissolving them into prose would lose operational knowledge and discovery
triggers. They are KEPT as first-class FOUNDER-altitude skills; only their references are
reconciled. The spine (`VALUE_FLOW.md`) already absorbs their conceptual model; `handoff-schema`
cross-links `value-station-handoff` rather than swallowing it.

| Source | Disposition | Status |
|---|---|---|
| `plugins/foundry/skills/founder-method/` | **keep** (COO-altitude station method); reconcile refs | ☑ |
| `plugins/foundry/skills/vertical-slice/` | **keep** (slice-cutting discipline) | ☑ |
| `plugins/foundry/skills/value-station-handoff/` | **keep** (per-station input/exit contracts); cross-linked from `knowledge/protocols/handoff-schema.md` | ☑ |
| `plugins/foundry/plugin.json` | replace with `.claude-plugin/plugin.json` | ☑ |
| `plugins/foundry/examples/` | keep | ☑ |

---

## C · Agents (26) — disposition

| Source agent | Model (today) | Target | Disposition | Status |
|---|---|---|---|---|
| `founder` | inherit | `agents/founder.md` | sole COO orchestrator | ☑ |
| `foundry-lead-engineer` | inherit | `agents/builder-lead.md` | demote → cycle planner | ☑ |
| `development-system-orchestrator` | inherit | `agents/lifecycle-orchestrator.md` | demote → per-item runner | ☑ |
| `foundry-reviewer` | opus-4-7 | `agents/reviewer.md` | absorb dev-system-reviewer as a role | ☑ |
| `development-system-reviewer` | opus-4-7 | — | **MERGE** → reviewer.md (`DOCUMENT-REVIEWER`) | ☑ |
| `ds-step-0-plan` | inherit | `agents/ds-step-0-plan.md` | move; fix paths | ☑ |
| `ds-step-1-ears` | opus-4-7 | same name | move; fix paths/model | ☑ |
| `ds-step-2-feature-docs` | opus-4-7 | same name | move | ☑ |
| `ds-step-3-tests` | haiku-4-5 | same name | move | ☑ |
| `ds-step-4-first-test-run` | inherit | same name | move | ☑ |
| `ds-step-5-implementation` | inherit | same name | move; fix code-quality ref | ☑ |
| `ds-step-6-green-run` | inherit | same name | move | ☑ |
| `ds-step-7-sync` | inherit | same name | move; fix commit-message ref | ☑ |
| `ds-step-8-commit-message` | inherit | same name | move; fix commit-message ref | ☑ |
| `ds-step-9-commit-push` | inherit | same name | move | ☑ |
| `ds-step-story-tests` | opus-4-7 | same name | move | ☑ |
| `foundry-handler-architect` | opus-4-7 | `agents/handler-architect.md` | move; fix arch refs | ☑ |
| `foundry-handler-python` | inherit | `agents/handler-python.md` | move; fix test-policy ref | ☑ |
| `foundry-handler-js` | inherit | `agents/handler-js.md` | move; fix refs | ☑ |
| `foundry-handler-react` | inherit | `agents/handler-react.md` | move; fix philosophy ref | ☑ |
| `foundry-handler-fastapi` | inherit | `agents/handler-fastapi.md` | move; fix philosophy ref | ☑ |
| `foundry-handler-css` | inherit | `agents/handler-css.md` | move; fix philosophy ref | ☑ |
| `foundry-handler-playwright` | inherit | `agents/handler-playwright.md` | move | ☑ |
| *(new)* `handler-vanilla-js` | inherit | `agents/handler-vanilla-js.md` | **NEW** — native handler of the `frontend` design system; re-staffs DESIGN (6b) from `handler-react`→`handler-vanilla-js` (framework-free by mandate) | ☑ |
| `foundry-daily-inspector` | opus-4-7 | `agents/inspector.md` | move; retarget audit root | ☑ |
| `coverage-loop-agent` | haiku-4-5 | `agents/coverage-loop-agent.md` | move; fix code-quality ref | ☑ |
| `flaky-test-fixer` | sonnet-4-6 | `agents/flaky-test-fixer.md` | move | ☑ |

---

## D · Duplicates eliminated (provenance before deletion)

| Concept | Sources (all preserved knowledge merges into the survivor) | Survivor |
|---|---|---|
| SOLID **self-improvement covenant** (the replication fragment) | `skills/foundry/references/solid-fragment.md` (survivor), `skills/ideator/references/solid-fragment.md` (near-identical dup, `git rm`) | `knowledge/architecture/solid-covenant.md` |
| SOLID **principles reference** (engineering, w/ examples + smell checklist) — *kept separate; it is different knowledge, not a duplicate* | `skills/code_quality/references/solid.md` | `knowledge/architecture/solid.md` |
| Commit-message format | `skills/development-system-core/references/COMMIT_MESSAGE.md` (canonical, 354 lines), foundry SKILL §394 pointer | `knowledge/protocols/commit-message.md` |
| EARS forms | `skills/roadmapper/references/ears-quick-reference.md`, embedded foundry pipeline notes | `knowledge/specs/ears.md` |
| BDD/Gherkin model | `skills/code_quality/references/tdd-bdd.md`, ds-step-2 + state-specification embedded | `knowledge/specs/bdd-gherkin.md` |
| Test-policy/coverage | `skills/foundry/references/test-policy.md`, code_quality coverage-commands, state-verification embedded | `knowledge/testing/test-policy.md` |

**Rule:** `git mv` the survivor to its canonical path first (history preserved). Record any
merged-away copy here, then delete it. Never recreate-and-delete.

---

## E · Gaps filled (NEW canonical docs authored)

| New doc | Why (gap) | Status |
|---|---|---|
| `knowledge/policy/model-selection.md` | 17 agents pin model IDs; no single policy; pinned `opus-4-7` will age out | ☑ |
| `knowledge/token-efficiency.md` | progressive-disclosure is overarching but undocumented | ☑ |
| `knowledge/pillars/waste-elimination.md` | seven-wastes referenced but no doc | ☑ |
| `knowledge/pillars/knowledge-parity.md`, `quality-first.md` | pillars named but not formalised | ☑ |
| perf-delta gate spec (section in `testing/test-policy.md`) | gate named in manifest text, never specified | ☑ |
| `commands/*` | command surface buried in skill descriptions | ☑ |

---

## F · Meta-infra & deprecations (stay at repo root)

| Artefact | Disposition | Status |
|---|---|---|
| `ROADMAP.md`, `settings.json`, `install.sh`, `statusline-command.sh`, `doc/`, `tests/`, `.githooks/`, `CLAUDE.md`, `README.md` | stay at root (run the repo itself) | n/a |
| `FORGE_HELLO.md` | **SUNSET** — Claude Code has native subagent comms. Harvest paradigm (discovery-before-spawn; escalate-learnings-into-docs) → `VALUE_FLOW.md §2` + inspector covenant. Record in `docs/DEPRECATED.md`. | ☑ |
| `forge-sync.sh` | **SUNSET** — record in `docs/DEPRECATED.md` | ☑ |
| phase-sensor hook in root `settings.json` | harvest → `plugins/foundry/hooks/hooks.json`; verify resolves | ☑ |

---

## G · Frontmatter / trigger-phrase preservation (for consolidations)

When 5 state-* skills become one `lifecycle-states` router and 2 reviewers become one panel,
**the union of original descriptions/triggers is a requirement.** Captured originals:

- **state-discovery:** "converting IDEATOR brief intent into stable implementation intent before formal specification begins."
- **state-specification:** "formal requirement and behavior contract creation (EARS and Gherkin) before implementation."
- **state-verification:** "test-first proof, failure-gap mapping, implementation validation, and regression prevention."
- **state-delivery:** "upstream synchronization, commit narrative quality, and delivery transaction completion."
- **state-production-readiness:** "final release confidence assessment, unresolved risk disposition, and Definition Of Done certification."
- **development-system-reviewer:** "Independent critical reviewer for generated SDLC documents… covering any document produced by the Development System, not just FOUNDRY pipeline artifacts." → becomes the `DOCUMENT-REVIEWER` role on `reviewer.md`.

---

## H · Marketplace split — cross-cutting plugins extracted (2026-06)

**Decision.** The `idea-to-production` marketplace now offers **three** plugins, not one. The
governing test: *does the component carry value DOWN the conveyor (IDEA→PRODUCTION), or does it
ride ALONGSIDE the line as a cross-cutting concern?* `VALUE_FLOW.md §4` already named three
cross-cutting stations — SECURITY, PUBLISHING, DESIGN. Two of them were extracted into their own
plugins; DESIGN (`frontend`) was kept in foundry because it *is* an on-line station (6b).

| Extracted to | Components moved out of foundry | Why |
|---|---|---|
| **`sentinel`** (security) | `skills/pii-audit/`, `commands/pii-audit.md` | PII/secret scanning is a pre-release gate, not a value-carriage step. Expanded with secret-scan, dependency-audit, and a consolidated `/security-gate`. |
| **`pressroom`** (publishing) | `skills/writer/`, `skills/rich-pdf-with-diagrams/` | foundry's value artefact is **markdown**; articles/diagrams/PDF are an optional enrichment. Expanded with `diagram-studio` and `/publish`. |

**Graceful-enhancement contract.** foundry no longer hard-references these by
`${CLAUDE_PLUGIN_ROOT}` path (which would break across a plugin boundary). Instead it refers to
them **by capability** — "if the `sentinel`/`pressroom` plugin is installed, hand off to its
skill; otherwise deliver markdown and note the step was skipped." See `VALUE_FLOW.md §4, §10`.

**Provenance of the relocated files** is the same as their pre-split state (rows 15–17 above and
the path-rewrite map); the files moved verbatim. Cross-plugin path repairs done at relocation:
- `pressroom`: `writer` ↔ `rich-pdf-with-diagrams` are now in the same plugin → their mutual
  `${CLAUDE_PLUGIN_ROOT}/skills/...` references remain valid and were kept.
- `pressroom`: `writer`'s former reference to foundry's
  `knowledge/protocols/commit-message.md` was replaced with a self-contained
  `skills/writer/references/commit-format.md` so pressroom never assumes foundry is installed.
