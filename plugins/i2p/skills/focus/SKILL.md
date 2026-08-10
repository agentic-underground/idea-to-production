---
name: focus
description: >
  Declare the active lifecycle PHASE so out-of-phase skills stay dormant — the "focus, don't uninstall"
  answer to context-pollution. Trigger with /i2p:focus (or "focus on DISCOVER", "set focus to build",
  "clear focus", "what's my focus?"). Writes .i2p/focus; a SessionStart hook broadcasts it (survives
  /clear). Best-effort steering, not a hard gate. → .i2p/focus + a per-session directive.
metadata:
  phase: [cross-cut]
  type: producer
  output: .i2p/focus (the active-phase declaration) + a SessionStart FOCUS injection
model: inherit
---

# i2p — FOCUS (the context-routing phase-gate, C2)

When several plugins are installed, their skill descriptions all sit in the agent's attention — even the
phases you are not working in. **FOCUS** lets you declare the active phase once, and the marketplace
treats out-of-phase skills as dormant until you change focus. You don't uninstall; you focus. It is the
C2 layer of [`context-routing.md`](../../../../docs/guide/context-routing.md) §4.

## How it works

1. **Set** — `/i2p:focus <PHASE>` writes `.i2p/focus` (`phase: <PHASE>`, one of the nine lifecycle
   phases). `/i2p:focus off` clears it; `/i2p:focus` (or `status`) reports it.
2. **Broadcast** — the `focus-routing.sh` SessionStart hook reads `.i2p/focus` and injects one FOCUS
   directive into context (re-fired on `resume`/`clear`/`compact`, so it **survives `/clear`**). Absent
   file → no injection (every skill available, today's behaviour).
3. **Apply** — the directive states the gate rule: a skill is **dormant iff FOCUS ∉ (its
   `metadata.phase` ∪ {cross-cut})**. `cross-cut` skills stay available; an untagged skill **fails open**
   (available). Out-of-phase skills are still reachable by their explicit `/command`.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/focus/scripts/focus.sh $ARGUMENTS
```

> **Steering, not a gate.** This *lowers* the chance of an out-of-phase skill firing; it does not
> mechanically prevent it (the descriptions remain in context). The only deterministic version would be
> a `PreToolUse` deny-hook — recorded as a future option in `context-routing.md` §4.4. Composes with
> `deliver:phase-sensor` (which detects the *within-BUILD sub-phase*); FOCUS declares the *lifecycle*
> phase and outranks detection when set.

Carries the KAIZEN self-improvement covenant ([`../../knowledge/covenant.md`](../../knowledge/covenant.md)).
