# FOUNDRY Knowledge — the conveyor's canonical facts

This directory is the **define-once** home for knowledge the whole conveyor obeys. Skills
and agents **reference** these files (via `${CLAUDE_PLUGIN_ROOT}/knowledge/...`); they never
restate them. If a fact lives here, there is exactly one copy of it.

> Read [`../VALUE_FLOW.md`](../VALUE_FLOW.md) to understand the *system*. Read here when you
> need a canonical *fact*.

## Which doc answers which question

| You need… | Read |
|-----------|------|
| The three pillars, in depth | `pillars/{knowledge-parity,quality-first,waste-elimination}.md` |
| Why determinism/pinning + zero-drift templates eliminate rediscovery waste | `pillars/determinism-and-pinning.md` |
| The operational rules an implementer follows | `pillars/implementation-covenant.md` |
| Why/how to pass minimal context to subagents | `token-efficiency.md` |
| Which model a role runs on | `policy/model-selection.md` |
| EARS requirement forms + ID rules | `specs/ears.md` |
| BDD/Gherkin scenario model (happy/unhappy/abuse) | `specs/bdd-gherkin.md` |
| The coverage mandate, test pyramid, perf-delta gate | `testing/test-policy.md` |
| How to run coverage per stack | `testing/coverage-commands.md` |
| SOLID + the self-improvement covenant | `architecture/solid-covenant.md` |
| The pure-core / one-way-dependency geometry that makes coordinates possible | `architecture/pure-core.md` |
| Clean Architecture / Hexagonal / DDD / etc. | `architecture/{clean-architecture,hexagonal,ddd,dry-yagni,clean-code,pragmatic,twelve-factor,untestable-patterns}.md` |
| The certainty-marker articulation protocol (THE ONLY WAY / GUARDRAIL / ANTI-PATTERN / WORKED EXAMPLE) | `protocols/certainty-markers.md` |
| The guardrails-ledger pattern (symptom → cause → fix) + FORBIDDEN lists | `protocols/guardrails-ledger.md` |
| Machine-readable phase state between agents | `protocols/context-sentinel.md` |
| Human-readable intent handoff between agents | `protocols/handoff-schema.md` |
| Commit message structure (WHY/WHAT/TESTING/ROADMAP) | `protocols/commit-message.md` |
| The Definition-of-Done template | `protocols/definition-of-done.md` |
| The per-item lifecycle loop + routing | `orchestration/orchestration-loop.md` |
| Priority → tier → token-budget mapping | `orchestration/tier-assignment.md` |
| All agent roles, capabilities, spawn conditions | `orchestration/agent-roster.md` |
| The IDEA_COST.jsonl schema | `orchestration/idea-cost-schema.md` |
| The Subject-Matter-Understanding template | `orchestration/subject-matter-understanding.md` |

## Layout
```
knowledge/
├── pillars/        # the three pillars + implementation-covenant + determinism-and-pinning
├── token-efficiency.md
├── policy/         # model-selection (role → model)
├── specs/          # ears, bdd-gherkin
├── testing/        # test-policy (coordinates, pyramid, perf-delta gate), coverage-commands
├── architecture/   # solid-covenant, pure-core + the quality lenses
├── protocols/      # certainty-markers, guardrails-ledger, context-sentinel, handoff-schema, commit-message, definition-of-done
└── orchestration/  # orchestration-loop, tier-assignment, agent-roster, idea-cost-schema, SMU
```
