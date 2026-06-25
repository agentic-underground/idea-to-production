---
name: operate-gif-parity-gap
description: operate README is the only specialist missing its 2nd concept GIF (operate-operate.gif never authored); CI link-check is .gif-blind
metadata:
  type: project
---

PR #253 removed the broken `![…](../../docs/images/operate-operate.gif)` ref from
`plugins/operate/README.md` (and a `diagrams/01-context-doors.png` ref from
`docs/guide/context-building-pipeline.md`).

**RESOLVED (amended PR #253, commit 03d88b6, re-reviewed 2026-06-24):** the orphan defect
is fixed. An earlier pass had PASSed on the wrong basis (said both targets "never existed"),
missing that the context-doors asset is REAL at `docs/diagrams/01-context-doors.png` (241KB,
git-tracked, ledger `status: done` composition BEST 88) and the ref was just a wrong relative
path. The amended PR now REPOINTS rather than deletes: `docs/guide/context-building-pipeline.md:45`
references `../diagrams/01-context-doors.png`, which resolves to the real file (verified via
`ls docs/guide/../diagrams/01-context-doors.png` → same 241445-byte file). The dead
`operate-operate.gif` ref is correctly removed (file never authored). Final verdict on amended
PR: **PASS**. Caveat for future reviews: CI verify-prereqs (Check I) does NOT scan `docs/`, so
green CI does not validate this path — the manual `ls` through the relative path is the
load-bearing evidence. See [[broken-ref-delete-vs-repoint]] for the delete-vs-repoint class.

Residual parity gap (KAIZEN follow-up, NOT a gate on a ref-removal PR): **operate is the
only specialist plugin README without a second concept/loop GIF after its banner.** All
siblings carry one AND the asset exists on disk:
- foundry → foundry-conveyor.gif (README:12)
- ideate → ideate-converge.gif (:11)
- discover → discover-radar.gif (:11)
- publish → publish-press.gif (:11)
- secure → sentinel-gate.gif (:11)
- i2p → i2p-frontdoor.gif (:8)
- design → design-critique.gif

**Why:** the operate concept GIF was simply never authored. **How to apply:** if a future
PR claims to "complete" operate's README or restore visual parity, the real fix is
authoring `docs/images/operate-operate.gif` + re-adding the ref — don't accept the parity
gap as resolved without the asset on disk.

CI blind spot (systemic): `scripts/verify-prereqs.sh` link-check only validates extensions
`.md .sh .tsv .json .svg .png` (lines ~304/337) — **`.gif` is NOT checked**, so broken GIF
refs ship green and only get caught by hand. Adding `.gif` to that extension set would
catch this class automatically. Relates to [[project_archive-move-redirect-class]] and
[[project_checkI-fence-blinding]] (link-check coverage gaps).
