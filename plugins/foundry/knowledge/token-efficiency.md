# Token Efficiency — the progressive-disclosure contract

Passing context to a model as tokens is a potentially wasteful operation. FOUNDRY treats
**token scarcity as a first-class constraint** and optimises for it at the agent level and
the value-handling level. This is a named pillar of waste elimination
(`pillars/waste-elimination.md`) and a hard design rule for every skill and agent.

## The three rules

### 1. Thin skills, fat references
Every `SKILL.md` is a **router**, not a library. It contains: the trigger, the station's
value, the exit gate, and a **when-to-read reference table**. The bodies of knowledge live in
`references/` (station-private) or `knowledge/` (canonical) and are loaded **only on demand**.

> A skill that inlines a 300-line reference forces every invocation to pay for it. Move the
> body out; leave a one-line pointer with a "when to read this" condition.

### 2. Define once, reference many
Canonical knowledge lives in exactly one file under `knowledge/`. Skills and agents **point**
to it via `${CLAUDE_PLUGIN_ROOT}/knowledge/...`; they never restate it. Restating knowledge
duplicates tokens *and* creates drift (two copies diverge). The deduplication of EARS, BDD,
SOLID, commit-message, test-policy, and the model policy into `knowledge/` is this rule applied.

### 3. Station-scoped loading
A subagent spawned for one station receives **only that station's references**. The
orchestrator passes the minimal context bundle:
- a TEST handler gets `knowledge/testing/` + `knowledge/specs/` — not the architecture corpus.
- an IMPLEMENT handler gets the architecture docs relevant to its decision — not the frontend
  philosophy tree.
- a reviewer gets the one artefact under review + the one role definition it embodies.

The **context sentinel** (`protocols/context-sentinel.md`) and **handoff schema**
(`protocols/handoff-schema.md`) exist precisely so an agent can reconstruct what it needs from
a compact, self-contained payload instead of replaying conversation history.

## The test
Before spawning a subagent, ask: *"What is the smallest set of references that lets this agent
reach knowledge-parity for its one task?"* Pass that. Nothing more is generosity that the
budget pays for; nothing less breaks parity. Both are defects.
