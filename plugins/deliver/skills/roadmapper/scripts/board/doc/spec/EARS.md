# EARS — `board`: lifecycle + EPIC rollup + native Status write

Requirements for the `board` component. Slice 1 (PLAN 0072.014) established the lifecycle + EPIC rollup;
**Slice 2 (PLAN 0072.015)** ports the Status *write* into native Python (EARS-011/012/013 + the rewritten
lockstep EARS-002/003). EARS = Easy Approach to Requirements Syntax. Each `EARS-NNN` is traced into a
pytest coordinate (`# @EARS-NNN`).

The decidable core is `board/core/lifecycle.py` + `board/core/write.py`; the I/O shell is `board/gh.py`.

## Ubiquitous

- **EARS-001** — The system SHALL map each supported transition verb to exactly one canonical Status:
  `start`→`In Progress`, `review`→`Review`, `revise`→`Revise`, `done`→`Done`, `deliver`→`Delivered`,
  `ready`→`To Do`.
- **EARS-010** — The system's canonical Status list SHALL be byte-identical to the bash
  `_GHP_STATUS_OPTIONS` list (`Backlog, To Do, In Progress, Review, Revise, Done, Delivered`) — the
  cross-language drift guard.

## Event-driven

- **EARS-002** — WHEN an issue's Status is set to a terminal value (`Done`/`Delivered`), the system SHALL
  close the issue. *(Native lockstep: `board.core.write.issue_state_action` returns `close` for a terminal
  target; `board.gh` executes `gh issue close`. The pure decision is pinned; the I/O is proven in the
  story proof.)*
- **EARS-003** — WHEN an issue's Status is set OUT of a terminal value while the issue is `CLOSED`, the
  system SHALL reopen it. *(Native lockstep: `issue_state_action` returns `reopen`; `board.gh` executes
  `gh issue reopen`.)*
- **EARS-004** — WHEN a PLAN's status changes via a lifecycle transition, the system SHALL recompute the
  parent EPIC's status from its children's statuses and apply the result iff it differs.
- **EARS-011** — WHEN setting an issue's Status, the system SHALL resolve the Status field id and
  single-select option id from a **fresh** `gh project field-list` read (no persisted cache) and write the
  value via `gh project item-edit` (native porcelain, argument-list, no hand-built GraphQL). *(Slice 2 —
  designs out the stale-cache class of 0072.013.)*

## State-driven

- **EARS-005** — WHILE all of an EPIC's PLAN children are terminal, the EPIC's computed status SHALL be
  `Delivered` if every child is `Delivered`, otherwise `Done`.
- **EARS-006** — WHILE at least one PLAN child is active (a canonical status other than `Backlog`/`To Do`)
  and not all children are terminal, the computed status SHALL be `In Progress`; WHILE all children are
  `Backlog`/`To Do` (none started), the computed status SHALL be **unchanged**.
- **EARS-014** — WHEN resolving a child PLAN's contribution to its parent's rollup, a **CLOSED** child
  SHALL contribute its board Status when that Status is itself terminal (so a `Delivered` child is not
  flattened to `Done`), else `Done` (a closed issue is at least Done); an **OPEN** child SHALL contribute
  its live board Status, or be omitted when unset. *(PLAN 0072.016 — the fix that lets an all-`Delivered`
  EPIC roll to `Delivered` per EARS-005 rather than always `Done`.)*

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
- **EARS-012** — IF the requested Status has no matching single-select option on the board (even after a
  fresh field-list read), OR the target issue is not a board item, THEN the system SHALL fail closed (exit
  non-zero, clear message) and make **no write**. *(An honest failure — never the silent stale-cache miss
  of 0072.013. On board #4 today, `Delivered` is such an absent option; the write refuses rather than
  guesses.)*
- **EARS-013** — The issue-state lockstep is a total decision over `(target_status, issue_state)`:
  terminal target ⇒ `close` (the current issue state is not consulted); non-terminal target ⇒ `reopen`
  IFF the issue is `CLOSED`, else no action. AND: after the Status field write has **succeeded**, a
  subsequent lockstep `gh issue close`/`reopen` I/O failure SHALL be **non-fatal** (a warning, exit 0) —
  the primary Status value is already persisted, matching the bash `set-status` rc contract.
