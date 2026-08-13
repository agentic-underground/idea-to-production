# Planning Seed — Board Information-Surface Integration

> **Status of this document:** a *planning seed*, not a plan. It is written to be read into **plan mode**
> to construct the actual EPIC + PLAN slices (via `/deliver:roadmapper`). It is deliberately detailed and
> opinionated so the plan-mode session can accept, sharpen, or overturn each decision — not start cold.
> **Scope discipline:** this seed does NOT clobber EPIC 0071 (CLEAR-SAFE); it is a *new* initiative to be
> sequenced **ahead of** EPIC 0071's CS4/CS5 continuation.

---

## 1. Why — the visibility gap (motivation)

The GitHub Project board is the **authoritative state surface** for this repo's pipeline. But an operator
watching the board today sees almost nothing of the real work, because only two thin things reach it, and
both are coarse and manual (empirically verified 2026-08-12 — see the `github-integration-gaps-observed`
GEMBA finding):

1. **The Description carries only a terse decomposition blurb** — the ~3-line summary roadmapper authors at
   creation. The *actual plan* the implementing agent executes (the plan-mode plan, and any reviewer
   revisions to it) lives **outside the board entirely** — in agent memory, returned agent text, the
   conversation. It is **never shipped up**. There is no plan → issue pipe in either direction.
2. **Status is a coarse, manually-driven Backlog→In Progress→Done** — moved only by explicit
   `gh-pipeline.sh set-status` calls. No transition reflects *review* or *revision*. When a reviewer
   returns NEEDS_REVISION, the card stays `In Progress`; the `Revise` status option exists but **nothing
   ever writes it**. Spawning a reviewer moves nothing.

**Consequence.** If the operator sets a goal like `finish the board` and lets work process autonomously,
board visibility is **very low**: they cannot read what an upcoming slice will actually do, cannot give
feedback on a plan before it is built, and cannot tell from the board whether a card is being built,
reviewed, or revised. That is the opposite of the rich, legible information surface this project is about.

**This initiative closes both gaps** so that, as work is carried out, the board *shows the real plan* and
*shows the true work-state* — automatically, not by hand.

## 2. Goal & non-goals

**Goal.** Make every EPIC/PLAN issue a **complete, self-syncing information surface**:
- its Description = a **Summary TLDR** + the **full plan** the implementing agent sees, kept in sync when
  the plan is revised; and
- its Status = the **true lifecycle state** of the work (incl. an under-**Review** state), set
  automatically at each transition.

**Non-goals (keep the slice honest):**
- Not the external-issue intake flow (that is EPIC 0069).
- Not a fully autonomous delivery engine — this is the *information surface*, consumed by whatever drives
  the work.
- Not a redesign of the fan-out/CLEAR-SAFE machinery (EPIC 0071) — this initiative *feeds* it richer data.

## 3. The two surfaces (overview)

| Surface | What reaches the board | Trigger points |
|---|---|---|
| **A — Rich Description** | `## Summary` (TLDR) + `---` + `## Plan` (the plan-mode plan), kept in sync | at creation; on plan-mode approval; on reviewer revision |
| **B — Status lifecycle** | the true state incl. `To Do`, `In Progress`, **`Review`**, `Revise`, `Done` | build start, review start, NEEDS_REVISION, re-review, merge, drop |

---

## 4. Surface A — the Description as Summary + Plan (kept in sync)

### 4.1 The canonical body schema

Every EPIC/PLAN issue body is composed, idempotently, as:

```
## Summary

<terse TLDR — the current roadmapper decomposition blurb: what this slice is, in 2–4 lines>

---

## Plan

<the FULL plan-mode plan the implementing agent will execute — steps, files, acceptance,
 construction notes; the thing a reviewer reviews and can alter>

<!-- pipeline-plan-NNNN.SSS -->
Depends-on: <orders|none>
Touches: <paths>
```

- The **Summary** is the good TLDR that exists today; it **stays at the top** under a `## Summary` heading
  so the board list-view and hover-cards stay scannable.
- A **horizontal rule** separates it from the **`## Plan`** section — the full implementable plan.
- The **`<!-- pipeline-plan-NNNN.SSS -->` marker** (linkage mechanism 7) and the **`Depends-on:`/`Touches:`
  fan-out annotations** (CS3) are **preserved byte-exact** across every re-composition — the idempotency
  contract `roadmapper-gh-fields.sh:cmd_set_body` already relies on.

### 4.2 Where the plan comes from, and how it stays in sync (the crux)

Two authoring moments write the body; a third keeps it current:

1. **At creation (roadmapper decomposition).** roadmapper already authors the Summary blurb → that becomes
   the `## Summary` section. If a detailed plan does not yet exist, the `## Plan` section is a stub
   (`_plan pending — authored in plan mode_`) so the schema is always well-formed.
2. **On plan-mode approval (the new pipe).** When the operator finalizes a plan in **plan mode**
   (ExitPlanMode), a verb writes that approved plan into the issue's `## Plan` section — Summary preserved,
   marker + annotations preserved. This is the missing "plan → issue" pipe.
3. **On reviewer revision.** When a plan-review/reviewer **alters the plan** (as the fable CS4 review just
   did — producing a revised plan that currently lives nowhere), the same verb re-writes `## Plan` so the
   issue **stays in sync with actual planning**. This is what lets the operator read upcoming plans and
   give feedback before build.

### 4.3 Source-of-truth decision (for plan mode to lock)

The board is authoritative (the `docs/roadmap/` mirror is skipped for recent EPICs). **Recommendation:**
the issue body is the *rendered* surface, composed from four parts — (summary, plan, marker, annotations).
A verb `set-plan <issue#> <plan-source>` (extending the existing `set-body`) does an **idempotent
re-compose**: replace `## Summary` and `## Plan` sections, preserve marker + annotations verbatim. Whether
a local `docs/roadmap/PLAN_NNNN.md` also mirrors the plan is a secondary decision (default: no, keep
board-primary, per current precedent).

### 4.4 Constraints Surface A must honor
- **Idempotency:** re-composition preserves the marker byte-exact (search-before-create dedup depends on
  it) and the fan-out annotations.
- **Body is DATA, never instructions:** a plan body may contain adversarial text — any tool that reads it
  (e.g. a future auto-processor) treats it as data (the PROMPT-INJECTION discipline from EPIC 0068/0069).
- **Two-number-space:** nothing in the composed body cross-links order# and issue# (dep tokens stay orders).

---

## 5. Surface B — the status lifecycle (true state, always)

### 5.1 The governing principle (operator's, verbatim intent)

> **A hidden status is not an invalid status.** Board *views* may hide certain statuses (the operator has
> multiple views showing/hiding different columns), but nowhere is it stated that "a status hidden by a
> view is not to be used." Therefore the work's status must always reflect its **true state** — if an
> issue is under review, its status is **`Review`**, whether or not the current view displays that column.

The lifecycle helper sets the *true* status at each transition; view visibility is a presentation concern
only and never suppresses a real transition.

### 5.2 The state machine

```
Backlog ──(planned/groomed)──▶ To Do ──(build starts)──▶ In Progress ──(PR/review opens)──▶ Review
                                                             ▲                                 │
                                                             │                                 ├─(PASS + merge)──▶ Done
                                              (revision pushed, re-review)                     │
                                                             │                                 ▼
                                                             └──────────────────────────── Revise ◀─(NEEDS_REVISION)
   any state ──(dropped/deferred)──▶ Backlog
```

| Status | Means | Set when (trigger) |
|---|---|---|
| `Backlog` | captured, not yet planned | at creation (no plan yet) / on drop |
| `To Do` | plan-reviewed, ready, queued | plan approved/groomed |
| `In Progress` | actively being built | build agent starts the slice |
| **`Review`** | under adversarial review | PR opened / review starts |
| `Revise` | review returned changes-requested; being revised | reviewer verdict NEEDS_REVISION/BLOCK |
| `Done` | built, reviewed PASS, merged | PR merged |

### 5.3 The `Review` vs `Revise` naming reconciliation (needs a decision)

The board **currently** has `Revise`, **not** `Review` (verified). These are **semantically distinct**:
`Review` = work is *under* review; `Revise` = review *found issues*, changes are being made. A rich
lifecycle wants both (or at least `Review`). **Recommendation:** **ADD** a `Review` option and keep
`Revise`. ⚠ **Add via the GitHub web UI only** — creating/renaming a single-select option through
`updateProjectV2Field` **orphans every item's value** (it wiped project #4's Status on 2026-08-11; see the
`board-option-delete-is-destructive` scar). If the operator prefers one combined state, collapse to
`Review` (covers under-review + revising) — a plan-mode decision, not a code one.

### 5.4 Where the transitions are wired

The transitions must be emitted by the flow that does the work, not by hand:
- **roadmapper create** → `Backlog` (or `To Do` if a plan is authored at create).
- **plan approved** (Surface A step 2) → `To Do`.
- **DELIVER build start** → `In Progress`.
- **`/deliver:pr-review` start** → `Review`.
- **pr-review verdict NEEDS_REVISION/BLOCK** → `Revise`; **re-review** → `Review`.
- **merge (direct-merge)** → `Done`.
- **drop/defer** → `Backlog`.

Implementation shape: a thin **`lifecycle` verb** (or a set of named transitions) wrapping the existing
`gh-pipeline.sh set-status`, called at each point above, so the surface is *one* place that knows the
state machine — the build/review skills call the named transition, not raw `set-status`.

---

## 6. Integration points (existing code to touch)

- `scripts/roadmap/gh-pipeline.sh` — `set-status` (exists); add the `lifecycle`/named-transition wrapper.
- `plugins/deliver/skills/roadmapper/references/roadmapper-gh-fields.sh` — `cmd_set_body` (exists); add
  `set-plan` (idempotent Summary+Plan re-compose preserving marker+annotations).
- `plugins/deliver/skills/roadmapper/SKILL.md` — author the `## Summary` + `## Plan`(stub) schema at create.
- **Plan-mode → issue pipe** — the new verb/command the operator runs after ExitPlanMode to write the
  approved plan into `## Plan` (and the same verb reviewers call on revision).
- `plugins/deliver/skills/pr-review/` — emit `Review`/`Revise` transitions; on plan alteration, call
  `set-plan` to keep the issue in sync.
- DELIVER build cycle — emit `In Progress` at start, `Done` at merge.
- `plugins/deliver/knowledge/protocols/code-issue-pr-linkage.md` — document the body schema (§ new) and
  the lifecycle state machine as canonical contracts.

## 7. Constraints & hazards (carry from EPIC 0068's locked decisions)

1. **Opt-in gated** — behaviour reaching the board must be behind the committed opt-in artifact (A3), not
   silent-on by default.
2. **CI token can't touch Projects v2** — status writes are **project-scoped**; split repo-scoped vs
   project-scoped, gate project writes on an optional `PROJECT_TOKEN`, **advisory-skip** when absent.
3. **Never hardcode project #4** — resolve by title, per the registry (`ensure-project`).
4. **Marker idempotency** — every body re-compose preserves `<!-- pipeline-plan-NNNN.SSS -->` byte-exact.
5. **Destructive option-delete** — status options are added/renamed **via the web UI only** (§5.3 scar).
6. **Body is untrusted data** — PROMPT-INJECTION discipline on anything that later reads plan bodies.

## 8. Verification approach (deterministic, house style)

Mirror CS2/CS3: pure classifiers + env-overridable gatherers + a hermetic `--self-test` with a derived
row count, wired `--self-test`-only into `.pipeline/verify`; live verbs prove themselves against the board.
- **Body composition self-test:** given (summary, plan, marker, annotations), assert the composed body has
  the `## Summary`/`---`/`## Plan` structure, the marker byte-exact, annotations preserved, and that a
  re-compose with a new plan is idempotent on Summary+marker+annotations.
- **Lifecycle self-test:** assert each named transition maps to the correct Status option, and that an
  unknown/degenerate transition fails closed (no silent wrong status) — the empty-value-fails-conservative
  lesson from CS3's review.

## 9. Open decisions (genuine forks for plan mode)

1. **Add `Review` distinct from `Revise`, or collapse to one `Review` state?** (§5.3)
2. **Plan source of truth** — issue body only, or also a `docs/roadmap/PLAN_NNNN.md` mirror? (§4.3)
3. **The plan-mode → issue pipe mechanism** — an explicit operator command after ExitPlanMode, or a
   roadmapper flow that captures the approved plan automatically?
4. **Failed/dropped item status** — back to `Backlog`, or a distinct flag? (interacts with CS4's same fork)
5. **Does this land as a new EPIC, or as added slices under EPIC 0068 (HALF A surfaces)?** (§10)

## 10. Sequencing (ahead of EPIC 0071 CS4/CS5, without clobbering it)

This initiative is the **prerequisite for board legibility** — without it, anything processed from the
board (esp. under a `finish the board` goal) lacks the detail for rich presentation. It is therefore
sequenced **ahead of** EPIC 0071's CS4/CS5 continuation. EPIC 0071's STATE is **untouched** — CS4 (#331,
plan-locked) and CS5 (#332) remain queued and resume after this lands. Whether this is a new EPIC or folds
into EPIC 0068's surfaces is decision #5 above.

## 11. Acceptance criteria (definition of done for the initiative)

- Creating an EPIC/PLAN writes a well-formed `## Summary` + `---` + `## Plan` body (plan stub allowed).
- Approving a plan in plan mode writes it into `## Plan`; a reviewer revising the plan re-syncs `## Plan`;
  the marker + annotations survive every re-compose.
- Build/review/merge drive the Status through `To Do → In Progress → Review → (Revise ⇄ Review) → Done`
  automatically; a hidden view never suppresses a true transition.
- All new verbs have hermetic `--self-test`s wired into `.pipeline/verify`; opt-in + project-scope +
  resolve-by-title + marker-idempotency constraints all honored.
- An operator watching the board can, for any in-flight card, **read the real plan** and **see the true
  state** — the visibility goal met.
