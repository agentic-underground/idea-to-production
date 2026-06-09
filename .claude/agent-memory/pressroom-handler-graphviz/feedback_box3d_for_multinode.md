---
name: box3d-for-multinode
description: To depict an N-instances "stacked multi-node" (e.g. ×6 copies), use shape=box3d — NOT a rank=same shadow twin (which lands beside, not behind)
metadata:
  type: feedback
---

To draw a "stacked multi-node" / fan-of-N (e.g. "plugins/<each>/SOUL.md ×6" — one
canonical thing copied into many slots), set `shape=box3d` on that node. It renders a
built-in stacked-card silhouette (offset double edge on top/left) that reads as
"multiple instances" on both dark and white grounds.

**Why:** The intuitive trick — a faint offset twin node pinned with `{rank=same; real; shadow}`
plus an invis edge — does NOT stack behind; rank=same forces the twin into the SAME ROW,
so it lands *beside* the real node, wasting horizontal budget and reading as two separate
cards. Verified on 02-soul-sentinel-A: rank=same shadow produced side-by-side; box3d
produced the intended stacked-card look in one attribute, no extra nodes/edges.

**How to apply:** box3d ignores rounded corners (`style="filled,rounded"` warns/degrades),
so set `shape=box3d, style=filled` on just those nodes while the rest keep rounded boxes.
It still honors `fillcolor`, `color`, `penwidth`, and HTML labels. Keep the count badge
(e.g. an accent "×6") in the label for unambiguity — the silhouette implies many, the
badge names the number.
