---
name: checkp-epic-floor-rekey
description: PR #242 re-keyed verify-prereqs check P so the EPIC Branch/## Plans grammar floor runs whenever EPIC docs exist (board OR manifest), not gated on the manifest file
metadata:
  type: project
---

PR #242 retired `docs/roadmap/.pipeline.md` (board is authoritative). The original check P (§P) gated
its ENTIRE on-disk grammar block behind `if [ -f "$manifest" ]`, so deleting the manifest would have
silently stopped validating the live roadmap (my prior REGRESSION/DOCUMENT coverage-gap finding). The
revision split it:
- `epics_present=0; ls docs/roadmap/EPIC_*.md … && epics_present=1`
- manifest rows: still `if [ -f "$manifest" ]` (manifest/local_file mode only — absence is valid).
- EPIC `**Branch**` scrape + `## Plans` order|plan|state grammar: now `if [ "$epics_present" -eq 1 ]`
  (runs in BOTH modes) — the live-roadmap grammar floor that survives manifest retirement.
- mode-aware pass message (manifest / board-mode / no-roadmap).

**Verified (board mode, manifest absent, CI-like HOME with no FLEET oracle):**
- current tree → check P PASS via board-mode branch ("board-mode roadmap: EPIC docs conform …"), 13 EPICs.
- NEGATIVE: corrupting an EPIC `**Branch**` → check P FAILS (exit 1). Floor has teeth.
- BACK-COMPAT: restoring a manifest → validates manifest rows AND EPIC floor; corrupt order row → FAIL.

**Subtlety (don't re-flag as a lost check):** the BASE comment said the EPIC Branch "equals the
manifest's branch cell," but the base CODE never enforced that cross-check — it only asserted the
scrape is non-empty. So the revision lost no real check; the per-EPIC loop body is byte-identical
base↔head. Only the GATING condition changed (widened, never narrowed).

The pre-existing local-only vendored-standard DRIFT failure (references/fleet-pipeline-standard.md stale
vs installed FLEET) is gated on a same-version live oracle being present; skipped in CI. Unrelated.
See [[fleet-v2-roadmap-migration]], [[board-mode-forbidden-mutation-default]].
