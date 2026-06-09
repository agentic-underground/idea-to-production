---
name: cluster-labels-dual-ground
description: Cluster labels and HTML sub-text on transparent ground must use saturated mid-tones, NOT canon #e6e9f0/#b8bed0 (which wash out on white)
metadata:
  type: feedback
---

The dark-mode canon node-text colors `#e6e9f0` (label) and `#b8bed0` (sub-text) are
designed for text sitting on a **filled dark node**. On a Graphviz **cluster label** or
an HTML-label `<font>` over a transparent cluster background, that text floats directly
on the host ground — so on a near-WHITE host it washes out and fails the dual-ground gate.

**Why:** A node has `fillcolor="#1e1e2e"` behind its text, guaranteeing contrast on both
grounds. A cluster has a transparent interior (canon forbids opaque full-bleed fills), so
its `fontcolor` label sits on white *or* black. `#e6e9f0` against white is invisible.
Verified on 01-orchestration-hierarchy-B: founder/builder-lead/lifecycle/EXECUTION cluster
titles in `#e6e9f0` vanished on the white card; the reviewer node (filled) survived.

**How to apply:** For text that sits on a transparent ground (cluster labels, edge labels,
HTML sub-text in cluster labels) use **saturated mid-tones** that clear both grounds:
- cluster title (named altitude): an accent works — accent-1 `#7aa2f7`, or slate `#8b93c8`
- sub-text / descriptive lines: `#7c84b8`
- accent edge labels: darken the light-lavender `#d6c8ff` to `#9d7fd6`
Keep `#e6e9f0`/`#b8bed0` ONLY for text inside filled nodes. Do NOT try to fix this with a
low-alpha cluster `fillcolor` — nested translucent fills compound per layer and stay weak
on white while muddying black.
