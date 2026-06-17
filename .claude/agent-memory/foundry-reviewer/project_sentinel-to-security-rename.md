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

Namespaced form is now `/security:scan-all` etc. foundry's `/pr-review`, i2p's `/i2p-review`/`/i2p-help`, and mission-control's `/operate-gate` all compose the renamed commands and resolve to the `security` plugin. foundry companion wiring is `"security": "security"`.

**Why:** capability-clear command naming (scan-* verbs) over the old gate/audit terms.

**How to apply:** When reviewing security composition, expect `security` plugin + `/scan-*` commands, NOT `sentinel`/`security-gate`. Legitimately-kept generics that are NOT stale refs: the word "sentinel" in lock vars / `SENTINEL::` protocol tokens / "context sentinel" / status sentinels; the `secret-scan-self` gitleaks CI job in mission-control observability (P1-11); `docs/images/sentinel-gate.gif` asset filename (link resolves, not renamed); `dependency-audit` as a discovery keyword in security plugin.json + marketplace.json keywords arrays. The standalone-security-reviewer DEFER-to-SENTINEL composition note in the reviewer skill still says "SENTINEL"/"security-gate" in prose — that's the foundry-skill wording, separate from the renamed plugin. Related: [[project-marketplace-supply-chain]].
