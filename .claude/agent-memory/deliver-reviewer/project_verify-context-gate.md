---
name: verify-context-gate
description: verify-context.sh (EPIC 0067 leanness gate) correctness — measurement fidelity, VC_* env-hook non-leak, jq-absent conservatism
metadata:
  type: project
---

`scripts/verify-context.sh` (PLAN 0067.004, closes EPIC 0067) — always-on leanness gate, 4 checks: C1 budget ≤420w (hard, names offender), C2 pointer ≤60w (hard), C3 phase-gating silent-no-focus (hard), C4 knowledge coverage (advisory WARN). Live footprint 381w (KAIZEN 350 + safe-default pointer 31).

Adversarially cleared (PR #299). Facts for re-review of this gate family:
- **Measurement fidelity holds:** inject-kaizen.sh emits `cat KAIZEN.md` verbatim as additionalContext, so C1 counting KAIZEN.md directly == the injected payload. C1 pointer uses ctx_of(run_pointer) = additionalContext only (systemMessage correctly excluded when jq present).
- **VC_* test hooks (VC_BUDGET/VC_COMPONENTS_DIR/VC_KNOWLEDGE_ROOT) DO override a live `--run`** — an env export would mask C1 (latent false-PASS). NOT reachable via pipeline: self_test uses *inline per-command* assignments (not exports), and `.pipeline/verify` runs `--self-test` then `--run` as separate top-level `bash` invocations w/ clean env. Only a global env export triggers it. LOW/SUGGESTION hardening (honor VC_* only under a self-test sentinel).
- **jq-absent path (ctx_of fallback) over-counts** — returns raw JSON incl. systemMessage+keys (pointer measured 47w vs true 31w). Conservative: false-FAIL risk only, never false-PASS; jq present in CI. LOW.
- **Leanness = upper-bound only:** a broken/silent pointer measures 0w and passes (no presence/lower-bound check). By design.
- Self-test rows BITE (shrinking the offender fixture → row 2 fails exit0≠1). Offender-naming deterministic in practice (bash key-hash stable); real fixture has unique 120w max. See [[knowledge-phase-resolver]] for the C4 resolver it wraps.
