---
name: knowledge-phase-resolver
description: EPIC 0067.003 resolve_knowledge_phase.py semantics + the --list doc/code gap; context for reviewing 0067.004 leanness gate
metadata:
  type: project
---
`scripts/context/resolve_knowledge_phase.py` (PLAN 0067.003, PR #298) resolves every
`plugins/*/knowledge/**/*.md` to a phase: own `metadata.phase` → union of same-plugin SKILL referrers
(cross-cut referrer wins; doc→doc refs don't propagate; agents unphased→`ambiguous`) → orphan.

**Why:** feeds the 0067.002 pointer + the 0067.004 leanness/coverage gate (`verify-context.sh`, not built yet).

**How to apply when reviewing 0067.004 or changes here:**
- Reference detection is a plain substring match of `knowledge/<rel>` in skill text. The `.md` right-anchor
  makes prefix collisions SAFE (`knowledge/solid.md` does NOT match a ref to `knowledge/solid-extra.md` —
  verified). But it over-attributes on negations / code-fence mentions (a skill saying "do NOT read
  knowledge/x.md" still gives x.md that skill's phase), and block-style YAML `phase:\n  - X` is NOT parsed
  (regex needs inline `[..]`) → doc silently `ambiguous`. No live skill uses block style; fails safe (flags).
- `--check` only asserts non-empty phases, NOT correctness of the inherited set — green `--check` ≠ correct phases.
- Real counts: 84 resolved modules (89 files − 5 READMEs; READMEs excluded), 58 inherited + 26 own, 0 flagged.
  PR body/RFC/docstring say "89 modules / 59 inherited" — off (89=file count, 58≠59). Doc-only.
- **`--list` is documented (RFC §3.4, packet, docstring) but is NOT a registered arg → errors exit 2.**
  Bare invocation is the list mode. If 0067.004 or docs invoke `--list`, they break. Flag until fixed.
- Self-test is hermetic (runs on `scripts/context/fixtures/knowledge-phase/`, not the real tree) and
  non-tautological. Only in-repo caller is `--self-test` in `.pipeline/verify`.
