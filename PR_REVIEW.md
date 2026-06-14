# PR Review — Epic #9 Process-Documentation & Git Governance (`flow-tracking-ui`)

**Range:** `origin/main..flow-tracking-ui` · **Verdict: ✅ PASS** (after revision)

Five FOUNDRY reviewer roles fanned out adversarially over the epic diff (5 children: #10 commit→issue→PR
governance, #11 issues-as-process-doc, #12 doc+illustration pipeline, #13 wiki-publisher, #14 onboarding
alert). Initial synthesis was **NEEDS_REVISION** (2 HIGH correctness + 1 HIGH security + 2 MED); all were
fixed in `8e296f3` and re-verified.

## Role verdicts
| Role | Verdict | Notes |
|---|---|---|
| SECURITY | NEEDS_REVISION → **fixed** | 1 HIGH (wiki asset path-traversal exfil), 2 MED (allowlist prefix-spoof, token-in-URL) |
| CORRECTNESS | NEEDS_REVISION → **fixed** | 2 HIGH (unfillable `GITHUB_ISSUE` trailer; roadmap/issue number-space collision), 2 MED |
| ARCHITECTURE | PASS | all 5 marketplace laws hold; 1 systemic model-id-drift SUGGESTION (pre-existing, flagged to covenant) |
| REGRESSION | PASS | additive, well-gated; SessionStart chain + CI contract preserved; verify-prereqs green |
| DOCUMENT | PASS | links resolve, model IDs correct, no restated knowledge; 2 SUGGESTIONs |

## HIGH/MED findings — resolution (all adversarially repro'd, then fixed)
1. **[HIGH·SEC] Wiki asset path-traversal exfil** — `publish-wiki.sh` copied `![x](../../secret)` assets into
   the public wiki. **Fixed:** added `*..*` token guard **and** `realpath` confinement to `doc/articles/`
   (fail-closed). Repro confirms both layers now block it.
2. **[HIGH·CORR] `GITHUB_ISSUE: #N` trailer unfillable** — commit was created before the issue existed.
   **Fixed:** ds-step-9 raises the issue then `git commit --amend` (commit not yet pushed); ds-step-8 leaves
   the trailer to that amend on first delivery.
3. **[HIGH·CORR] Number-space collision** — `ROADMAP: closes #N` (roadmap item) would close GitHub issue #N.
   **Fixed:** commit-message.md now mandates a **non-closing** roadmap footer (`Refs roadmap #N`) on
   allowlisted github origins; only the PR's `Closes #<issue>` closes anything.
4. **[MED] Allowlist match** — prefix glob let `agentic-underground-evil/*` match and bare-owner vs slug was
   ambiguous. **Fixed:** merge-governance.md specifies an **anchored full `owner/repo` slug** match.
5. **[MED] Token-in-URL** (process-arg/`.git/config` exposure) — accepted as residual: scratch dir is
   `mktemp 0700` with cleanup trap, single-user dev target. Noted, not gating.

## Verification
- `bash scripts/verify-prereqs.sh` → **all checks PASS** (canonical parity, four-mirror J, link-resolution I,
  hook smoke-exec L incl. the new `offer-doc-alert.sh`).
- `bash -n` clean on all three new/edited shell scripts; security-exploit repro now **BLOCKED**.

## Not reviewed
- Live execution against GitHub (no issues/PRs were created; #10/#13's `gh` paths reviewed statically + the
  origin-match was dry-checked). The wiki publish was not run against a real `.wiki.git`.
- SENTINEL `/security-gate` (secrets/PII/deps): no new dependency or secret surface (authored docs + bash);
  the SECURITY reviewer role covered script safety directly.

## Carried suggestions (non-gating, KAIZEN)
- Model-id literals restated inline in 3 pressroom files — a pre-existing repo-wide pattern (45 files);
  flagged for a single future sweep to reference `model-selection.md`.
- `ROADMAP.md [0]` epic's plan reference points to a not-yet-created plan file (created at its own Step-0).

_Generated for `/foundry:pr-review` — reports a verdict; does not merge. Merge per merge-governance
(pr-approval: human merges the PR)._
