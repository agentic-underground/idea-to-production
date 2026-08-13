# EARS — `board`: lifecycle + EPIC rollup + native Status write + native create

Requirements for the `board` component. Slice 1 (PLAN 0072.014) established the lifecycle + EPIC rollup;
**Slice 2 (PLAN 0072.015)** ports the Status *write* into native Python (EARS-011/012/013 + the rewritten
lockstep EARS-002/003); **Slice 3a (PLAN 0072.017)** ports **`ensure-epic`** (the create/converge path)
into native Python (EARS-015…018). EARS = Easy Approach to Requirements Syntax. Each `EARS-NNN` is traced
into a pytest coordinate (`# @EARS-NNN`).

The decidable core is `board/core/lifecycle.py` + `board/core/write.py` + `board/core/create.py`; the I/O
shell is `board/gh.py`.

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
- **EARS-014** — WHEN resolving a child PLAN's contribution to its parent's rollup, a **CLOSED** child
  SHALL contribute its board Status when that Status is itself terminal (so a `Delivered` child is not
  flattened to `Done`), else `Done` (a closed issue is at least Done); a **non-CLOSED** (OPEN) child SHALL
  contribute its live board Status, or be omitted when unset. *(PLAN 0072.016 — the fix that lets an
  all-`Delivered` EPIC roll to `Delivered` per EARS-005 rather than always `Done`.)*
- **EARS-015** — WHEN `ensure-epic <order>` runs, the system SHALL first search all repo issues for the
  byte-exact idempotency marker `<!-- pipeline-epic-NNNN -->` and treat a hit as "already created"
  (converge, never duplicate). *(Slice 3a. Known limitation, shared with the bash `_ghp_issue_by_marker`:
  the `gh api issues` list is eventually consistent — a freshly-created issue takes ~3s to appear — so a
  re-run WITHIN that window of a create could still duplicate. Real usage (crash → later re-run) is well
  outside the window; the story proof polls for list-consistency before asserting the heal.)*
- **EARS-016** — WHEN an EPIC is created, the system SHALL create it **bare** (`gh issue create` with a
  body of `desc` + marker) and add it to the board, seeding `Backlog` on the item-add-returned item id
  (no re-query — dodges the item-list propagation race of 0072.010's F0). *(Slice 3a.)*
- **EARS-017** — WHEN `ensure-epic` converges an already-present EPIC, the system SHALL heal: add it to the
  board if absent, seed `Backlog` if its Status is UNSET, and (idempotently) re-apply its kind — so a crash
  between create and board-add (or a seed that never landed) is repaired on the next run, never left
  permanently UNSET. The converge decision is a **total pure reducer** over
  `(found_issue, on_board, status_is_set)`. *(Slice 3a — closes the F0 class for good.)*
- **EARS-019** — WHEN `ensure-plan <epic#> <order>` creates a PLAN, the system SHALL create it under the
  EPIC via `gh issue create --parent <epic#>`, then board+seed+kind as EARS-016. The `--parent` link is
  NOT atomic (gh does create-then-`AddSubIssue` internally), so a half-failed link is recovered by the
  next converge (EARS-020), never a lost sub-issue. *(Slice 4.)*
- **EARS-020** — WHEN `ensure-plan` converges an already-present PLAN, the system SHALL heal a **missing**
  parent link (`gh issue edit --parent`, non-fatal) in addition to board membership + Backlog seed + kind;
  the converge decision is a **total pure reducer** over `(found, on_board, status_is_set, needs_link)`.
  IF the PLAN is already a sub-issue of a **DIFFERENT** EPIC, the system SHALL **warn and NOT repoint** it
  (never silently steal a deliberately-moved child). *(Slice 4.)*
- **EARS-021** — WHEN `next-plan <epic#>` runs, the system SHALL derive the EPIC order from the EPIC's
  title and return the next free `NNNN.SSS` = (max `SSS` among the EPIC's child `PLAN NNNN.SSS` titles,
  matched as a **substring**) + 1; an EPIC with no PLAN children ⇒ `.001`. *(Slice 4.)*

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
- **EARS-018** — IF the issue-list READ that backs the marker search fails (auth/rate-limit/network),
  THEN `ensure-epic` SHALL fail closed (exit non-zero) and create **nothing** — a failed read is NEVER
  mistaken for "marker absent" (which would duplicate the EPIC). AND IF the `<order>` is not 1–4 digits,
  THEN it SHALL be rejected (fail closed, no write). AND the kind's Type/label application SHALL be
  **best-effort** (a non-org repo or a missing label ⇒ warn, the verb still succeeds). *(Slice 3a.)*
- **EARS-022** — IF a PLAN `<order>` is not `NNNN.SSS`, OR the `<epic#>` is not a bare issue number, OR the
  EPIC's title carries no derivable 4-digit order, THEN the system SHALL fail closed (exit non-zero, no
  write). Issue-number comparisons (the parent-link check) SHALL be canonicalized (`"0337"`≡`"337"`) so a
  correctly-linked PLAN never triggers a needless re-link loop. *(Slice 4.)*
