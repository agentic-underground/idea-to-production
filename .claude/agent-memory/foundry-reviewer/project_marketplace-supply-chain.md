---
name: marketplace-supply-chain
description: Recurring supply-chain risk class in the idea-to-production marketplace — unpinned third-party executables shipped/recommended by plugins
metadata:
  type: project
---

The marketplace repeatedly ships or recommends floating/unpinned third-party code execution. Same root cause across MCP configs and Ansible provisioning fragments.

Instances seen (branch `empower-marketplace`, reviewed 2026-06-03):
- `plugins/foundry/.mcp.json` → `npx -y @playwright/mcp@latest` (unpinned npm)
- `plugins/sentinel/.mcp.json` → `uvx semgrep-mcp` (unpinned PyPI, on the secure plugin)
- `PREREQUISITES/ansible/core-bootstrap.yml` → `curl … | sh` for rustup/uv/Volta
- `PREREQUISITES/ansible/binaries.yml` → `osv-scanner` from `releases/latest`, piped `install.sh` for gitleaks/trivy/grype/syft (no checksum)
- `zig` IS correctly pinned (0.13.0) — the model for the others.

**Why:** registry/CDN compromise or malicious publish → arbitrary code as the user; `@latest` also kills reproducibility. Bounded because Ansible fragments are opt-in and docs say "pin in production", but the MCP `.mcp.json` ships in the plugin.

**How to apply:** On any future review touching `.mcp.json` or `PREREQUISITES/ansible/`, flag unpinned `@latest`/bare-package/`releases/latest`/`curl|sh` as a supply-chain finding. Push for the systematic fix (a "pin + checksum every externally-fetched executable" rule) rather than per-site patches — see [[feedback-approval-gate-claim]].

Also watch the approval-gate safety claim in `PREREQUISITES/40-mcp.md` / `live-feedback.md`: it states "does not silently auto-run" as absolute, but is false under `enableAllProjectMcpServers`/pre-approval/`--dangerously-skip-permissions`. Must be qualified.

**Re-review 2026-06-03 (2nd commit `2800b89`):** dispositions accepted, verdict PASS-with-LOW.
- `40-mcp.md` NOW qualifies the gate ("approval-gated **under default permissions**… not an absolute guarantee") and adds explicit pin-for-provisioning guidance. Adequate. The unpinned `@latest`/`uvx semgrep-mcp` in committed `.mcp.json` is judged ACCEPTABLE (not a blocker) for a shipped plugin: approval-gated by default, matches upstream zero-config docs, disposition is honest. Residual LOW: hard-pin would still be stronger.
- gitleaks moved to a pinned tarball (good). REMAINING unpinned-by-design and accepted as LOW (all opt-in, tagged `optional`, doc says "pin in production"): `osv-scanner` releases/latest (no checksum); trivy/grype/syft `curl|sh` install scripts (no checksum); core-bootstrap rustup/uv/Volta `curl|sh`. Pin+checksum still the recommended systematic hardening.
- `check.sh` `bash -c "$probe"`: ACCEPTABLE. tsv default is `${here}/../requirements.tsv` (in-repo trusted); never auto-loads a tsv from the scanned/untrusted project dir — only an explicit positional arg overrides it (= user-initiated, same trust as running bash). No untrusted-tsv path.
- `live-feedback.md` §1 still says "one-time approval" without the permissive-mode caveat — minor doc inconsistency vs 40-mcp.md, LOW.

**Deep-relative-link regression (arch re-review 2026-06-03):** The `../../../../PREREQUISITES/` fix only scrubbed the two NAMED files (`live-feedback.md`, `prerequisites/SKILL.md` — both now source-tree-only phrasing, correct). The SAME fragile clickable deep link was (re)introduced in newly-added files the fix never swept: `plugins/{foundry,sentinel,pressroom}/skills/check/SKILL.md` and `plugins/pressroom/skills/diagram-studio/SKILL.md` + `rich-pdf-with-diagrams/SKILL.md`. From `${CLAUDE_PLUGIN_ROOT}/skills/check/`, `../../../../` reaches the marketplace root ONLY in the source tree; dangles for a standalone install — exactly the failure mode finding #2 targeted. Fix = apply the live-feedback.md treatment (drop link, "lives in marketplace source tree" prose; requirements.tsv is the local SSOT). Lesson: a "scrub anti-pattern X" fix must grep the WHOLE diff for X, not just the cited files. See [[rewrite-regressions]].

**Command/skill drift (same re-review):** `commands/prerequisites.md` step 2 says run "each installed plugin's skills/check/scripts/check.sh" (a cross-plugin filesystem path), contradicting `skills/prerequisites/SKILL.md` which (correctly, post-fix) routes companions via `/sentinel:check` /`/pressroom:check` and forbids cross-plugin fs paths — and inspector rule #6. The command and the skill it delegates to drifted.
