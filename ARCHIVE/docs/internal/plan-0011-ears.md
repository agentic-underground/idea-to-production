# EARS Specification — PLAN_0011: retrofit EARS/Gherkin/story proof for the PR #56 lifecycle-delivery changes

**Date:** 2026-06-23
**Epic / Plan:** `EPIC_0010` / `PLAN_0011`
**Reviewer target:** EARS-REVIEWER
**Source:** legacy backlog item 34 (`PR #56` quality retrofit)

---

## Provenance re-scope (load-bearing — read before the IDs)

PR #56 shipped **three** behaviours into the FOUNDRY lifecycle outside the SDLC. PLAN_0011 pins
the behaviour **that exists on the current surface**, not the surface PR #56 was authored against.
Two of the three behaviours were authored against the **`flow` plugin**, which has since been
**RETIRED** (commit `da07db8` — "retire the flow plugin; the FLEET engine supersedes it"). The
honest mapping:

| PR #56 behaviour | Original surface | Status today | Where it lives now |
|---|---|---|---|
| `history.rs` `status_from()` maps `AWAITING MERGE → Status::Done` on startup | `flow-server` (Rust) | **RETIRED** | superseded by the FLEET v2 manifest `state` model (`available → engaged → completed`) + the orchestrator's `AWAITING MERGE → COMPLETE` post-merge transition |
| `ds-step-9` Action #8 posts `done` to the flow canvas | `flow` canvas `post_status` | **RETIRED** | `ds-step-9` step 8 is now *"Reserved — the live flow board was retired… No separate board to sync."* The live completion signal is `DELIVERY_COMPLETE` keyed to branch HEAD; the engine owns `state` |
| `lifecycle-orchestrator` AWAITING MERGE pause + post-merge completion handler | `plugins/foundry/agents/lifecycle-orchestrator.md` | **LIVE** | same file, directly testable |

Each EARS ID below is therefore tagged **LIVE** (pinned by a behaviour assertion on the current
surface) or **RETIRED** (pinned by an assertion that the retired surface is gone *and* that its
live successor behaves correctly). No retired `flow-server` code is resurrected — pinning the
*retirement* is the test coordinate that catches a regression (someone re-adding a dead sink call).

---

## EARS-001 — AWAITING MERGE → terminal-Done mapping *(RETIRED surface → LIVE successor)*

**Original (RETIRED):** WHEN the flow history loaded a record whose status was `AWAITING MERGE`
THE SYSTEM SHALL map it to a terminal `Done` status on startup.

**Re-scoped statement (current surface):**
WHEN the post-merge completion handler confirms a paused item's PR is `MERGED`
THE SYSTEM SHALL transition that item from `AWAITING MERGE` to the terminal `COMPLETE` status
(the v2 manifest equivalent of the retired `Done`),
AND the retired `flow-server` `history.rs` startup mapping SHALL NOT be present in the tree.

- **Gherkin:** `AWAITING MERGE maps to the terminal COMPLETE status`,
  `the retired flow-server startup mapping is gone`
- **Test coordinate:** `tests/plan-0011/02-awaiting-merge-mapping.sh`
- **Unhappy/abuse:** unknown/malformed status → no terminal transition (the handler only flips on a
  confirmed `MERGED`; an unverified or not-yet-merged PR never maps to terminal — see EARS-006).

## EARS-002 — completion status post (Action #8) *(RETIRED surface → LIVE successor)*

**Original (RETIRED):** WHEN `ds-step-9-commit-push` completes its commit/push action THE SYSTEM
SHALL post a `done` status for the item to the canvas surface (Action #8).

**Re-scoped statement (current surface):**
WHEN `ds-step-9-commit-push` completes in engine mode THE SYSTEM SHALL emit
`DELIVERY_COMPLETE` keyed to branch HEAD and SHALL NOT post to a live flow canvas
(Action #8 is reserved/retired; the engine owns the `state` column).

- **Gherkin:** `ds-step-9 emits DELIVERY_COMPLETE at branch HEAD, not a canvas post`,
  `Action #8 is reserved — no live board to sync`
- **Test coordinate:** `tests/plan-0011/04-status-sync.sh`

## EARS-003 — AWAITING MERGE pause *(LIVE)*

WHILE a PLAN's PR is open and unmerged THE SYSTEM SHALL hold the lifecycle-orchestrator in an
`AWAITING MERGE` pause (PR URL visible, `IN_PROGRESS.md` carrying `AWAITING_MERGE`) rather than
reporting the item complete.

- **Gherkin:** `the orchestrator pauses at AWAITING MERGE with the PR visible`
- **Test coordinate:** `tests/plan-0011/03-pause-and-post-merge.sh`

## EARS-004 — post-merge completion handler *(LIVE — happy path)*

WHEN the PR for a paused item is merged (the user sends the merge signal and the handler confirms
`state == "MERGED"`) THE SYSTEM SHALL run the post-merge completion handler that transitions the
item to `COMPLETE`, emits `DELIVERY_COMPLETE`, and reports a completion summary.

- **Gherkin:** `a merged PR drives the item to COMPLETE` (happy)
- **Test coordinate:** `tests/plan-0011/03-pause-and-post-merge.sh`

## EARS-005 — status sink unreachable degrades gracefully *(LIVE — unhappy)*

IF the status/board sink is unreachable WHEN completion runs THE SYSTEM SHALL degrade gracefully —
commit/push (and post-merge completion) MUST NOT fail because the status sink is down. On the
current surface this is realised two ways: `ds-step-9` step 4b graceful-skip of GitHub
issue/PR automation (*"Never block delivery on this"*), and the orchestrator's **Path C**
(gh unavailable / merge fails → fall back, do **not** emit `DELIVERY_COMPLETE`, do **not** corrupt
the sentinel chain, leave the item paused). The retired flow canvas is itself a "sink-down by
construction" — the post-merge handler completes without a live board.

- **Gherkin:** `a down status sink does not fail delivery` (sink-down),
  `delivery records completion without a live board` (sink-up equivalent)
- **Test coordinate:** `tests/plan-0011/04-status-sync.sh`, `tests/plan-0011/03-pause-and-post-merge.sh`

## EARS-006 — refuse to complete an unmerged PR *(LIVE — abuse)*

IF the post-merge handler runs against a PR that is not yet merged THEN THE SYSTEM SHALL NOT mark
the item complete (warn and wait; no `DELIVERY_COMPLETE`; ROADMAP/manifest unchanged).

- **Gherkin:** `the handler refuses a not-yet-merged PR` (abuse)
- **Test coordinate:** `tests/plan-0011/03-pause-and-post-merge.sh`

---

## Traceability summary (acceptance criterion 1)

| EARS ID | Gherkin scenario(s) | Test coordinate | happy/unhappy/abuse |
|---|---|---|---|
| EARS-001 | AWAITING MERGE → COMPLETE; retired mapping gone | `02-awaiting-merge-mapping.sh` | happy + abuse (unknown/malformed) |
| EARS-002 | DELIVERY_COMPLETE at HEAD; Action #8 reserved | `04-status-sync.sh` | happy (sink-up equivalent) |
| EARS-003 | pause at AWAITING MERGE | `03-pause-and-post-merge.sh` | happy |
| EARS-004 | merged PR → COMPLETE | `03-pause-and-post-merge.sh` | happy |
| EARS-005 | down sink does not fail delivery | `04-status-sync.sh`, `03-pause-and-post-merge.sh` | unhappy |
| EARS-006 | refuse not-yet-merged PR | `03-pause-and-post-merge.sh` | abuse |

Every EARS ID maps to at least one Gherkin scenario and at least one passing test coordinate.
