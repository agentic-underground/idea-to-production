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
bash ${CLAUDE_PLUGIN_ROOT}/skills/lifecycle/scripts/lifecycle.sh done <PHASE>  # mark PHASE done → next (order-safe)
bash ${CLAUDE_PLUGIN_ROOT}/skills/lifecycle/scripts/lifecycle.sh advance       # next phase (unconditional)
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

Advancement is **wired into each owning plugin**: when a station completes it calls
`/i2p-lifecycle done <its-phase>` (by capability — only when i2p is installed). `done <PHASE>` is
**order-safe and idempotent** — it advances to the next phase *only if* the lifecycle is currently at
`<PHASE>`, and is a silent no-op otherwise (or when no lifecycle is running), so a plugin can never jump
the lifecycle out of order or auto-start it. The exit signal → `done` mapping:

| Owner | Marks done | → advances to |
|---|---|---|
| market-scanner (kept OPPORTUNITY) | `done DISCOVER` | IDEATE |
| ideator (IDEA package handed off) | `done IDEATE` | DESIGN |
| atelier (design phase concluded) | `done DESIGN` | BUILD |
| foundry (item SHIPs / COMPLETE) | `done BUILD` | ASSURE |
| sentinel (security gate PASS) | `done ASSURE` | PUBLISH |
| pressroom (publication out) | `done PUBLISH` | IN_PRODUCTION |

You can also drive it by hand here with `done`/`advance`/`set`.

## Self-improvement covenant
Inherits the i2p covenant. The phase set and signals live in one place
([`../../knowledge/product-lifecycle.md`](../../knowledge/product-lifecycle.md)); if reality drifts, fix
the model there once — this driver and the statusline widget follow.
