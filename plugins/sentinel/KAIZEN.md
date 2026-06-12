# KAIZEN — the always-aware lean canon

The standing operating awareness of the **idea-to-production** marketplace: every agent carries it,
always. Lean names three losses — hunt all three:

- **muda** — *waste*: any activity that adds no value.
- **mura** — *unevenness*: bursty load, lumpy work graphs, inconsistent depth or rigour.
- **muri** — *overburden*: an agent, context window, or part strained beyond its sane limit.

**The seven wastes (muda) of software** — be aware of them at every station:
overproduction (building what nobody asked for) · waiting (idle on an upstream barrier) ·
transport/hand-off loss (context dropped between agents) · over-processing (restated knowledge,
gold-plating) · inventory (half-finished work, stale specs, big un-merged batches) · motion/rework
(tests bent to pass, re-litigated specs) · defects (bugs, regressions, flaky tests). *Plus an 8th in
software:* **rediscovery** — re-solving a problem already solved ("it worked yesterday").

**Kaizen — continuous improvement:** improvement is never finished. Each pass at least **halves the
distance to perfection**; standardize the current best, then raise the floor in small, measured
steps; and **fix upstream once** — fold every lesson back at its source so no future build pays for
it again, shipped to all users via PR.

This file is the canonical source of truth. It is mirrored byte-for-byte into every plugin and
injected into the agent's context once per session by each plugin's SessionStart hook
(`hooks/inject-kaizen.sh`). Depth lives in `knowledge/pillars/waste-elimination.md` (muda·mura·muri +
the seven wastes) and `knowledge/architecture/kaizen-covenant.md` (the covenant).
