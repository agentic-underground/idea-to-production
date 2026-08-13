---
description: Pipe an approved plan-mode plan onto its board issue — resolve a roadmap ORDER (NNNN.SSS) → issue and write the plan into `## Plan`, preserving Summary/marker/annotations. Also the reviewer re-sync verb. Graceful no-op when the board is unreachable.
---

Pipe an approved plan onto the GitHub board — the explicit post-`ExitPlanMode` (and reviewer re-sync)
step of PLAN 0072.003. `$ARGUMENTS` is the roadmap **order** to sync (`NNNN.SSS` for a PLAN, `NNNN`
for an EPIC) — **an order, never a GitHub issue number** (the two-number-space hazard: a `Depends-on:`
token and a sync target must speak the same space).

Use it when a plan-mode session just approved the plan for a board item, or when an adversarial review
altered a plan and the issue's `## Plan` must be brought back in sync.

1. **Capture the approved plan.** Write the just-approved plan-mode plan (or the reviewer-revised plan)
   to a temp file, e.g. `/tmp/approved-plan-<order>.md` — the Markdown that should become the issue's
   `## Plan` section (no `## Summary`, no marker — the composer supplies those). Optionally also write a
   `## Summary` blurb to a second temp file if the Summary should change too (usually it should not — a
   reviewer edits the Plan, not the Summary).

2. **Pipe it in by order.** Run the resolver+composer (it needs `PIPELINE_PROJECT=<registry-key>` in the
   env, like every §3.3-B verb):
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/roadmapper/scripts/roadmapper-gh-fields.sh \
     sync-plan <order> /tmp/approved-plan-<order>.md [summary-file]
   ```
   It resolves the **order → issue** via the pipeline marker (`plan-issue`/`epic-issue`), then writes the
   plan into `## Plan` through the composer — **preserving the `## Summary`, the `<!-- pipeline-… -->`
   marker, and the `Depends-on:`/`Touches:` trailer byte-exact**.

3. **Read the outcome and report it honestly.**
   - `issue #<n> plan synced (marker preserved)` — the plan is now on the board item; state the issue it
     resolved to.
   - `… not resolvable on the board (unreachable or absent) — plan-sync skipped (no-op).` — a **graceful
     no-op** (exit 0): the board is unreachable or the order isn't on it. The plan is **not** lost — say
     so, and that it can be re-run once the board is reachable / the item exists. Never present a no-op as
     a success.
   - `'<arg>' is not a roadmap order …` (exit 2) — a **usage error**: you passed something that isn't an
     `NNNN`/`NNNN.SSS` order (likely a bare GitHub issue#). Re-invoke with the roadmap order.

This command **writes** to the board; it does not merge or promote. Promotion to `To Do` is the separate
human-gated gesture (§11.4a). Degrades cleanly with no `gh`/board — the no-op path above.
