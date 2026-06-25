---
name: sentinel-to-security-rename
description: sentinel plugin renamed → security; four scanner commands renamed to /scan-* (PR #116 / roadmap #94)
metadata:
  type: project
---

The `sentinel` plugin was renamed to **`security`** (PR #116, roadmap #94, merged on branch `chore/rename-sentinel-to-security`). Its four scanner commands were renamed:
- `security-gate` → `scan-all`
- `dependency-audit` → `scan-dependencies`
- `secret-scan` → `scan-for-secrets`
- `pii-audit` → `scan-for-pii`

The four scanner commands kept those names; only the plugin namespace changed.

**SUPERSEDED (the phase-pragmatic rename wave):** `security` was itself renamed → **`secure`** (the SECURE-phase verb). The namespaced form is now `/secure:scan-all` etc., the directory is `plugins/secure/`, and deliver/i2p companion wiring is now `"security": "secure"` (capability key `security` → plugin value `secure`). The SECURITY *capability/reviewer-role* label and the `SECURITY-REPORT.md` artifact keep the domain word.

**Why:** capability-clear command naming (scan-* verbs) over the old gate/audit terms; then phase-pragmatic plugin naming (`secure`).

**How to apply:** When reviewing security composition, expect the `secure` plugin + `/secure:scan-*` commands, NOT `sentinel`/`security`/`security-gate`. Legitimately-kept generics that are NOT stale refs: the word "sentinel" in lock vars / `SENTINEL::` protocol tokens / "context sentinel" / status sentinels; the `secret-scan-self` gitleaks CI job in mission-control observability (P1-11); `docs/images/sentinel-gate.gif` asset filename (link resolves, not renamed); `dependency-audit` as a discovery keyword in `secure` plugin.json + marketplace.json keywords arrays. Related: [[project-marketplace-supply-chain]].
