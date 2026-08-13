# EARS — `board` Slice 1: lifecycle + EPIC rollup

Requirements for the `board` component's first slice (PLAN 0072.014). EARS = Easy Approach to
Requirements Syntax. Each `EARS-NNN` is traced into a pytest coordinate (`# @EARS-NNN`).

The decidable core is `board/core/lifecycle.py`; the I/O shell is `board/gh.py`.

## Ubiquitous

- **EARS-001** — The system SHALL map each supported transition verb to exactly one canonical Status:
  `start`→`In Progress`, `review`→`Review`, `revise`→`Revise`, `done`→`Done`, `deliver`→`Delivered`,
  `ready`→`To Do`.
- **EARS-010** — The system's canonical Status list SHALL be byte-identical to the bash
  `_GHP_STATUS_OPTIONS` list (`Backlog, To Do, In Progress, Review, Revise, Done, Delivered`) — the
  cross-language drift guard.

## Event-driven

- **EARS-002** — WHEN a PLAN transitions to a terminal status (`Done`/`Delivered`), the system SHALL close
  the PLAN's issue. *(Delegated to the proven `gh-pipeline.sh set-status` lockstep; asserted in the story
  proof, not re-implemented.)*
- **EARS-003** — WHEN a PLAN transitions out of a terminal status while its issue is closed, the system
  SHALL reopen the issue. *(Delegated as EARS-002.)*
- **EARS-004** — WHEN a PLAN's status changes via a lifecycle transition, the system SHALL recompute the
  parent EPIC's status from its children's statuses and apply the result iff it differs.

## State-driven

- **EARS-005** — WHILE all of an EPIC's PLAN children are terminal, the EPIC's computed status SHALL be
  `Delivered` if every child is `Delivered`, otherwise `Done`.
- **EARS-006** — WHILE at least one PLAN child is active (a canonical status other than `Backlog`/`To Do`)
  and not all children are terminal, the computed status SHALL be `In Progress`; WHILE all children are
  `Backlog`/`To Do` (none started), the computed status SHALL be **unchanged**.

## Unwanted behaviour (fail-closed / guards)

- **EARS-007** — IF the board is unreachable OR an order cannot be resolved to an issue at the start of a
  command, THEN the system SHALL fail closed (exit non-zero, clear message, **no write at all**). *(If a
  transient failure occurs mid-sequence — after the PLAN's Status is written but before the parent rollup
  — the PLAN move stands and the EPIC is reconcilable via the idempotent `board rollup <epic-order>`; this
  is strictly better than the pre-tool status quo, where no rollup happened at all.)*
- **EARS-008** — IF a transition verb is unknown, OR a value that is not a roadmap order (e.g. a bare
  GitHub issue number) is supplied where an order is expected, THEN the system SHALL reject it (exit
  non-zero) and make no board change.
- **EARS-009** *(the CRITICAL guard)* — IF the EPIC's current status is off-lifecycle (`PARKED` or any
  non-canonical value) OR already terminal, THEN the rollup SHALL make **no change** — it SHALL never
  un-park a parked EPIC nor regress a completed one. Also: an EPIC with **no** children ⇒ no change.
