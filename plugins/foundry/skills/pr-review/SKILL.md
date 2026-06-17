---
name: pr-review
description: >
  Run an ADVERSARIAL review of a pull request or a local diff and return a single gating verdict
  (PASS / NEEDS_REVISION / BLOCK). Trigger with /foundry:pr-review [PR#|base..head] (or "review this
  PR", "adversarial review of the diff", "is this branch mergeable?"). Fans out FOUNDRY's reviewer
  agent in multiple adversarial roles (correctness, security, regression, architecture, performance,
  docs — plus conditional API-contract, observability, licensing, prompt-injection, i18n, and
  doc-accessibility lenses when the diff touches them) — each prompted to REFUTE the change, not
  rubber-stamp it — then synthesises their findings into one verdict. Composes the SECURITY plugin's
  /scan-all when installed. Writes PR_REVIEW.md.
metadata:
  type: orchestrator
  output: PR_REVIEW.md (verdict PASS | NEEDS_REVISION | BLOCK) + optional PR comment
  composes: [reviewer (agent, multi-role), scan-all (security, if present)]
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
an explicit instruction to *try to break the change*. The agent carries the adversarial stance,
severity rubric, finding schema, and self-refutation pass intrinsically (see
[`../../agents/reviewer.md`](../../agents/reviewer.md) §Adversarial stance / §Severity rubric /
§Finding schema) — so every caller, not just this one, gets a hostile-but-fair reviewer. Each role
returns findings as `{severity, locus (file:line), claim, why_it_matters, suggested_fix, evidence}`
where severity ∈ `CRITICAL | HIGH | MEDIUM | LOW | SUGGESTION` and **evidence is mandatory for
CRITICAL/HIGH** (the observed command output / line / ratio that proves it — an unproven CRITICAL/HIGH
is downgraded by the agent).

**Always-on lenses** (run on any non-trivial diff):

| Role (reviewer `role=`) | Adversarial question it must answer |
|---|---|
| **CORRECTNESS-REVIEWER** | Where is this logically wrong, inconsistent, or unhandled? What input breaks it? |
| **SECURITY-REVIEWER** | Where is the authz/session/business-logic flaw a scanner can't see? (Superseded by SECURITY — below.) |
| **REGRESSION-REVIEWER** | What existing behaviour or test could this silently break? |
| **ARCHITECTURE-REVIEWER** | What boundary/SOLID/dependency rule does this violate? |
| **PERFORMANCE-REVIEWER** | What gets slower, allocates more, or scales worse? |
| **DOCUMENT-REVIEWER** | Where do docs/specs/links drift from what the code now does? |

**Conditional lenses** (run only when the diff touches the surface they own — otherwise list as
"not applicable" in the report, never as a silent skip):

| Role (reviewer `role=`) | Run WHEN the diff touches… |
|---|---|
| **API-CONTRACT-REVIEWER** | a public API/schema/RPC/proto, library public symbols, CLI flags, event payloads, or config keys (breaking-change + semver discipline). |
| **OBSERVABILITY-REVIEWER** | a production code path that can fail/branch/carry latency (logs/traces/metrics, SLO hooks — ties to the OPERATE phase). |
| **LICENSING-REVIEWER** | an added or bumped dependency (licence compatibility — complements the SECURITY plugin's scan-dependencies, which checks vulns not licences). |
| **PROMPT-INJECTION-REVIEWER** | LLM prompts, tool/agent definitions, or external data fed into a model (injection, tool-permission scope, exfiltration). |
| **I18N-REVIEWER** | user-facing strings or locale/number/date/RTL formatting (translation readiness). |
| **DOC-ACCESSIBILITY-REVIEWER** | a rendered document artefact (PDF/report) — tagging, reading order, contrast, alt text (hard a11y gate). |
| **DOC-LAYOUT** | a rendered figure / diagram / SVG / generator — the at-a-glance legibility gate (edge-clip, overlap, inline-legibility). **Only when PRESSROOM is installed**, composing its `layout-reviewer` by capability; runs `layout-check.sh` + `raster-lint.sh` on the changed `.svg`/generators as the free mechanical pre-flight. |

Scale the panel to the diff: a docs-only change may need only CORRECTNESS + DOCUMENT; a code change
touching auth pulls in SECURITY + REGRESSION; an API change pulls in API-CONTRACT; an agent/prompt
change pulls in PROMPT-INJECTION. **Name the roles you ran, the conditional ones that were
not-applicable, and any you skipped** in the report (no silent narrowing).

> **If the SECURITY plugin is installed**, also run `/scan-all` over the changed tree and fold its verdict
> in as the **authoritative security lens** — it supersedes the SECURITY-REVIEWER pass for the
> mechanical lenses (secrets, supply-chain, PII). The SECURITY-REVIEWER then narrows to the
> logic the SECURITY plugin can't see (authz bypass, session/state design, business-logic abuse), cites CWE/OWASP
> IDs, and does **not** re-report what the gate already owns (the dedup boundary in
> [`../../agents/reviewer.md`](../../agents/reviewer.md) §SECURITY-REVIEWER). When the SECURITY plugin is absent,
> SECURITY-REVIEWER widens back to the OWASP floor and the report notes machine scanning did not run.

## 3. Adversarially refute every surviving HIGH/CRITICAL — MANDATORY

For **every** HIGH/CRITICAL finding, run the second-pass refutation: argue it is a **false positive**
("show this is wrong") — looking for the guard, test, config, or sanitiser that defeats it. **Keep the
finding only if it survives.** This is not optional: the reviewer agent already does this internally
per finding (§Self-refutation pass), and the orchestrator confirms it for every surviving
HIGH/CRITICAL before it can gate — a block must survive a genuine attempt to break it. This kills
plausible-but-wrong blocks before they cost a revision cycle. Record each refutation outcome
(survived / dropped, and why) in the report's `[verified]` column.

## 4. Synthesise the verdict

Deduplicate overlapping findings, then apply the **same verdict rule FOUNDRY uses everywhere**
(matches the SECURITY plugin's gate and the reviewer agent):

| Verdict | Condition |
|---|---|
| **BLOCK** | ≥1 surviving **CRITICAL** finding (correctness bug, security hole, guaranteed regression). |
| **NEEDS_REVISION** | No CRITICAL, but ≥1 **HIGH**, or ≥1 **MEDIUM** left **unresolved**. |
| **PASS** | Only **LOW / SUGGESTION** findings — plus any **MEDIUM** that was explicitly **resolved or accepted with a recorded rationale**. Each finding documented. |

The verdict is the **highest *unresolved* severity across all roles** — a clean architecture lens
does not offset an unresolved security CRITICAL, and a MEDIUM gates only until it is fixed or
explicitly accepted-with-rationale (record the disposition in the report).

**On BLOCK or repeated NEEDS_REVISION → fire the GEMBA reflex (#22).** A BLOCK verdict, or the same
class of finding surviving more than one revision, is a *gemba* signal that the gap is systemic. When
`operate` is installed, prompt **`/operate:gemba`** to capture the gap and route it
(SELF → a `self-improve` PR; elsewhere → the learning ledger + a consented issue) so the defect class
is fixed upstream once — never let a hard stop pass uncaptured.

## 5. Emit `PR_REVIEW.md`

```markdown
# PR Review — <target>            **Verdict:** BLOCK | NEEDS_REVISION | PASS
**Range:** <base>..<head>   **Files:** N   **Roles run:** … (skipped: …)

## Verdict rationale         (one paragraph — why this verdict)
## Findings                  (table: severity · file:line · claim · evidence · suggested fix · role · [verified])
## Security (SECURITY)        (gate verdict + link, or "not installed")
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
