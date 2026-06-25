---
name: pressroom-knowledge-scaffold
description: pressroom plugin lacks deliver's knowledge/ tree — handlers copied from deliver templates import broken knowledge links
metadata:
  type: project
---

When a new pressroom value-handler is authored by copying a deliver handler template
(e.g. deliver/agents/handler-rust.md), the deliver knowledge-link scaffold gets imported
wholesale but **pressroom does not ship those files**.

pressroom/knowledge/ contains only: covenant.md, inspection-core.md, raster-toolchain.md,
comfyui-model-guide.md, comfyui-workflows/. It has NO pillars/, protocols/, tooling/,
testing/, architecture/ dirs and NO first-principles.md.

So these deliver refs are BROKEN in pressroom: implementation-covenant.md,
certainty-markers.md, live-feedback.md, first-principles.md, test-policy.md,
pure-core.md, determinism-and-pinning.md, architecture/kaizen-covenant.md.

**Why:** self-contained plugins (CLAUDE.md) — ${CLAUDE_PLUGIN_ROOT} for pressroom is the
pressroom dir. The canonical-copy promise (verify-prereqs checks A/N/O) only syncs
KAIZEN.md, check.sh, inject-kaizen.sh — NOT knowledge files.

**How to apply:** Sibling pressroom handlers (handler-chart/mermaid/graphviz) correctly
keep the covenant local ("Carries the KAIZEN covenant") with NO cross-plugin knowledge
links. The covenant link should target pressroom/knowledge/covenant.md. CI Check I
("internal doc links resolve") FAILS the relative ../knowledge/ links but SKIPS
${CLAUDE_PLUGIN_ROOT}/* — so PLUGIN_ROOT-style broken refs pass CI yet trip a cold-start
spawned agent at runtime. Flag both kinds. Relates to [[plugin-count-drift]].
