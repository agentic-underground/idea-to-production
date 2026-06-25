---
name: review
description: >
  The marketplace-wide adversarial review. Use for /i2p:review (or "review everything",
  "full review across all the plugins", "give me one verdict from every reviewer"). Determines
  scope, fans out EVERY installed specialist reviewer — code (deliver /pr-review), design
  (design /ui-review), rendered docs (publish /publish:design-reviewer), security (security
  /scan-all) — adversarially verifies the serious findings, and synthesises ONE verdict
  (PASS / NEEDS_REVISION / BLOCK) in I2P_REVIEW.md, naming what could not be reviewed. Thin: it
  composes the specialists, it does not re-implement review logic.
metadata:
  type: orchestrator
  output: I2P_REVIEW.md (verdict PASS | NEEDS_REVISION | BLOCK across all lenses)
  composes: [deliver /pr-review, design /ui-review, publish /publish:design-reviewer, security /scan-all — each if present]
model: inherit
---

# i2p — Cross-plugin adversarial review

One command, the whole marketplace's review power, one verdict. Where deliver's `/pr-review` reviews the
**code**, `/i2p:review` adds the **design**, **rendered-doc**, and **security** lenses the specialist
plugins own — behind a single marketplace-wide decision a human (or an auto-merge step) can act on.

> **Stance — adversarial, not confirmatory.** Every lens is told to *find what is wrong, missing, or
> risky*. A finding-free PASS must be **earned**. And coverage is honest: a lens whose plugin is not
> installed is a **gap reported**, never a silent green light.

> **DRY — delegate, never duplicate.** This skill is a thin orchestrator. It invokes the specialists'
> existing skills and folds their verdicts together; it does not re-implement correctness, design,
> typography, or security review here.

---

## 1. Determine scope

From `$ARGUMENTS` (a PR number, a `base..head` range, a running URL, a path, or empty ⇒ current branch
vs merge-base with `main`), decide which lenses are in scope:

| In scope when… | Lens | Delegate to (if installed) |
|---|---|---|
| a code diff exists | **CODE** | deliver **`/pr-review`** |
| a running SPA / screenshot is provided | **DESIGN** | design **`/ui-review`** |
| rendered docs / figures (PDF, diagrams) changed | **DOCS** | publish **`/publish:design-reviewer`** (its layout/legibility gate — edge-clip, overlap, inline-legibility — rides inside this delegation, run before taste) |
| always (any change can leak/secret/regress deps) | **SECURITY** | security **`/scan-all`** |

Name the lenses you will run and the ones you skip (and why) — no silent narrowing.

## 2. Fan out the panel

Run each in-scope lens whose plugin is **installed**. Each returns findings as
`{severity, locus, claim, why_it_matters, suggested_fix, lens}`, severity ∈
`CRITICAL | HIGH | MEDIUM | LOW | SUGGESTION`. Prefer running independent lenses **in parallel**.

- deliver `/pr-review` already fans out its own adversarial roles (correctness, security, regression,
  architecture, performance, docs) and, when security is present, folds in `/scan-all` — let it; do
  not re-run those roles yourself. If deliver is **absent**, fall back to a direct `/scan-all` for
  the SECURITY lens and note that the code lens was unavailable.

## 3. Adversarially verify

For each HIGH/CRITICAL finding, do a second pass prompted to **refute** it ("show this is a false
positive"). Keep it only if it survives. This kills plausible-but-wrong blocks.

## 4. Synthesise one verdict

Deduplicate overlapping findings across lenses, then apply the **marketplace verdict rule** (the same
one deliver's pr-review and security's gate use):

| Verdict | Condition |
|---|---|
| **BLOCK** | ≥1 surviving **CRITICAL** in any lens. |
| **NEEDS_REVISION** | No CRITICAL, but ≥1 **HIGH**, or ≥1 **MEDIUM** left **unresolved**. |
| **PASS** | Only **LOW / SUGGESTION** — plus any **MEDIUM** explicitly **resolved or accepted with a recorded rationale**. |

The verdict is the **highest *unresolved* severity across all lenses** — a clean design lens does not
offset an unresolved security CRITICAL.

## 5. Emit `I2P_REVIEW.md`

```markdown
# i2p Review — <target>          **Verdict:** BLOCK | NEEDS_REVISION | PASS
**Scope:** <range/url/path>   **Lenses run:** … (skipped: …)

## Verdict rationale            (one paragraph — why this verdict)
## Findings                     (table: severity · locus · claim · suggested fix · lens · [verified])
## Per-lens verdicts            (CODE / DESIGN / DOCS / SECURITY — verdict + link to each sub-report)
## What was NOT reviewed        (lenses whose plugin is absent, files excluded, metadata unavailable — and why)
```

This command **reports**; it does not merge — what happens after a PASS is the project's
merge-governance decision (deliver's `knowledge/protocols/merge-governance.md` when present).

---

## Self-improvement covenant

Inherits the front door covenant (`knowledge/covenant.md`) and each specialist's reviewer covenant.
Additionally: whenever a real defect ships past a PASS, add the lens — or wire in the specialist plugin —
that would have caught it, so the same class cannot pass again.
