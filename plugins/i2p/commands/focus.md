---
description: Declare the active lifecycle PHASE for context routing — out-of-phase skills stay dormant ("focus, don't uninstall"). Writes .i2p/focus; a SessionStart hook broadcasts it (survives /clear). Best-effort steering, not a hard gate.
---

Set, report, or clear the repo's FOCUS. Follow the [`focus` skill](../skills/focus/SKILL.md):

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/focus/scripts/focus.sh $ARGUMENTS
```

- no args / `status` → report the current FOCUS (or that none is set).
- `<PHASE>` → set the active phase (DISCOVER · IDEATE · DELIVER · DESIGN · BUILD · ASSURE · SECURE ·
  PUBLISH · OPERATE), optionally followed by a free-text note. Out-of-phase skills are then steered
  dormant on the next session start / resume / clear; `cross-cut` skills stay available; out-of-phase
  skills remain reachable by their explicit `/command`.
- `off` → clear the FOCUS (every skill available again).

The active phase is broadcast by the `focus-routing.sh` SessionStart hook, so it **survives `/clear`**.
See [`../../../docs/guide/context-routing.md`](../../../docs/guide/context-routing.md) §4 (the C2
phase-gate) and [`../../../docs/guide/lexicon.md`](../../../docs/guide/lexicon.md).
