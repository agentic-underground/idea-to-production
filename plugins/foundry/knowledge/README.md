# FOUNDRY Knowledge — the conveyor's canonical facts

This directory is the **define-once** home for knowledge the whole conveyor obeys. Skills
and agents **reference** these files (via `${CLAUDE_PLUGIN_ROOT}/knowledge/...`); they never
restate them. If a fact lives here, there is exactly one copy of it.

> Read [`../VALUE_FLOW.md`](../VALUE_FLOW.md) to understand the *system*. Read here when you
> need a canonical *fact*.

## Which doc answers which question

| You need… | Read |
|-----------|------|
| **The philosophical spine** — the meta-principles, their bindings, *why* the system is shaped this way | [`first-principles.md`](first-principles.md) |
| Every name in the marketplace + the conceptual tree (foundry vs forge vs founder) + the **core language** (multiple bindings) | [`glossary.md`](glossary.md) |
| The three pillars, in depth | [`knowledge-parity`](pillars/knowledge-parity.md) · [`quality-first`](pillars/quality-first.md) · [`waste-elimination`](pillars/waste-elimination.md) |
| Why determinism/pinning + zero-drift templates eliminate rediscovery waste | [`pillars/determinism-and-pinning.md`](pillars/determinism-and-pinning.md) |
| The operational rules an implementer follows | [`pillars/implementation-covenant.md`](pillars/implementation-covenant.md) |
| Why/how to pass minimal context to subagents | [`token-efficiency.md`](token-efficiency.md) |
| Which model a role runs on | [`policy/model-selection.md`](policy/model-selection.md) |
| EARS requirement forms + ID rules | [`specs/ears.md`](specs/ears.md) |
| BDD/Gherkin scenario model (happy/unhappy/abuse) | [`specs/bdd-gherkin.md`](specs/bdd-gherkin.md) |
| Coverage as the floor, coverage **density**, the test pyramid + perf-delta gate, tests-as-coordinates | [`testing/test-policy.md`](testing/test-policy.md) |
| How to run coverage per stack | [`testing/coverage-commands.md`](testing/coverage-commands.md) |
| SOLID + the self-improvement covenant (halve the distance to perfection) | [`architecture/solid-covenant.md`](architecture/solid-covenant.md) |
| The SOLID *principles* reference (engineering, with examples + smell checklist) | [`architecture/solid.md`](architecture/solid.md) |
| The pure-core / one-way-dependency geometry that makes coordinates possible | [`architecture/pure-core.md`](architecture/pure-core.md) |
| Clean Architecture / Hexagonal / DDD / etc. (forms we **build with**) | [`clean-architecture`](architecture/clean-architecture.md) · [`hexagonal`](architecture/hexagonal.md) · [`ddd`](architecture/ddd.md) · [`dry-yagni`](architecture/dry-yagni.md) · [`clean-code`](architecture/clean-code.md) · [`pragmatic`](architecture/pragmatic.md) · [`twelve-factor`](architecture/twelve-factor.md) · [`untestable-patterns`](architecture/untestable-patterns.md) |
| The marketplace's **own** architecture — the deliberate hybrid (the form we **are**) | [`architecture/self-architecture.md`](architecture/self-architecture.md) |
| The certainty-marker articulation protocol (THE ONLY WAY / GUARDRAIL / ANTI-PATTERN / WORKED EXAMPLE) | [`protocols/certainty-markers.md`](protocols/certainty-markers.md) |
| The guardrails-ledger pattern (symptom → cause → fix) + FORBIDDEN lists | [`protocols/guardrails-ledger.md`](protocols/guardrails-ledger.md) |
| Machine-readable phase state between agents | [`protocols/context-sentinel.md`](protocols/context-sentinel.md) |
| Human-readable intent handoff between agents | [`protocols/handoff-schema.md`](protocols/handoff-schema.md) |
| Commit message structure (WHY/WHAT/TESTING/ROADMAP) | [`protocols/commit-message.md`](protocols/commit-message.md) |
| The Definition-of-Done template | [`protocols/definition-of-done.md`](protocols/definition-of-done.md) |
| Who merges a passing change (PR-approval vs direct-merge autonomy; always-on review) | [`protocols/merge-governance.md`](protocols/merge-governance.md) |
| The per-item lifecycle loop + routing | [`orchestration/orchestration-loop.md`](orchestration/orchestration-loop.md) |
| Priority → tier → token-budget mapping | [`orchestration/tier-assignment.md`](orchestration/tier-assignment.md) |
| All agent roles, capabilities, spawn conditions | [`orchestration/agent-roster.md`](orchestration/agent-roster.md) |
| The IDEA_COST.jsonl schema | [`orchestration/idea-cost-schema.md`](orchestration/idea-cost-schema.md) |
| The Subject-Matter-Understanding template | [`orchestration/subject-matter-understanding.md`](orchestration/subject-matter-understanding.md) |

## Layout
```
knowledge/
├── glossary.md     # every name + the conceptual-domain tree (foundry vs forge vs founder)
├── pillars/        # the three pillars + implementation-covenant + determinism-and-pinning
├── token-efficiency.md
├── policy/         # model-selection (role → model)
├── specs/          # ears, bdd-gherkin
├── testing/        # test-policy (coordinates, pyramid, perf-delta gate), coverage-commands
├── architecture/   # solid-covenant, pure-core + the quality lenses
├── protocols/      # certainty-markers, guardrails-ledger, context-sentinel, handoff-schema, commit-message, definition-of-done
└── orchestration/  # orchestration-loop, tier-assignment, agent-roster, idea-cost-schema, SMU
```
