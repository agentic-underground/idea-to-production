---
name: pr-review
description: >
  Run an ADVERSARIAL review of a pull request or a local diff and return a single gating verdict
  (PASS / NEEDS_REVISION / BLOCK). Trigger with /foundry:pr-review [PR#|base..head] (or "review this
  PR", "adversarial review of the diff", "is this branch mergeable?"). Fans out FOUNDRY's reviewer
  agent in multiple adversarial roles (correctness, security, regression, architecture, performance,
  docs) — each prompted to REFUTE the change, not rubber-stamp it — then synthesises their findings
  into one verdict. Composes SENTINEL's /security-gate when installed. Writes PR_REVIEW.md.
metadata:
  type: orchestrator
  output: PR_REVIEW.md (verdict PASS | NEEDS_REVISION | BLOCK) + optional PR comment
  composes: [reviewer (agent, multi-role), security-gate (sentinel, if present)]
model: inherit
---

# FOUNDRY — Adversarial PR Review

One command, a panel of independent skeptics, one verdict. PR-REVIEW is the merge gate FOUNDRY did
not yet have: it reviews a diff the way a hostile-but-fair senior reviewer would — **assume the
change is wrong until each lens fails to break it** — and returns a decision a human (or an
auto-merge step) can act on.

> **Stance — adversarial, not confirmatory.** Every reviewer role is told to *find what is wrong,
> missing, or risky*. A finding-free pass must be *earned*, not granted. Reviewers never invent
> issues to look busy, but they never rubber-stamp either (the FOUNDRY reviewer covenant —
> [`../../agents/reviewer.md`](../../agents/reviewer.md)).

---

## Quick start

```bash
/foundry:pr-review                 # review the current branch vs its merge-base with main
/foundry:pr-review 42              # review GitHub PR #42 (needs gh or a token; see §1)
/foundry:pr-review main..HEAD      # review an explicit git range
/foundry:pr-review --post          # also post the verdict as a PR comment (needs gh/token)
```

---

## 1. Resolve the target & gather context

Run the helper to assemble the review packet (works for a local range or a PR number):

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/pr-review/scripts/gather-diff.sh [PR#|base..head] > /tmp/pr-review-packet.md
```

It emits: the **base..head** range, the **changed-file list** with churn, the **full unified diff**,
and (when a PR number is given and `gh`/`$GH_TOKEN` is available) the PR **title/body** and CI status.
If neither `gh` nor a token is present, pass an explicit range — the review still runs on the diff;
only PR metadata and `--post` are unavailable (reported as a gap, never silently skipped).

## 2. Fan out the adversarial panel

Spawn the FOUNDRY **reviewer** agent once per role **in parallel**, each with the review packet and
an explicit instruction to *try to break the change*. Each returns findings as
`{severity, file, line, claim, why_it_matters, suggested_fix}` where severity ∈
`CRITICAL | HIGH | MEDIUM | LOW | SUGGESTION`.

| Role (reviewer `role=`) | Adversarial question it must answer |
|---|---|
| **CORRECTNESS** (DOCUMENT-REVIEWER / general) | Where is this logically wrong, inconsistent, or unhandled? What input breaks it? |
| **SECURITY-REVIEWER** | What untrusted input, secret, or supply-chain path does this expose? |
| **REGRESSION-REVIEWER** | What existing behaviour or test could this silently break? |
| **ARCHITECTURE-REVIEWER** | What boundary/SOLID/dependency rule does this violate? |
| **PERFORMANCE-REVIEWER** | What gets slower, allocates more, or scales worse? |
| **DOCUMENT-REVIEWER** | Where do docs/specs/links drift from what the code now does? |

Scale the panel to the diff: a docs-only change may need only CORRECTNESS + DOCUMENT; a code change
touching auth pulls in SECURITY + REGRESSION. **Name the roles you ran and the ones you skipped** in
the report (no silent narrowing).

> **If SENTINEL is installed**, also run `/security-gate` over the changed tree and fold its verdict
> in as the authoritative security lens (it supersedes the SECURITY-REVIEWER heuristic pass).

## 3. (Optional) adversarially verify each non-trivial finding

For any HIGH/CRITICAL finding, spawn a second reviewer prompted to **refute** it ("show this is a
false positive"). Keep the finding only if it survives. This kills plausible-but-wrong blocks.

## 4. Synthesise the verdict

Deduplicate overlapping findings, then apply the **same verdict rule FOUNDRY uses everywhere**
(matches SENTINEL's gate and the reviewer agent):

| Verdict | Condition |
|---|---|
| **BLOCK** | ≥1 surviving **CRITICAL** finding (correctness bug, security hole, guaranteed regression). |
| **NEEDS_REVISION** | No CRITICAL, but ≥1 **HIGH**, or ≥1 **MEDIUM** left **unresolved**. |
| **PASS** | Only **LOW / SUGGESTION** findings — plus any **MEDIUM** that was explicitly **resolved or accepted with a recorded rationale**. Each finding documented. |

The verdict is the **highest *unresolved* severity across all roles** — a clean architecture lens
does not offset an unresolved security CRITICAL, and a MEDIUM gates only until it is fixed or
explicitly accepted-with-rationale (record the disposition in the report).

## 5. Emit `PR_REVIEW.md`

```markdown
# PR Review — <target>            **Verdict:** BLOCK | NEEDS_REVISION | PASS
**Range:** <base>..<head>   **Files:** N   **Roles run:** … (skipped: …)

## Verdict rationale         (one paragraph — why this verdict)
## Findings                  (table: severity · file:line · claim · suggested fix · role · [verified])
## Security (SENTINEL)        (gate verdict + link, or "not installed")
## What was NOT reviewed      (roles skipped, files excluded, metadata/CI unavailable — and why)
```

If `--post` is given and `gh` is available, **the orchestrator** (not the gather-diff script) posts
the verdict + findings as a PR comment: `gh pr comment <PR#> --body-file PR_REVIEW.md`. The script
only assembles the packet; posting is an explicit, separate action so a review can never silently
mutate a PR.

## 6. Gate behaviour & merge governance

PR-REVIEW **reports**; it does not merge. What happens after a **PASS** is decided by the project's
**merge-governance mode** ([`../../knowledge/protocols/merge-governance.md`](../../knowledge/protocols/merge-governance.md)),
read from `.foundry/governance.md` (absent ⇒ default `pr-approval`):

- **`pr-approval`** (default): push the branch, open a PR whose body carries this verdict + findings,
  then **stop** — the human merges. The agent never self-merges.
- **`direct-merge`** (autonomy): on PASS, the delivery step merges to `main` and pushes; the verdict
  is recorded in the commit trail / `PR_REVIEW.md`.

In **both** modes a non-PASS verdict (`NEEDS_REVISION`/`BLOCK`) halts the merge and loops back to
revision — autonomy means "merge on PASS", never "merge regardless." Keeping the verdict separate
from the merge keeps the reviewer honest and the merge decision accountable.

---

## Self-improvement covenant

Inherits the reviewer covenant. Additionally: whenever a real defect ships past a PASS, add the lens
or refutation prompt that would have caught it, so the same class cannot pass again. Record the
lesson where the reviewer agent can read it.
