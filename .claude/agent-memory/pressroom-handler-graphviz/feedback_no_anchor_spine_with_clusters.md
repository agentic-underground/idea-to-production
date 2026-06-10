---
name: no-anchor-spine-with-clusters
description: Don't force a tall TB tree with invisible point-anchor spines when a subgraph cluster is also present — the anchor rank=same groups collide with the cluster's own ranks
metadata:
  type: feedback
---

When making a `rankdir=TB` tree taller by stacking role tiers, do NOT use invisible
`shape=point` anchor nodes wired into a vertical spine with `rank=same` tiers hung off
each anchor. If the same graph also contains a `subgraph cluster_*`, the cluster imposes
its own rank constraints and the anchor ranks fight them: tiers stop being clean
horizontal bands and a lower plugin tier gets dragged down beside the cluster instead of
sitting in its own row.

**Why:** Verified on 01-domain-tree-A. An invisible anchor spine + `{rank=same; ...}` per
tier produced a left-shifted tangle where the 4 companion plugins collided with the
7-leaf foundry cluster rank. Removing the anchors and using plain `root -> child` edges
plus per-tier `rank=same` (no spine) gave a clean layout; the cluster leaves were then
stacked into a tidy single column via an invisible `a -> b -> ... [style=invis, weight=10]`
ordering chain, parented by ONE visible edge `foundry -> f_head`.

**How to apply:** For a big TB tree with a cluster sub-structure: (1) let `root -> plugin`
edges + `rank=same` set the upper tiers, no invisible spine; (2) inside the cluster, stack
leaves in a single column with one invisible weighted ordering chain; (3) connect the
cluster to its parent with a single visible edge into the head leaf — this keeps it a tree
and avoids a 7-way fan-out tangle. See also [[rank-vs-weight-lr]] for when rank=same is the
wrong tool. Note the ≤4-across matrix floor still bites a 7-plugin root fan — accent-group
the row by role to keep it readable, or split into two rows if width budget is tight.
