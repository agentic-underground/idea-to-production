---
name: lifecycle
description: >
  Start and report the idea-to-production PRODUCT LIFECYCLE for a project. Use for /i2p-lifecycle
  (or "start a product lifecycle", "what phase are we in?", "kick off idea-to-production",
  "advance the lifecycle"). Reads/writes .i2p/lifecycle.json via scripts/lifecycle.sh and
  explains the model from knowledge/product-lifecycle.md. The statusline phase widget reads the
  same state file.
metadata:
  type: orchestrator
  output: .i2p/lifecycle.json (current_phase + history) + a phase report
  composes: [market-scanner, ideator, atelier, foundry, sentinel, pressroom, mission-control — by capability]
model: inherit
---

# i2p — Product lifecycle

One spine for the whole suite — **eight phases that form a cycle**: **DISCOVER ① → IDEATE ② → DESIGN ③ →
BUILD ④ → ASSURE ⑤ → SECURE ⑥ → PUBLISH ⑦ → OPERATE ⑧ ↻**. ASSURE (quality) and SECURE (security) are
**separate first-class gates**; OPERATE is the living-in-production phase whose learnings loop back to
DISCOVER. The canonical model (owners, the three cross-cutting concerns, academic lineage, entry/exit
signals, domain binding) is
[`../../knowledge/product-lifecycle.md`](../../knowledge/product-lifecycle.md). This skill is the thin
driver over the state file.

## Commands

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/lifecycle/scripts/lifecycle.sh status        # where are we?
bash ${CLAUDE_PLUGIN_ROOT}/skills/lifecycle/scripts/lifecycle.sh init [name]   # start at DISCOVER
bash ${CLAUDE_PLUGIN_ROOT}/skills/lifecycle/scripts/lifecycle.sh done <PHASE>  # mark PHASE done → next (order-safe)
bash ${CLAUDE_PLUGIN_ROOT}/skills/lifecycle/scripts/lifecycle.sh advance       # next phase (unconditional)
bash ${CLAUDE_PLUGIN_ROOT}/skills/lifecycle/scripts/lifecycle.sh set <PHASE>   # jump to a phase
```

State lives at `<project>/.i2p/lifecycle.json`. The `concierge` status line reads it and renders
`◆ lifecycle ●●◉○○○○○ <PHASE> (n/8)`.

## Token-cost & estimate↔actual calibration

`init` seeds calibration-aware per-phase **token estimates**; `done <PHASE>` folds that phase's
**actual-vs-estimate** into a global calibration ledger so estimates self-correct over time. Actuals are
measured automatically by `concierge`'s `capture-cost.sh` Stop hook (`.i2p/cost.json`); the status line
shows `◇ … session` and `◈ life actual/~estimate (Δ%) · $`. Report cost with:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/lifecycle/scripts/cost.sh report <dir>
```

When reporting lifecycle status, also run `cost.sh report` and summarise spend + estimation accuracy.
Full model + schema: [`../../knowledge/instrumentation.md`](../../knowledge/instrumentation.md).

## Kick off a new product lifecycle

When the user wants to start (or `/i2p-help` offered and they accepted):
1. Run `lifecycle.sh init "<product name>"` (defaults to the repo folder name) — sets phase **DISCOVER**.
2. **Route to the phase owner**: DISCOVER → `/market-scan` (or `/discovery-goal` first); if they already have a
   validated idea, `set IDEATE` and route to `/ideate`. Name only the **installed** plugins; if a phase's
   owner is absent, say what installing it would unlock (graceful degradation, the marketplace pattern).
3. Tell them the status line will show the phase (offer `/concierge:statusline` if not enabled).

## Advance the lifecycle

Advancement is **wired into each owning plugin**: when a station completes it calls
`/i2p-lifecycle done <its-phase>` (by capability — only when i2p is installed). `done <PHASE>` is
**order-safe and idempotent** — it advances to the next phase *only if* the lifecycle is currently at
`<PHASE>`, and is a silent no-op otherwise (or when no lifecycle is running), so a plugin can never jump
the lifecycle out of order or auto-start it. The exit signal → `done` mapping:

| Owner | Marks done | → advances to |
|---|---|---|
| market-scanner (kept OPPORTUNITY, challenger upholds) | `done DISCOVER` | IDEATE |
| ideator (IDEA package handed off, challenger READY) | `done IDEATE` | DESIGN |
| atelier (design phase concluded) | `done DESIGN` | BUILD |
| foundry (item SHIPs — tests green, story proven) | `done BUILD` | ASSURE |
| foundry (adversarial quality review PASS — `/pr-review`) | `done ASSURE` | SECURE |
| sentinel (security-gate PASS) | `done SECURE` | PUBLISH |
| pressroom (publication out) | `done PUBLISH` | OPERATE |
| mission-control (operate learning → next cycle) | `done OPERATE` | DISCOVER ↻ |

You can also drive it by hand here with `done`/`advance`/`set`.

**Keep the welcome in step (by capability).** After advancing — and only when the `concierge` plugin is
installed and the repo has a `.claude/welcome.md` — run `/concierge:define-welcome refresh` so the repo's
front door reflects the new phase's emergent identity. Silent and order-safe; degrades to nothing when
concierge is absent. (CONCIERGE also auto-detects a stale welcome on the next SessionStart via its
`offer-welcome.sh` hook, so this is a same-session liveness nicety, not the only path.)

## Self-improvement covenant
Inherits the i2p covenant. The phase set and signals live in one place
([`../../knowledge/product-lifecycle.md`](../../knowledge/product-lifecycle.md)); if reality drifts, fix
the model there once — this driver and the statusline widget follow.
