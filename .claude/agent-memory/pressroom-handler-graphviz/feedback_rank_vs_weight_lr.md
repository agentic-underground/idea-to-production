---
name: rank-vs-weight-lr
description: In rankdir=LR, fix a vertical jog with edge weight, never rank=same (which collapses the spine into a vertical stack)
metadata:
  type: feedback
---

To flatten a vertical jog in a `rankdir=LR` linear spine, add high `weight=100` to
the spine edges — NOT `{rank=same; ...}`.

**Why:** A sequential `a -> b -> c` chain puts each node on its own rank. In LR, a
rank is a vertical column, so `{rank=same; <all spine nodes>}` forces every node into
ONE column and the figure collapses from a left→right flow into a top→bottom stack.
Verified on 01-value-flow-A: rank=same produced a vertical stack; reverting to
`weight=100` per spine edge produced the intended flat horizontal baseline.

**How to apply:** The jog in a horizontal spine is usually caused by a
`constraint=false` return/loop edge nudging ranks. Counter it by weighting the main
spine edges so the loop edge cannot pull nodes off the baseline. Reserve `rank=same`
for genuinely parallel siblings, not for a sequential chain.
