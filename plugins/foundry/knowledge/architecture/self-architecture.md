# The marketplace's OWN architecture — a deliberate hybrid

> **Two architectures, do not confuse them.** This doc is about **the form we *are*** — how the
> `idea-to-production` marketplace and its plugins are themselves structured. It is **not** about the
> form we tell projects to *build with*. Hexagonal/ports-and-adapters is a **design choice for the
> software FOUNDRY builds** ([`hexagonal.md`](hexagonal.md)); the marketplace's *own* shape is the
> **hybrid** named below. Choosing one form for everything would be a category error — different
> layers have genuinely different jobs.

The marketplace is **three forms, each used where it fits**:

## 1. Pure-core / hexagonal — the `knowledge/` layer  ·  *excellent fit*

`knowledge/` is the **decidable core**: canonical facts that carry **no inbound logical dependency** on
agent or skill *behaviour* — no agent's logic leaks into a fact. Agents and skills depend **inward** on
it (`${CLAUDE_PLUGIN_ROOT}/knowledge/...`). Knowledge docs *do* carry a few **navigational** pointers
out (e.g. "the roster lives in `agents/...`", "merge governance gates `skills/pr-review`") — those are
reader-wayfinding references, **not dependency edges**: nothing in a fact's *content* is decided by an
agent. This is the pure-core geometry ([`pure-core.md`](pure-core.md)) read at the documentation level —
and it is why the one-copy rule ([`../README.md`](../README.md)) holds: a fact lives in exactly one
place, and everything references it. **This layer reads as hexagonal**, with knowledge as the core and
skills/agents as adapters.

## 2. Ports-and-adapters — plugin composition  ·  *excellent fit*

At the marketplace level the plugins compose as ports-and-adapters:
- **foundry** is the core capability.
- **secure** (SECURITY) and **publish** (PUBLISHING) are optional **driven ports**, referenced
  **by capability, never by cross-plugin path**, and degrade gracefully when absent.
- **commands** and **hooks** are **driving ports** (user/automation entry points); the Claude tools
  (Bash, Read/Write, MCP, LSP) are **driven adapters** to the outside world.

This is a clean hexagon, and it is *why* graceful enhancement works.

## 3. Pipeline / hierarchical-orchestration — the agent conveyor  ·  *correct, and NOT hexagonal*

The agent conveyor is a **chain of command**, not a hexagon:

```
founder (COO) → builder-lead (cycle planner) → lifecycle-orchestrator (per-item)
   → ds-step-* / handler-* (station workers) → reviewer (gate, by role)
```

> **ANTI-PATTERN (DO NOT):** Do not try to "make the orchestration hexagonal." Hexagonal is the **wrong
> lens** here — these agents are **not substitutable adapters behind a port**; they are **stations on a
> pipeline**, each with an **input contract**, a **transformation**, and a mandatory **exit
> certificate** (a context sentinel), passing value **down** the line while questions flow **up**. The
> right names for this form are **Pipeline / Pipes-and-Filters** and **hierarchical orchestration**.
> Forcing adapter-substitutability onto a command chain would destroy the very sequencing and gating
> that make the conveyor trustworthy. **It is correct as-is; naming it prevents false "refactor to
> hexagonal" churn.**

Why a pipeline and not a hexagon: a station's *order* and its *gate* are load-bearing (you cannot run
TEST before EARS; you cannot SHIP before the review PASSes). Substitutability is meaningless for a step
whose whole value is *being that step, in that place, with that exit certificate*.

## The two altitudes map onto the forms

This is also where the **two altitudes** ([`../first-principles.md`](../first-principles.md) §7) live:
the **workers** (handlers, `ds-step-*`) are the pipeline's filters — pragmatic, pattern-precise,
ledger-keeping; the **orchestrators** (`founder`/`builder-lead`/`lifecycle`/`reviewer`) sequence and
gate them — aligned by the shared philosophy and language. Knowledge (form 1) is the pure core both
altitudes read; composition (form 2) is how the whole thing plugs into a user's session.

## The one real drift to fix

> **GUARDRAIL — knowledge-restatement-in-agents.** The hexagonal `knowledge/` core only stays pure if
> agents **reference** it, not **restate** it. Some agents still embed *summarised copies* of canon
> (e.g. model-tier prose, the test contract) — a reverse dependency that drifts. The fix is
> reference-with-a-certainty-marker, not a pasted table. This is a recurring `inspector` finding — and
> the **standing target** for the `/foundry:self-improve` skill. It is the only place the
> marketplace's own form is violated rather than merely different.

## Summary

| Layer | Form | Fit |
|---|---|---|
| `knowledge/` | pure-core / hexagonal (core) | excellent |
| plugin composition | ports-and-adapters | excellent |
| agent conveyor | pipeline / hierarchical-orchestration | correct (hexagonal is the wrong lens) |
| (drift) agents restating knowledge | reverse edge into the core | the one thing to fix |
