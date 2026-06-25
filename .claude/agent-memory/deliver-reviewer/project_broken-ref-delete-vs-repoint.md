---
name: broken-ref-delete-vs-repoint
description: Deleting a broken image/link ref when the target asset actually EXISTS (wrong path, not missing) orphans a real reviewed asset; check disk before accepting a delete-the-ref fix
metadata:
  type: project
---

When a "remove broken image ref" PR lands, the broken ref may be a **wrong path to an asset that exists**, not a ref to a missing file. Deleting the ref then orphans a real, reviewed asset instead of fixing the link.

Concrete (PR #253, commit f81957e):
- `docs/guide/context-building-pipeline.md` removed `![…](diagrams/01-context-doors.png)`. That path was wrong (resolves to `docs/guide/diagrams/` which doesn't exist), BUT the asset exists at `docs/diagrams/01-context-doors.png` (+ `.svg` source), git-tracked, marked `status: done` (composition BEST 88) in `.publish/illustration-ledger.json`. Correct fix was `../diagrams/01-context-doors.png`; the PR deleted the figure instead → asset now referenced by ZERO docs (orphaned). MEDIUM.
- `plugins/operate/README.md` removed `![…](../../docs/images/operate-operate.gif)` — that GIF genuinely never existed. Operate is the ONLY plugin missing its hero gif; all 7 siblings have one (i2p-frontdoor, deliver-conveyor, publish-press, design-critique, ideate-converge, discover-radar, sentinel-gate). Not in ledger/memory as planned → not a premature fix, but the asymmetry is the real gap.

**Why CI didn't catch either** (verify-prereqs.sh Check I): checked extensions are `.md .sh .tsv .json .svg .png` — **`.gif` is NOT checked**, so the operate gif ref was never validated. And Check I's scan roots are `plugins/**` + `PREREQUISITES/*.md` + root `*.md` ONLY — **`docs/guide/` is out of scope**, so the .png ref was never validated either. Gate was green before AND after; removal changed no CI outcome.

**How to apply:** On any "delete broken ref" PR, before accepting: `find` the basename on disk. If the asset EXISTS, the fix is re-point the path, not delete the figure — flag delete-instead-of-repoint as MEDIUM (orphans a reviewed asset; cross-check `.publish/illustration-ledger.json` status). Two Check-I blind spots to remember: `.gif` unchecked, `docs/` tree unscanned.
