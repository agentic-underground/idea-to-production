---
name: cluster-to-cluster-edge-clip
description: For a "cross-cuts the WHOLE cluster" group→group edge, orient ltail/lhead so the clip lands on the boundary FACING the other cluster, and set constraint=false so it can't distort ranks
metadata:
  type: feedback
---

To draw ONE edge that says "cluster A cross-cuts the whole of cluster B" (not a single
inner cell), `compound=true` plus `ltail=cluster_A, lhead=cluster_B` clips the edge to
both cluster boundaries. But the anchor NODES you name still decide WHICH wall the clip
lands on and how the line routes.

**Why:** Verified on 01-domain-tree. First attempt `pressroom -> cell_gov` with
`lhead=cluster_core, dir=back`: because cell_gov was the bottom-most core cell and
pressroom a corner companion, the clipped segment collapsed to a faint near-horizontal
stub that did NOT visibly touch the core boundary — it read as a single-cell link, the
exact thing the cluster anchoring was meant to avoid. Re-orienting to
`cell_pillars -> sentinel` (a mid-height core cell facing companions → a near companion),
`ltail=cluster_core, lhead=cluster_companions`, `constraint=false`, `penwidth=2.0` gave a
bold dashed arc springing cleanly off the green wall to the amber wall.

**How to apply:** (1) Pick anchor nodes that SIT ON the boundary facing the other cluster
(a mid-height cell on the near wall), not a far corner — the clip lands at the named node's
edge, so a far/low node drags the clip to a wall that doesn't face the target. (2) Always
add `constraint=false` on a cross-cut edge between two laid-out clusters, or newrank will
let it distort lane positions (here it also freed companions to reposition to a cleaner
top-right, improving the arc). (3) Bump penwidth (~2.0) — a dashed cross-cut on transparent
ground is faint; verify it on BOTH grounds, not just black. Edge label colour still follows
[[cluster-labels-dual-ground]] (saturated mid-tone, here #d6a463). See also
[[no-anchor-spine-with-clusters]] for rank interactions with clusters.
