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
  composes: [market-scanner, ideator, atelier, foundry, sentinel, pressroom — by capability]
model: inherit
---

# i2p — Product lifecycle

One spine for the whole suite: **DISCOVER ① → IDEATE ② → DESIGN ③ → BUILD ④ → ASSURE ⑤ → PUBLISH ⑥ →
★ IN PRODUCTION**. The canonical model (owners, academic lineage, entry/exit signals, domain binding)
is [`../../knowledge/product-lifecycle.md`](../../knowledge/product-lifecycle.md). This skill is the
thin driver over the state file.

## Commands

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/lifecycle/scripts/lifecycle.sh status        # where are we?
bash ${CLAUDE_PLUGIN_ROOT}/skills/lifecycle/scripts/lifecycle.sh init [name]   # start at DISCOVER
bash ${CLAUDE_PLUGIN_ROOT}/skills/lifecycle/scripts/lifecycle.sh advance       # next phase
bash ${CLAUDE_PLUGIN_ROOT}/skills/lifecycle/scripts/lifecycle.sh set <PHASE>   # jump to a phase
```

State lives at `<project>/.i2p/lifecycle.json`. The `concierge` status line reads it and renders
`◆ lifecycle ●●◉○○○○ <PHASE> (n/7)`.

## Kick off a new product lifecycle

When the user wants to start (or `/i2p-help` offered and they accepted):
1. Run `lifecycle.sh init "<product name>"` (defaults to the repo folder name) — sets phase **DISCOVER**.
2. **Route to the phase owner**: DISCOVER → `/market-scan` (or `/goal` first); if they already have a
   validated idea, `set IDEATE` and route to `/ideate`. Name only the **installed** plugins; if a phase's
   owner is absent, say what installing it would unlock (graceful degradation, the marketplace pattern).
3. Tell them the status line will show the phase (offer `/concierge:statusline` if not enabled).

## Advance the lifecycle

Advance at each phase's **exit signal** (see the model doc): a kept opportunity → IDEATE; a complete IDEA
package → BUILD (via DESIGN when UI is in scope); SHIP → ASSURE; a PASS security gate → PUBLISH; release
out → IN_PRODUCTION. Either call `advance`/`set` here, or let the owning plugin advance it as it completes
its station (the documented convention; full per-plugin wiring is an incremental rollout).

## Self-improvement covenant
Inherits the i2p covenant. The phase set and signals live in one place
([`../../knowledge/product-lifecycle.md`](../../knowledge/product-lifecycle.md)); if reality drifts, fix
the model there once — this driver and the statusline widget follow.
