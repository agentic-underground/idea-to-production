---
name: verify-context-gate-failopen
description: verify-context.sh (0067.004) fail-open + VC_* live-override integrity gaps; compensated in .pipeline/verify by sibling gates
metadata:
  type: project
---

`scripts/verify-context.sh` (EPIC 0067 final slice, PR #299) — the always-on leanness gate.

Two gate-integrity gaps (both [[project_fail-open-guard-class]]):
- **Fail-open on missing artifacts.** C1 reads `cat "$KAIZEN" 2>/dev/null` and `run_pointer` (missing/broken hook → empty). Missing KAIZEN.md / renamed phase-pointer.sh / broken roadmap+focus hooks all measure **0w** and **PASS green** (verified: temp REPO with all artifacts absent → exit 0, "0w ≤ 420w"). No `[ -s "$KAIZEN" ]` / `[ -x "$POINTER" ]` existence guard. C2/C3 same shape.
- **VC_* honored in live `--run`.** `VC_BUDGET=999999` → trivial pass; `VC_COMPONENTS_DIR=.../pass` → C1 measures fixtures not real KAIZEN+pointer. No guard restricting test hooks to `--self-test`; a leaked export / CI env silently masks C1 with no warning.

**Why only MEDIUM, not HIGH:** in `.pipeline/verify` the fail-open is compensated — `test-phase-pointer.sh` and `resolve_knowledge_phase.py --self-test` run BEFORE it (`|| exit 1`), and `verify-prereqs.sh` Check N asserts KAIZEN.md parity. Standalone `bash verify-context.sh --run` is NOT compensated.

**No** command injection (fixture basenames `$(id)`/spaces/globs stay literal; all output via `%s`), no temp-dir TOCTOU/symlink (mktemp -d 0700, unconditional `rm -rf "$d"` cleanup), no write outside temp except harmless mktemp-failure → `mkdir -p "/.i2p"` (permission-denied).

**How to apply:** if a follow-up hardens this gate, expect existence-guards + a "VC_* active in live run" warn. Don't re-flag the injection/temp surface — cleared.
