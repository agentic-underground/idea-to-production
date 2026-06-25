---
name: lifecycle
description: >
  Start and report the idea-to-production PRODUCT LIFECYCLE for a project. Use for /i2p:lifecycle
  (or "start a product lifecycle", "what phase are we in?", "kick off idea-to-production",
  "advance the lifecycle"). Reads/writes .i2p/lifecycle.json via scripts/lifecycle.sh and
  explains the model from knowledge/product-lifecycle.md. The statusline phase widget reads the
  same state file.
metadata:
  type: orchestrator
  output: .i2p/lifecycle.json (current_phase + history) + a phase report
  composes: [discover, ideate, foundry:roadmapper + FLEET engine (DELIVER), atelier, foundry, security, publish, operate — by capability]
model: inherit
---

# i2p — Product lifecycle

One spine for the whole suite — **nine phases that form a cycle**: **DISCOVER ① → IDEATE ② → DELIVER ③ →
DESIGN ④ → BUILD ⑤ ⇄ ASSURE ⑥ ⇄ SECURE ⑦ → PUBLISH ⑧ → OPERATE ⑨ ↻**. **DELIVER** (between IDEATE and
DESIGN, owned by `foundry:roadmapper` + the external FLEET engine) turns the IDEA package into a dependency-ordered
roadmap. The three realisation phases **BUILD ⇄ ASSURE ⇄ SECURE** form a **loop** — a failed quality or
security gate re-enters BUILD (the `fail` back-edge), and the loop exits to PUBLISH only when all three are
satisfied. ASSURE (quality) and SECURE (security) are **separate first-class gates**; OPERATE is the
living-in-production phase whose learnings loop back to DISCOVER. The canonical model (owners, the three
cross-cutting concerns, academic lineage, entry/exit signals, domain binding) is
[`../../knowledge/product-lifecycle.md`](../../knowledge/product-lifecycle.md). This skill is the thin
driver over the state file.

## Commands

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/lifecycle/scripts/lifecycle.sh status              # where are we?
bash ${CLAUDE_PLUGIN_ROOT}/skills/lifecycle/scripts/lifecycle.sh init [name]         # start at DISCOVER
bash ${CLAUDE_PLUGIN_ROOT}/skills/lifecycle/scripts/lifecycle.sh done <PHASE>        # mark PHASE done → next (order-safe)
bash ${CLAUDE_PLUGIN_ROOT}/skills/lifecycle/scripts/lifecycle.sh fail <ASSURE|SECURE> # loop back-edge: failed gate → re-enter BUILD (loop_pass++)
bash ${CLAUDE_PLUGIN_ROOT}/skills/lifecycle/scripts/lifecycle.sh advance             # next phase (unconditional)
bash ${CLAUDE_PLUGIN_ROOT}/skills/lifecycle/scripts/lifecycle.sh set <PHASE>         # jump to a phase
```

State lives at `<project>/.i2p/lifecycle.json` — `current_phase` plus the additive **loop fields**
`loop_state` (the live BUILD/ASSURE/SECURE position) and `loop_pass` (the loop iteration count), written
by `done`/`fail`. The i2p status line reads it and renders `◆ lifecycle ●●◉○○○○○○ <PHASE> (n/9)`, marking
the loop with a `⇄` (and `⇄ ×N` for the iteration) while in BUILD/ASSURE/SECURE.

## Token-cost & estimate↔actual calibration

`init` seeds calibration-aware per-phase **token estimates**; `done <PHASE>` folds that phase's
**actual-vs-estimate** into a global calibration ledger so estimates self-correct over time. Actuals are
measured automatically by i2p's `capture-cost.sh` Stop hook (`.i2p/cost.json`); the status line
shows `◇ … session` and `◈ life actual/~estimate (Δ%) · $`. Report cost with:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/lifecycle/scripts/cost.sh report <dir>
```

When reporting lifecycle status, also run `cost.sh report` and summarise spend + estimation accuracy.
Full model + schema: [`../../knowledge/instrumentation.md`](../../knowledge/instrumentation.md).

## Kick off a new product lifecycle

When the user wants to start (or `/i2p:help` offered and they accepted):
1. Run `lifecycle.sh init "<product name>"` (defaults to the repo folder name) — sets phase **DISCOVER**.
2. **Route to the phase owner**: DISCOVER → `/market-scan` (or `/discovery-goal` first); if they already have a
   validated idea, `set IDEATE` and route to `/ideate`. Name only the **installed** plugins; if a phase's
   owner is absent, say what installing it would unlock (graceful degradation, the marketplace pattern).
3. Tell them the status line will show the phase (offer `/i2p:statusline` if not enabled).

## Advance the lifecycle

Advancement is **wired into each owning plugin**: when a station completes it calls
`/i2p:lifecycle done <its-phase>` (by capability — only when i2p is installed). `done <PHASE>` is
**order-safe and idempotent** — it advances to the next phase *only if* the lifecycle is currently at
`<PHASE>`, and is a silent no-op otherwise (or when no lifecycle is running), so a plugin can never jump
the lifecycle out of order or auto-start it. The exit signal → `done` mapping:

| Owner | Marks done | → advances to |
|---|---|---|
| discover (kept OPPORTUNITY, challenger upholds) | `done DISCOVER` | IDEATE |
| ideate (IDEA package handed off, challenger READY) | `done IDEATE` | DELIVER |
| `foundry:roadmapper` + FLEET engine (dependency-ordered v2 pipeline of build-ready items) | `done DELIVER` | DESIGN |
| atelier (design phase concluded) | `done DESIGN` | BUILD *(loop entry)* |
| foundry (item SHIPs — tests green, story proven) | `done BUILD` | ASSURE *(loop)* |
| foundry (adversarial quality review PASS — `/pr-review`) | `done ASSURE` | SECURE *(loop)* |
| security (scan-all PASS — all three satisfied) | `done SECURE` | PUBLISH *(loop exit)* |
| publish (publication out) | `done PUBLISH` | OPERATE |
| operate (operate learning → next cycle) | `done OPERATE` | DISCOVER ↻ |

**The loop back-edge — `fail <ASSURE|SECURE>`.** Distinct from `done`: a failed quality (ASSURE) or
security (SECURE) gate does **not** advance — it re-enters **BUILD**, sets `loop_state` back to BUILD, and
increments `loop_pass` (the iteration is recorded in history). The owner of the failing gate calls
`fail <its-gate>` instead of `done`. Like `done` it is order-safe (a no-op unless the lifecycle is at that
gate) and rejects a non-gate argument. So BUILD ⇄ ASSURE ⇄ SECURE iterate until the work is simultaneously
shipped, quality-certified, and security-certified, then `done SECURE` exits the loop to PUBLISH.

You can also drive it by hand here with `done`/`fail`/`advance`/`set`.

**Keep the welcome in step (by capability).** After advancing — and only when i2p is
installed and the repo has a `.claude/welcome.md` — run `/i2p:define-welcome refresh` so the repo's
front door reflects the new phase's emergent identity. Silent and order-safe; degrades to nothing when
the welcome surface is absent. (i2p also auto-detects a stale welcome on the next SessionStart via its
`offer-welcome.sh` hook, so this is a same-session liveness nicety, not the only path.)

## Self-improvement covenant
Inherits the i2p covenant. The phase set and signals live in one place
([`../../knowledge/product-lifecycle.md`](../../knowledge/product-lifecycle.md)); if reality drifts, fix
the model there once — this driver and the statusline widget follow.
