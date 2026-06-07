# i2p Review — dogfood of the marketplace-review fixes          **Verdict:** PASS *(after fixes)*

**Scope:** `1f2298d..HEAD` — the change that fixed the original marketplace review (lifecycle re-org
separating ASSURE/SECURE, new `mission-control` OPERATE plugin, foundry reviewer overhaul + 6 new lenses,
independent DISCOVER/IDEATE challengers, doc propagation). 63 files, all md/sh/json/tsv.
**Lenses run:** CODE (foundry pr-review style — shell/JSON/prompt-coherence) · SECURITY (sentinel gate
style — secrets/PII/injection/portability) · INTEGRITY (lifecycle coherence, canonical copies, counts,
wiring). All adversarial; HIGH/CRITICAL refutation-verified. **Skipped:** DESIGN (no running SPA), rendered
DOCS (no PDF/figure artefact changed).

> This is a **dogfood** run — the marketplace's *own* reviewers (including the freshly-overhauled foundry
> reviewer) reviewing the change that built them. It worked: the panel caught a real CRITICAL I had
> introduced. That defect and all lesser findings are now fixed; this verdict reflects the **post-fix** state.

## Verdict rationale

The dogfood's **initial verdict was BLOCK** — the CODE lens found a surviving **CRITICAL**: the headline
"OPERATE → DISCOVER ↻" cyclic re-entry was promised across ~7 surfaces but `lifecycle.sh done OPERATE` was a
hard no-op ("OPERATE is terminal"), so the cycle was **inert in code**. SECURITY passed cleanly. INTEGRITY
found only LOW stale plugin-count enumerations. **All findings are now resolved** (commit below): the
wraparound + a cycle counter make the re-entry real (smoke-tested OPERATE → DISCOVER, cycle 2 ↻), and every
count/enumeration is consistent. No unresolved finding of any severity remains → **PASS**.

## Findings (all resolved)

| Severity | Lens | Locus | Finding | Resolution |
|---|---|---|---|---|
| **CRITICAL** | CODE | `lifecycle.sh` `done`/`advance` | `done OPERATE` treated OPERATE as terminal; the documented OPERATE → DISCOVER ↻ cycle never fired, contradicting product-lifecycle.md, the lifecycle SKILL, and 7 mission-control surfaces incl. `marketplace.json`. | **Fixed** — `next_phase()` wraps LAST→FIRST; `done`/`advance` at OPERATE advance to DISCOVER and `bump_cycle`; added a `cycle` field to the state + a `↻N` indicator in status and the statusline. Smoke-tested. |
| LOW | INTEGRITY | `i2p/skills/check/SKILL.md` | `/i2p-check` plugin table omitted mission-control (which ships `/check`). | **Fixed** — row added. |
| LOW | INTEGRITY+CODE | `i2p/.claude-plugin/plugin.json` (×2), `i2p/knowledge/covenant.md`, `i2p/skills/help/SKILL.md` frontmatter | Stale "six specialist plugins" (now seven). | **Fixed** — all → seven. |
| LOW | INTEGRITY | all 9 `*/hooks/inject-soul.sh:7` | Canonical comment said "byte-identical across all eight plugins" (now nine). | **Fixed** — updated identically across all 9; parity preserved (`verify-prereqs` Check F green). |
| LOW | CODE | `pr-review/SKILL.md` frontmatter | Description didn't mention the 6 new conditional lenses. | **Fixed** — frontmatter now lists them. |
| SUGGESTION | CODE | `pr-review/SKILL.md` CORRECTNESS lens | CORRECTNESS mapped to DOCUMENT-REVIEWER (doc-critique), so the primary code-correctness attack had no dedicated role. | **Fixed** — added a concrete **CORRECTNESS-REVIEWER** role to the reviewer agent (edge cases, error paths, concurrency, resources, contract fidelity) and remapped the lens to it. |
| SUGGESTION | CODE | `scorecard/marketplace-score.sh` | Portability metric excludes whole doc files (glossary, self-improve, scorecard dir), which could mask a future coupling. | **Accepted (rationale recorded)** — those are markdown/prose files that never execute, so they cannot introduce a *runtime* ~/.claude coupling; the metric targets live agent/hook/command/script surfaces. No change. |

## Per-lens verdicts

- **CODE — PASS** (was BLOCK). Shell correctness, JSON validity, and prompt/agent coherence all hold; the
  lone CRITICAL (cyclic re-entry) is fixed and smoke-tested. The reviewer's own new roles read as concrete,
  non-overlapping, and adversarial.
- **SECURITY — PASS.** No secrets, no newly-introduced PII (only the maintainer's GitHub noreply address as
  manifest metadata — legitimate, pre-existing pattern), no injection/exfiltration surface, zero `~/.claude`
  couplings in the new `mission-control` plugin.
- **INTEGRITY — PASS** (was NEEDS_REVISION). Canonical copies byte-identical across all 9 plugins; the
  8-phase lifecycle is consistent on every surface (the previously self-contradicting help doc included);
  done-wiring agrees end-to-end; all plugin-count enumerations now read nine/seven and include
  mission-control; challenger agents and the new reviewer roles are actually wired.

## What was NOT reviewed

- **No live SAST/secret-scanner or live SPA** was run — this is adversarial reasoning over shell/doc/json
  content (the appropriate lens for a prompt/doc/shell marketplace), not an automated SAST pass or a
  browser crawl. Git-history (committed-then-reverted secrets) was not scanned — out of scope for a
  doc-only diff.
- **The reviewers themselves are prompt-level capabilities** — this run exercised the overhauled foundry
  reviewer *by enacting its process*, but the new roles (CORRECTNESS, API-CONTRACT, etc.) and
  `mission-control`'s skills have not yet run against a real production diff or live service.

*The original pre-fix marketplace review is archived at `doc/historical/I2P_REVIEW-2026-06-07.md`.*
