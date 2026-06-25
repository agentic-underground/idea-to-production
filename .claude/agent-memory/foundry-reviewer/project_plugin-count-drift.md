---
name: plugin-count-drift
description: Hardcoded plugin-count numbers in docs/figures drift from the live set; prefer count-agnostic phrasing. As of flow-retirement (PR #150) the count is EIGHT.
metadata:
  type: project
---

The marketplace has **eight** plugins as of 2026-06 (i2p, discover, ideator, foundry, security, publish, atelier, operate) — the in-repo `flow` plugin (DELIVER + flow-mcp Ruby server) was RETIRED in PR #150, DELIVER re-homed to `foundry:roadmapper` + the external FLEET `pipeline` engine. CLAUDE.md says "eight composable plugins (i2p + seven specialists)"; marketplace.json lists 8 sources. (Older memory said nine with different plugin names — that snapshot is superseded; verify against `grep '"source": "./plugins/' .claude-plugin/marketplace.json | wc -l`.) Each ships a byte-identical KAIZEN.md (CI Check N) and inject-kaizen.sh (CI Check O) — verify-prereqs.sh §N/§O.

**PR #150 lesson (flow retirement count-drift):** the editor deleted the flow row from README's plugin table (→ 8 rows) and updated CLAUDE.md to "eight", but left README's prose "nine composable / Nine plugins / all nine plugins" (L7, L72, L80, L179), SLASH_COMMANDS L3 "across its nine plugins", and the masthead alt-text (L3, still naming `flow` as DELIVER owner) un-decremented. Classic: count lives in prose + table + figure alt-text, which drift independently. When reviewing a plugin add/remove PR, grep ALL of: `nine|eight|seven specialist|all (nine|eight)`, the masthead/figure alt-texts, and any per-phase owner list.

Recurring defect: docs and embedded figures hardcode a stale multiplicity. context-building-pipeline.md said "six" (prose L73/74/107) and figure 02 rendered "×6 / 6 callers race / never 6×" in both image and alt text. The canonical inject-soul.sh even disagrees with itself (header "all nine plugins" vs L34 "8 hooks / 8x").

**Why:** the count is a hardcoded constant copied into prose, PNG pixels, and alt text — three places that drift independently when a plugin is added/removed.
**How to apply:** when reviewing docs/figures that count plugins or hook copies, verify against `ls plugins | wc -l` (currently 9). Push count-agnostic phrasing ("every installed plugin", "one winner", "never duplicated") instead of a literal number — flagged for the KAIZEN covenant. CI parity check letters (verify-prereqs.sh): **A** = check.sh, **N** = KAIZEN.md (10 copies incl. root), **O** = inject-kaizen.sh (9 copies). Do NOT swap these. (SOUL.md/inject-soul.sh and their Checks E/F were retired.) Note: G=requirements.tsv no-download, H=marketplace.json⟺plugins — so a hook header citing "Check G/H" for the KAIZEN banner is a stale wrong cross-ref (should be N/O); the inject-kaizen.sh canonical copy shipped with exactly this bug (header line 9). The SOLID→KAIZEN covenant rename landed (file renamed knowledge/architecture/solid-covenant.md → kaizen-covenant.md; root KAIZEN.md banner mirrored into all 9 plugins).
