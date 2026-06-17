---
description: Consolidated readiness — run every installed idea-to-production plugin's /check and merge the ✓/✗ results into one table by plugin, with a short summary of what's missing and how to install it.
---

Run the marketplace-wide dependency check. Follow the [`check` skill](../skills/check/SKILL.md):

1. For each **installed** plugin that ships a `/check` (market-scanner, ideator, foundry, atelier,
   security, pressroom, operate), run it — pass `$ARGUMENTS` through (e.g. `--strict`, `--tier=recommended`).
2. Consolidate every ✓/✗ row into **one table grouped by plugin**, then summarise what is missing and
   how to install it (point at the marketplace `PREREQUISITES/` folder and the per-row hints).
3. Name any plugin that is **not** installed so the picture is complete.

This is advisory — a missing tool narrows a capability, it does not break the marketplace. With
`--strict`, report a non-OK overall status when any **required** tool is missing.
