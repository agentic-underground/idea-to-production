---
name: canvas-write-conflict
description: When two parallel Round-1 items both need to modify canvas.js, assign canvas.js exclusively to one agent and defer the other's canvas wiring to Round 2
metadata:
  type: feedback
---

In epic [27] planning, items [28] (detail panel) and [29] (drag columns + WS) both needed canvas.js changes (panel click handler and drag/WS respectively). Running both agents concurrently on canvas.js would produce write conflicts.

**Why:** canvas.js is a single large module with shared closure state (`items`, `positions`, `transform`). Two agents writing to it simultaneously cannot reliably produce a merged result without conflict.

**How to apply:** When a round has two parallel items both touching the same large module:
1. Assign ownership of that module to exactly one agent (the one with the deeper integration need)
2. The other agent writes only its own new files; its module-wiring step is deferred to Round 2 (the first step of whichever dependent item comes next)
3. Document the deferral explicitly in the Resumption Instructions

In epic [27]: [29] owns canvas.js drag/WS; [28]'s card-click wiring into canvas.js was deferred to [30]'s Round 2 first step.
