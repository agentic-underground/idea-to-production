---
id: 101
title: "Lifecycle state-machine rework — loop-aware lifecycle.sh + json schema"
status: PENDING
priority: HIGH
added: 2026-06-17
depends_on: "#100"
---

# [101] Lifecycle state-machine rework — loop-aware lifecycle.sh + json schema

**Brief Description**
Rework the lifecycle state machine to implement the v2 model defined in #100: add the **DELIVER**
phase and make **BUILD ⇄ ASSURE ⇄ SECURE a native loop** — re-enter BUILD when ASSURE or SECURE
fails, advance to PUBLISH only when all three pass. The phase sequence is hard-coded as a `PHASES=`
string in `plugins/i2p/skills/lifecycle/scripts/lifecycle.sh` (line 18) and `cost.sh` (line 25), with
`next_phase`, `advance`, and `done` walking that flat string and wrapping LAST→FIRST. This is a
**full state-machine rework** — native loop states for B/A/S, **not** a counter bolt-on — and an
**additive** extension of `.i2p/lifecycle.json` with loop fields (e.g. `loop_pass`, `loop_state`).

### User Stories
- AS a builder I WANT `lifecycle.sh advance`/`done` to know about DELIVER and the B/A/S loop SO THAT
  the phase the state file reports matches the v2 model exactly, including looping back to BUILD on a
  failed gate.
- AS an owner plugin (foundry on an ASSURE/SECURE fail) I WANT a way to signal "this gate failed" SO
  THAT the lifecycle re-enters BUILD instead of advancing — the loop's back-edge is a first-class
  transition, not a manual `set`.
- AS a maintainer I WANT the new schema to be additive SO THAT existing `.i2p/lifecycle.json` files
  and the cost calibration keep working.

### EARS Specification
**Ubiquitous**
- `PHASES` in both `lifecycle.sh` and `cost.sh` SHALL encode the nine-phase v2 order
  (DISCOVER IDEATE DELIVER DESIGN BUILD ASSURE SECURE PUBLISH OPERATE), and `cost.sh`'s `base_for`
  SHALL carry a seed estimate for DELIVER.
- The state machine SHALL model BUILD/ASSURE/SECURE as **native loop states** (a loop sub-state
  machine), not as a counter appended to a flat linear walk.
- `.i2p/lifecycle.json` SHALL gain loop fields (e.g. `loop_state` ∈ {BUILD,ASSURE,SECURE} and
  `loop_pass` for the iteration count) **additively** — a file without them SHALL still load and
  read as a valid (pre-loop) state.

**Event-driven**
- WHEN the lifecycle is in the loop and ASSURE or SECURE reports a **failure** THE state machine SHALL
  transition `loop_state` back to BUILD (the loop back-edge) and record the iteration.
- WHEN BUILD, ASSURE, and SECURE are all satisfied THE `advance`/`done` transition out of SECURE SHALL
  go to PUBLISH (the loop exit), not back into the loop.
- WHEN `done DELIVER` (or `advance` from DELIVER) is issued at DELIVER THE state machine SHALL move to
  DESIGN.
- WHEN OPERATE wraps THE state machine SHALL still re-enter DISCOVER and bump `cycle` (the OPERATE↻
  behaviour is preserved).

**Unwanted behaviour**
- IF the loop is implemented as a `done`-counter hack bolted onto the existing flat `next_phase` walk
  THEN that is a defect — the rework SHALL use native loop states per #100.
- IF a pre-v2 `.i2p/lifecycle.json` (8-phase, no loop fields) is loaded THEN the tool SHALL NOT crash
  or clobber it; it SHALL read safely and the existing corrupt-vs-not-started distinction SHALL be
  preserved.
- IF jq is absent THEN writes SHALL still degrade with a clear message exactly as today (no new hard
  jq dependency on the read paths).

### Acceptance Criteria
1. Given `lifecycle.sh` and `cost.sh`, When inspected, Then `PHASES` is the nine-phase v2 string and
   `cost.sh base_for` returns a non-zero seed for DELIVER.
2. Given a lifecycle in the BUILD/ASSURE/SECURE loop, When an ASSURE or SECURE failure is signalled,
   Then `.i2p/lifecycle.json` `loop_state` is set back to BUILD and the iteration is recorded — the
   current_phase does not advance to PUBLISH.
3. Given a lifecycle where BUILD, ASSURE, and SECURE are all satisfied, When the SECURE transition
   fires, Then current_phase advances to PUBLISH.
4. Given a fresh `init`, When the state file is written, Then it includes the nine phases plus the new
   loop fields; given a legacy 8-phase file, When read, Then `get`/`status` succeed without error.
5. Given `init`, When run, Then the cost estimator seeds DELIVER alongside the other phases.

### Implementation Notes
- Implements the canonical model from #100 — read it for the exact phase order, DELIVER's
  entry/exit, and the loop's exit signal ("all three satisfied").
- Touch `plugins/i2p/skills/lifecycle/scripts/lifecycle.sh` (`PHASES` line 18; `next_phase`
  lines ~89–97; `advance` ~133–139; `done` ~140–163; `valid_phase`, `status`'s `(n/N)` counter) and
  `plugins/i2p/skills/lifecycle/scripts/cost.sh` (`PHASES` line 25; `base_for` lines ~27–31).
- `.i2p/lifecycle.json` is `{product, current_phase, phases[], cycle, started_at, history[]}` today;
  extend additively with `loop_state` and `loop_pass`. `cost.json` is already cycle-indexed and
  additive (see cost.sh header) — keep that contract.
- The loop back-edge needs a transition verb the owner can call on a gate failure (e.g.
  `lifecycle.sh fail <ASSURE|SECURE>` re-entering BUILD), distinct from `done <phase>`. Keep `done`
  order-safe and idempotent as today.
- Preserve the OPERATE↻ DISCOVER wrap + `bump_cycle`, the corrupt-file refusal, and the
  best-effort cost `close`/calibration calls.
