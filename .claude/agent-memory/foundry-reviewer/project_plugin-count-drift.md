---
name: plugin-count-drift
description: Hardcoded plugin-count numbers in docs/figures drift from the live set (nine); prefer count-agnostic phrasing
metadata:
  type: project
---

The marketplace has **nine** plugins (atelier, concierge, foundry, i2p, ideator, market-scanner, mission-control, pressroom, sentinel). Each ships a byte-identical SOUL.md (CI Check E) and inject-soul.sh (CI Check F) — verify-prereqs.sh §E/§F.

Recurring defect: docs and embedded figures hardcode a stale multiplicity. context-building-pipeline.md said "six" (prose L73/74/107) and figure 02 rendered "×6 / 6 callers race / never 6×" in both image and alt text. The canonical inject-soul.sh even disagrees with itself (header "all nine plugins" vs L34 "8 hooks / 8x").

**Why:** the count is a hardcoded constant copied into prose, PNG pixels, and alt text — three places that drift independently when a plugin is added/removed.
**How to apply:** when reviewing docs/figures that count plugins or hook copies, verify against `ls plugins | wc -l` (currently 9). Push count-agnostic phrasing ("every installed plugin", "one winner", "never duplicated") instead of a literal number — flagged for the KAIZEN covenant. CI parity check letters (verify-prereqs.sh): **E** = SOUL.md, **F** = inject-soul.sh, **N** = KAIZEN.md (10 copies incl. root), **O** = inject-kaizen.sh (9 copies). Do NOT swap these. Note: G=requirements.tsv no-download, H=marketplace.json⟺plugins — so a hook header citing "Check G/H" for the KAIZEN banner is a stale wrong cross-ref (should be N/O); the inject-kaizen.sh canonical copy shipped with exactly this bug (header line 9). The SOLID→KAIZEN covenant rename landed (file renamed knowledge/architecture/solid-covenant.md → kaizen-covenant.md; root KAIZEN.md banner mirrored into all 9 plugins).
