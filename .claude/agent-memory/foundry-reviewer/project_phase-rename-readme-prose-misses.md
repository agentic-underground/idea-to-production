---
name: phase-rename-readme-prose-misses
description: phase-pragmatic plugin renames (#264-267 wave) reliably miss README PROSE plugin-identity positions that CI cannot see — alt-text owning-plugin list, link TEXT (vs target), capability/graceful tables
metadata:
  type: project
---

The "name the plugin for its phase" rename wave (#264 market-scanner→discover, #265 ideator→ideate, #266 atelier→design, #267 security→secure) renames a plugin's machine identity while KEEPING the domain/capability word. A recurring UNDER-replacement class: **README prose plugin-identity positions that verify-prereqs.sh cannot gate.**

PR #267 (security→secure) shipped these four README misses while the gate was fully green:
- **README:3 masthead alt-text** "owning plugin (... security ...)" — the PR renamed the OTHER lowercase names in the SAME string (ideator→ideate, atelier→design) but left `security`; meanwhile docs/images/masthead.svg:77 visible SECURE-node label WAS updated to `secure`, so alt-text now contradicts its own image.
- **README:~94 plugin-tour table** `[security](plugins/secure/)` — link TARGET updated to plugins/secure/ but link TEXT left as `security` (self-contradicting link).
- **README:~128 capability table** `security (SECURE)` — col2 is lowercase PLUGIN name (siblings: `design (DESIGN)`); must be `secure (SECURE)`.
- **README:~135 graceful-enhancement table** `**security** | the SECURE gate runs` — bold col is plugin name (siblings `**ideate**`, `**design**`, `**publish**`); must be `**secure**`.

**Why:** these are token-scoped renames where the lowercase word is AMBIGUOUS — sometimes the kept domain/capability label, sometimes the plugin identity. Authors (and CI checks H/I/R, which validate PATHS + lifecycle rows, not prose link-text/alt-text wording) miss the identity positions. Same blind spot as [[project-rename-wordmark-alttext]] and [[project-market-scanner-to-discover-rename]].

**How to apply:** On ANY phase-rename PR, diff the IMMEDIATELY-PRIOR sibling rename's README treatment (e.g. #266 design) and demand byte-parity on: (1) masthead alt-text owning-plugin list, (2) plugin-tour table link TEXT not just target, (3) capability "Owner" table col2, (4) graceful-enhancement bold col, (5) domain-tree SVG alt-text companions list. The fix is mechanical; the catch is that the gate is green so the reviewer is the only backstop. KAIZEN: a `verify-prereqs` check that link TEXT matches the basename of `plugins/<x>/` link TARGET would kill the link-text variant systematically. Related: [[project-sentinel-to-security-rename]].
