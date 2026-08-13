# EPIC 0072 — Board Information-Surface Integration (delivery plan)

## Context

The GitHub Project board is this repo's authoritative state surface, but an operator watching it sees
almost nothing of the real work: the Description carries only a terse decomposition blurb (the real plan
lives off-board), and Status is a coarse, **manually**-driven `Backlog→In Progress→Done` — no transition
reflects *review* or *revision*, and spawning a reviewer moves nothing (empirically verified 2026-08-12,
`github-integration-gaps-observed` memory). Under a `finish the board` goal, visibility is therefore very
low. **This initiative closes both gaps** so the board shows the *real plan* and the *true work-state*
automatically. Source seed: `docs/roadmap/SEED_board-info-surface.md`. Sequenced **ahead of** EPIC 0071
CS4/CS5 (does not clobber it).

**Decisions locked with the operator:** new **EPIC 0072** (not folded into 0068) · `Review` is a status
**distinct** from `Revise` (added via the web UI) · the plan→issue pipe is an **explicit verb**
(`set-plan`, no auto-capture) · **issue-primary** source of truth (no docs mirror for the plan text) ·
board-writes **ride the existing `github_board`-mode gate** (the unbuilt 0068 A3 opt-in is *not* a blocker;
the stale seed §7.1 "gate on A3" constraint is retired in the closing slice).

## Dogfooding + bug-capture protocol (the operator's explicit ask)

Author EPIC 0072 and its PLANs onto board #4 **via `/deliver:roadmapper`** — dogfooding our own planner.
**Anything that doesn't work as expected is written up and scheduled** as a bug or enhancement (a
`pipeline/NNNN-*` board item via roadmapper, or `/operate:gemba` for a workface capture). Candidate gaps
already surfaced by exploration — confirm/file each as it's hit (several are *fixed by* slices below, so
file the gap, then point it at its fixing slice):

1. `_GHP_STATUS_OPTIONS` (`gh-pipeline.sh:58`) is drifted — lacks `Revise` (live) and `Review` → its
   warn-on-missing logic misleads. (Fixed by 0072.007.)
2. No section-splice body verb — `set-body` is whole-file overwrite only. (Fixed by 0072.001.)
3. pr-review never calls `set-status` and extracts no issue# → the whole review lifecycle is board-invisible. (0072.004/0072.008.)
4. Reserved "Status sink" is a dead no-op (`ds-step-9-commit-push.md:151-153`, `lifecycle-orchestrator.md:278-283`) — `Done` is never written. (0072.006.)
5. Issue# is bound lazily at delivery (`ds-step-9-commit-push.md:83-99`) → a Phase-0 build has no issue# for a non-roadmapper-originated slice. File as an ordering/coverage gap.
6. Branch→order is the only proven mapping (`verify-board-linkage.sh:37-38`); PR→order for fork/renamed branches is unproven and needed by pr-review. File as a resolver coverage gap.
7. Stale seed constraint §7.1 (A3 opt-in) — A3 unbuilt; ride the existing gate. File as protocol-doc drift; retire in 0072.009.
8. The roadmapper set-status propagation race after `item-add` (already in memory) — re-confirm if hit during authoring.

> Note the recursion: EPIC 0072's *own* board issues are authored **before** the Summary+Plan structure
> exists, so they'll carry the current terse-body format. Once 0072.001/0072.003 land, re-sync 0072's own
> issue bodies into the new format as the first real dogfood of the pipe.

## The decomposition (EPIC 0072 + nine PLAN slices)

Metadata → Branch `pipeline/0072-board-info-surface`; Depends on `EPIC_0071` (sequencing only — 0072 lands
first, 0071 CS4 resumes after); Phase `BUILD`. **`Review` distinct from `Revise`; issue-primary; ride the
existing board-mode gate.** Each slice is built test-first via DELIVER (branch → PR → single reviewer per
`pr-gate-single-reviewer` → direct-merge), with a hermetic `--self-test` wired `--self-test`-only into
`.pipeline/verify` (the live verbs prove themselves against the board).

| Order | Slice | Keystone | Depends-on | Touches (superset) |
|---|---|---|---|---|
| 0072.001 | `set-plan` section-splice verb + body composer | ★ | none | `roadmapper-gh-fields.sh`, `.pipeline/verify`, `code-issue-pr-linkage.md` |
| 0072.002 | roadmapper authors `## Summary` + `---` + `## Plan`(stub) at create | | 0072.001 | `roadmapper/SKILL.md`, `roadmapper-gh-fields.sh` |
| 0072.003 | plan-mode → issue pipe (explicit verb) | ★ | 0072.001 | `roadmapper/SKILL.md`, `roadmapper-gh-fields.sh`, new `plugins/deliver/commands/*` |
| 0072.004 | branch/PR → issue resolver | ★ | none | `scripts/roadmap/gh-pipeline.sh`, `.pipeline/verify` |
| 0072.005 | `lifecycle` transition wrapper over `set-status` | ★ | none (soft: 0072.007) | `scripts/roadmap/gh-pipeline.sh`, `.pipeline/verify`, `code-issue-pr-linkage.md` |
| 0072.006 | wire build-start (In Progress) + Done-at-merge | | 0072.004, 0072.005 | `builder/SKILL.md`, `ds-step-9-commit-push.md`, `lifecycle-orchestrator.md` |
| 0072.007 | add `Review` board option (web UI) + reconcile canonical list | ★(ops) | none | `gh-pipeline.sh:58` array, new runbook |
| 0072.008 | wire pr-review `Review`/`Revise` transitions + plan re-sync | | 0072.001, .004, .005, .007 | `pr-review/SKILL.md`, `pr-review/scripts/gather-diff.sh` |
| 0072.009 | plan-approved→To Do + canonicalize protocol (CLOSES EPIC) | | 0072.003, 0072.005 (+.002 for accept) | `code-issue-pr-linkage.md`, `roadmapper/SKILL.md`, plan-pipe cmd |

### Per-slice detail (Brief + acceptance)

- **0072.001 — `set-plan` composer.** Add `cmd_set_plan` to `roadmapper-gh-fields.sh`: idempotently
  re-compose `## Summary` + `---` + `## Plan` from four parts (summary, plan, marker, annotations); replace
  only the Summary/Plan sections; preserve `<!-- pipeline-plan-NNNN.SSS -->` + `Depends-on:`/`Touches:`
  **byte-exact**. Body written via `--body-file` stdin (no eval). *Accept:* self-test asserts structure,
  marker byte-exactness, annotation order-stability, and idempotent re-compose; `--self-test` in `.pipeline/verify`.
- **0072.002 — authored schema at create.** roadmapper §3.3-B composes Summary(blurb) + `---` +
  `## Plan`(`_plan pending — authored in plan mode_` stub) at create/enrich via the composer. *Accept:* new
  EPIC/PLAN bodies are well-formed; marker present; existing create/`set-body` self-tests still green.
- **0072.003 — plan-mode→issue pipe.** An explicit operator command (post-ExitPlanMode) resolving
  order→issue via `plan-issue` and calling `set-plan` to write the approved plan into `## Plan`; same verb
  serves reviewer re-sync. *Accept:* writes `## Plan` preserving Summary/marker/annotations; resolves by
  order (never issue# in dep tokens); graceful no-op when board unreachable.
- **0072.004 — branch/PR→issue resolver.** Pure classifier: PR#/current branch → order
  (`^pipeline/[0-9]{4}(\.[0-9]{3})?[-/]` or `Closes #N`) → `plan-issue`/`epic-issue` → issue#. *Accept:*
  resolves an order-carrying branch/PR; **fails closed** (empty+nonzero) on fork/renamed/missing/multiple —
  never guesses; self-test covers the regex + degenerate cases.
- **0072.005 — `lifecycle` wrapper.** `cmd_lifecycle <issue#> <transition>` mapping named transitions →
  status (`plan-approved`→To Do, `build-start`→In Progress, `review-start`→Review, `needs-revision`→Revise,
  `re-review`→Review, `merged`→Done, `drop`→Backlog) over `set-status`; one place owns the state machine.
  *Accept:* self-test asserts each transition → correct option string; unknown transition **fails closed**;
  project-scope-absent (preflight exit 3) → graceful degrade, never hard-fail.
- **0072.006 — wire build/merge.** builder Phase 0 → `lifecycle build-start` **standalone-only** (engine
  board-write is the documented "calamity" — hard-guard); the reserved Done sink → `lifecycle merged`.
  Issue# from the 0072.004 resolver. *Accept:* standalone emits In Progress + Done; **engine writes nothing**;
  every write a graceful no-op when board/`PROJECT_TOKEN` unreachable.
- **0072.007 — `Review` option + canonical list.** Add `Review` **via the GitHub web UI** (never the API —
  `updateProjectV2Field` option-edit orphans all Status values; the project-#4-wipe scar). Fix `gh-pipeline.sh:58`
  to `Backlog, To Do, In Progress, Review, Revise, Done, Delivered`. Ship a runbook recording the web-UI-only
  rule. *Accept:* field-list shows `Review`; canonical list reconciled; `set-status Review` lands; no item's
  Status wiped.
- **0072.008 — wire pr-review.** Emit `Review` between §1 gather and §2 fan-out; `Revise`/`Review(re)` at §4
  verdict; resolve issue# via 0072.004; on plan alteration call `set-plan` to re-sync `## Plan`. *Accept:*
  transitions fire at the right points; plan re-sync preserves marker/annotations; graceful gap-report (never
  hard-fail) when no issue/board/token.
- **0072.009 — plan-approved→To Do + canonicalize (CLOSES).** Plan pipe also emits `lifecycle plan-approved`
  (To Do); canonicalize `code-issue-pr-linkage.md` with the body schema + state machine as contracts; retire
  the stale A3 constraint; consolidate self-tests. *Accept:* approving a plan writes `## Plan` **and** flips
  To Do; full `To Do→In Progress→Review→(Revise⇄Review)→Done` demonstrated; hidden view never suppresses a
  true transition; all self-tests green.

## Shared-infra ownership · dependency DAG · serialization

**Owners:** `set-plan` composer = **0072.001**; `lifecycle` wrapper = **0072.005**; branch/PR→issue
resolver = **0072.004**; `Review` option + canonical list = **0072.007**. Consumers reuse, never rebuild.

**DAG / wave view (respecting file-collisions):**
- **Roots:** 0072.001 · 0072.004 · 0072.005 · 0072.007.
- **Wave 1:** 0072.001 (roadmapper-fields) ∥ serialized `gh-pipeline.sh` chain **[0072.004 → 0072.005 → 0072.007]**.
- **Wave 2:** [0072.002 → 0072.003] (roadmapper, serial) ∥ 0072.006.
- **Wave 3:** 0072.008 ∥ 0072.009.

> **⚠ HONEST-WAVES CORRECTION (from dogfooding CS3 on the authored board — finding F3).** The wave view
> above OVERSOLD parallelism. Honest file-level analysis (`fan-out-advisement.sh` on #338/#341/#342/#344):
> 0072.001/004/005 all touch `.pipeline/verify` and 004/005/007 all touch `gh-pipeline.sh`, so **real
> wave-1 = {0072.001, 0072.007} parallel; {0072.004, 0072.005} serialize.** To recover the intended
> parallelism, make the shared files SINGLE-WRITER — defer all `.pipeline/verify` self-test wiring and
> `code-issue-pr-linkage.md` canonicalization to the closing slice (0072.009), trading per-slice self-test
> gating for more parallel build. Otherwise build wave-1 serially. Decide at build time; the tool is
> authoritative over this prose.

**Must serialize (shared file — for honest CS3 fan-out):** `gh-pipeline.sh` {004,005,007}; `roadmapper-gh-fields.sh`
{001,002,003 — 001 first}; `roadmapper/SKILL.md` {002,003,009}; `code-issue-pr-linkage.md` {001,005,009 — 009 last}；
`.pipeline/verify` {001,004,005 — append-only, low-conflict}. **Freely parallel (single-writer):** `pr-review/SKILL.md`
(008), builder/agent files (006), the runbook (007). These become each slice's `Depends-on:`/`Touches:` annotations
so the fan-out advisement computes the waves honestly.

## Top risks (carry into every slice)

1. **Engine-vs-standalone split** — builder board-writes STANDALONE-only; an engine board-write is a documented calamity. 0072.006 hard-guards.
2. **Graceful no-op** — project-scope-absent (preflight exit 3) / no `PROJECT_TOKEN` / not-in-board-mode ⇒ advisory-skip + gap-report, **never hard-fail** (esp. the Done sink).
3. **Byte-exact marker + annotation preservation** under `set-plan` (dedup + CS3 both depend on it) — asserted directly in self-test.
4. **PR→issue for fork/renamed branches** — fail closed, never guess.
5. **Destructive option-add** — `Review` via web UI only; 0072.007 code touches *only* the line-58 array.
6. **Whole-body lost-update race** — `set-plan` re-reads → splices → rewrites whole; a concurrent human edit clobbers. Re-read immediately before write; note last-write-wins.
7. **Untrusted body data / two-number-space** — `set-plan` stays `--body-file` stdin (no eval); composed body never cross-links order#↔issue# (dep tokens stay orders; resolver converts at call time only).

## Verification (end-to-end)

- **Per slice:** hermetic `--self-test` wired `--self-test`-only into `.pipeline/verify` (mirror
  `gh-pipeline.sh --self-test` at `.pipeline/verify:34-37`). Body-composition test asserts structure + byte-exact
  marker + idempotent re-compose; lifecycle test asserts transition→option and unknown-fails-closed.
- **Live acceptance (after 0072.007's web-UI add):** run the full cycle on a throwaway board item —
  `plan-approved`→To Do, `build-start`→In Progress, `review-start`→Review, `needs-revision`→Revise,
  `re-review`→Review, `merged`→Done — and confirm `set-plan` round-trips a plan into `## Plan` with marker +
  annotations intact. Confirm a hidden board-view never suppresses a set transition.
- **Regression:** `.pipeline/verify` stays green throughout; existing roadmapper/gh-pipeline self-tests unaffected.

## Execution order (after approval)

1. **Author the board (dogfood):** run `/deliver:roadmapper` to create EPIC 0072 + the nine PLAN sub-issues
   (with `Depends-on:`/`Touches:` annotations above), seeded in Backlog. File any roadmapper gap as a bug/enhancement.
2. **Operator manual step:** add the **`Review`** single-select option to project #4 **via the GitHub web UI**
   (never the API). (This is 0072.007's non-code half; can be done up-front so live transitions work early.)
3. **Build the slices** per the wave view (each: `pipeline/0072.NNN-*` branch → test-first → PR → single
   reviewer → direct-merge → board Status + STATE update). Update the resume-memory + prove CLEAR-SAFE at each PLAN boundary.
4. **On close (0072.009):** re-sync EPIC 0072's own issue bodies into the new Summary+Plan format (first real
   dogfood of the pipe), then **resume EPIC 0071 CS4** (its STATE is untouched; CS4 is plan-locked, #331 in To Do).

## Critical files
- `scripts/roadmap/gh-pipeline.sh` (resolver, `cmd_lifecycle`, line-58 canonical list)
- `plugins/deliver/skills/roadmapper/scripts/roadmapper-gh-fields.sh` (`cmd_set_plan` composer)
- `plugins/deliver/skills/roadmapper/SKILL.md` (authored schema + plan-pipe verb)
- `plugins/deliver/skills/pr-review/SKILL.md` (+ `scripts/gather-diff.sh`) (Review/Revise + re-sync)
- `plugins/deliver/agents/ds-step-9-commit-push.md`, `plugins/deliver/agents/lifecycle-orchestrator.md` (Done sink), `plugins/deliver/skills/builder/SKILL.md` (In Progress)
- `plugins/deliver/knowledge/protocols/code-issue-pr-linkage.md` (canonical body schema + state machine)
- `.pipeline/verify` (self-test wiring)
