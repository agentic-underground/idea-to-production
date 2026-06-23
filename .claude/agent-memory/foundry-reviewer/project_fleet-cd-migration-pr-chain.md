---
name: fleet-cd-migration-pr-chain
description: FLEET-CD migration is a staged PR chain (PR-3 emit v2 #147, PR-4 FOUNDRY PLAN-scope, PR-5 trigger re-route #149, PR-6 flow retire, PR-7 legacy migration); each stage must retire the forward-ref notes the prior stage wrote
metadata:
  type: project
---

The FOUNDRY roadmapper/builder v2 (FLEET continuous-delivery) cutover ships as an ordered PR chain:
- **PR-3 (#147)** — roadmapper emits v2 artifacts (`.pipeline.md` + EPIC_/PLAN_), models authoring as a value task. Deferred build *dispatch* to "later PRs" via forward-ref notes in roadmapper §1, §3.3 (sequencing), §3.4, §6.
- **PR-4** — FOUNDRY PLAN-scope entry (builder §2.5; engine-mode `ds-step-9-commit-push`, no push/STATUS).
- **PR-5 (#149)** — re-route GO/build triggers to engine kick-off for v2 (roadmapper §2/§10/§11.2/§11.3/§11.4/§11.8, builder §1).
- **PR-6** — flow retirement (incl. `/flow:pull` value-handler re-routing).
- **PR-7 (#151) — MIS-FILE, REVERSED by #153.** Filed the migration as engine-built `EPIC_0003`
  (PLAN_0004..0009 whose Construction process appended manifest rows + emitted EPIC docs). My #151
  review PASSED it on doc-conformance (49/49 covered, ids contiguous, check P green) but MISSED that
  the construction process VIOLATES the engine's forbidden-mutation guard — the build agent may not
  edit `.pipeline.md` or the EPIC doc. The live engine calamitied on it (log: `epic 0003 plan 0001:
  loop=CALAMITY (agent modified a forbidden path)`, CALAMITY #2; breaker paused). GEMBA MISS:
  **conformance-green is NOT build-viable.** New chain-checklist item — for any authoring/migration
  EPIC, check the PLAN `## Construction process` against the engine's forbidden paths (manifest +
  active EPIC doc), not just check P.
- **PR-8 (#153) — the fix. VERIFIED CLEAN, PASS.** Removes EPIC_0003 + PLAN_0004..0009 + manifest
  row; adds docs/roadmap/LEGACY-BACKLOG.md framing migration as in-session /roadmapper §3.5 authoring
  (decision D3: engine only consumes finished, conformance-passing docs — SKILL.md:326-332). Proof:
  forbidden_mutation=`docs/roadmap/.pipeline.md` (register-with-fleet.sh:35, live registry), v2 build
  also forbids epic doc (builder.sh:545 `FORBIDDEN_EXTRA`); guard at builder.sh:357-366. All 49
  backlog items covered exactly in LEGACY-BACKLOG batches (no drop/phantom/dupe, python-verified);
  manifest holds only EPIC_0001 completed; check P + .pipeline/verify exit 0; engine `next` → "(no
  available item)"; no dangling EPIC_0003/PLAN_000[4-9] refs in live surfaces (only the intentional
  mention in LEGACY-BACKLOG.md:8); PLAN_0002 correctly owned by EPIC_0001 (not orphaned);
  register-with-fleet.sh + governance.md carry no migration-EPIC refs. Residual (non-blocking,
  outside diff): source branch `origin/feat/register-pipeline-migrate-backlog` lingers but its diff
  vs main is empty; engine-state cleanup done out-of-band per PR body.

External **`pipeline` plugin** (FLEET marketplace) confirmed installed at
`~/.local/share/fleet/pipeline-marketplace/pipeline/`. Commands exist: run, status, stop,
unattended, new, timer. `scripts/pipeline-cron.sh` dispatches `build|status|next|run|stop|
unattended|next-plan|...`; `build` execs `builder.sh build <NNNN>`. Plan-build prompt
(`_render_plan_build_prompt`) reads "this plan's Construction process" → PLAN doc's
`## Construction process` → "invoke FOUNDRY scoped to (EPIC,PLAN)" = builder §2.5. Chain verified live.

**Why:** Self-contained plugin; the external pipeline plugin is correctly labelled "external" (like token-fairness), not shipped in this marketplace.

**How to apply:** RECURRING DEFECT CLASS — when reviewing PR-N of this chain, grep the touched
skills for "later PR" / "lands with" / "still deferred" / "still drive" / "trigger-dispatch PR"
forward-refs written by an EARLIER stage. The PR that *fulfills* a deferral MUST retire the note that
announced it, or the doc self-contradicts (a fresh agent reads "GO = engine kick-off" in §11.4 yet "§11
GO-mode still drives the legacy flow, re-routing lands later" in §1). PR #149 left FOUR such stale
notes (§1 L50-53, §3.3 L221-227, §3.4 L322-323, §6 L601-602). Flag as a gemba/KAIZEN systemic gap:
add a chain-stage checklist item "retire the forward-refs this stage fulfills."
