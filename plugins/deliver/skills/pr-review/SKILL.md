---
name: pr-review
description: >
  Run an ADVERSARIAL review of a PR or local diff → one gating verdict (PASS / NEEDS_REVISION / BLOCK).
  Trigger with /deliver:pr-review (or "review this PR", "is this branch mergeable?"). Guard: ASSURE only.
  Runs ONE composed reviewer whose lenses auto-select for the diff (or a project review-profile pins them);
  composes secure's /scan-all when installed. Writes PR_REVIEW.md.
metadata:
  phase: [ASSURE]
  type: orchestrator
  output: PR_REVIEW.md (verdict PASS | NEEDS_REVISION | BLOCK) + optional PR comment
  composes: [reviewer (ONE agent, composed multi-lens), scan-all (security, if present)]
model: inherit
---

# DELIVER — Adversarial PR Review

One command, one hostile-but-fair reviewer carrying the lenses the diff warrants, one verdict.
PR-REVIEW is the merge gate DELIVER did not yet have: it reviews a diff the way a senior reviewer
would — **assume the change is wrong until each lens fails to break it** — and returns a decision a
human (or an auto-merge step) can act on. One composed reviewer, not a panel of one-lens agents.

> **Stance — adversarial, not confirmatory.** Every lens is told to *find what is wrong,
> missing, or risky*. A finding-free pass must be *earned*, not granted. Reviewers never invent
> issues to look busy, but they never rubber-stamp either (the DELIVER reviewer covenant —
> [`../../agents/reviewer.md`](../../agents/reviewer.md)).

---

## Quick start

```bash
/deliver:pr-review                 # review the current branch vs its merge-base with main
/deliver:pr-review 42              # review GitHub PR #42 (needs gh or a token; see §1)
/deliver:pr-review main..HEAD      # review an explicit git range
/deliver:pr-review --post          # also post the verdict as a PR comment (needs gh/token)
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

## 2. Review with ONE composed reviewer — lenses chosen for the diff

**Default posture: a single reviewer, looking for several things — not several reviewers each
looking for one thing.** Spawn **one** DELIVER **reviewer** agent, given the review packet and a
prompt that **composes the lenses this diff actually warrants** into a single hostile-but-fair pass.
This is the rigour-to-cost point for the gate: one adversarial reviewer holding the whole diff in
context catches cross-cutting issues a role-siloed panel misses, and N agents guarding each PR is
`muri`/over-processing (the standing operator preference — folded here as the shipped default, not a
per-PR re-application). The agent carries the adversarial stance, severity rubric, finding schema,
and self-refutation pass intrinsically (see [`../../agents/reviewer.md`](../../agents/reviewer.md)
§Adversarial stance / §Severity rubric / §Finding schema). It returns findings as
`{severity, locus (file:line), claim, why_it_matters, suggested_fix, evidence, lens}` where severity
∈ `CRITICAL | HIGH | MEDIUM | LOW | SUGGESTION` and **evidence is mandatory for CRITICAL/HIGH** (the
observed command output / line / ratio that proves it — an unproven CRITICAL/HIGH is downgraded).

### 2a. Pick the lenses (auto-select ~3 by diff fingerprint)

Fingerprint the diff, then compose the **three most load-bearing lenses** into that one agent's
prompt (the reviewer answers each in turn and tags every finding with its `lens`). Start from the
**base triad**, then swap/add a conditional lens when the diff touches the surface it owns —
displacing the least-relevant base lens so the composed prompt stays at ~3 (a genuinely
multi-surface diff may justify 4; never silently drop below ~3 lenses):

**Base triad** (the default three when nothing special is touched):

| Lens | Adversarial question it must answer |
|---|---|
| **CORRECTNESS** | Where is this logically wrong, inconsistent, or unhandled? What input breaks it? |
| **REGRESSION** | What existing behaviour or test could this silently break? |
| **DOCUMENT** | Where do docs/specs/links drift from what the code now does? |

**Conditional lenses** — a diff touching this surface **pulls the lens in** (displacing the weakest
base lens); a lens not pulled is listed **"not applicable"** in the report, never silently dropped:

| Lens | Pulled in WHEN the diff touches… |
|---|---|
| **SECURITY** | auth/session/authz, secrets, or business-logic trust boundaries (the flaw a scanner can't see). Superseded by the SECURE gate below when installed. |
| **ARCHITECTURE** | a new boundary/bounded-context, a dependency-direction or SOLID-load-bearing seam. |
| **PERFORMANCE** | a hot path / allocation / scaling-sensitive change. |
| **API-CONTRACT** | a public API/schema/RPC/proto, library public symbols, CLI flags, event payloads, or config keys (breaking-change + semver). |
| **OBSERVABILITY** | a production code path that can fail/branch/carry latency (logs/traces/metrics, SLO hooks — OPERATE tie-in). |
| **LICENSING** | an added or bumped dependency (licence compatibility — complements SECURE's scan-dependencies). |
| **PROMPT-INJECTION** | LLM prompts, tool/agent definitions, or external data fed into a model (injection, tool-permission scope, exfiltration). |
| **I18N** | user-facing strings or locale/number/date/RTL formatting. |
| **DOC-ACCESSIBILITY** | a rendered document artefact (PDF/report) — tagging, reading order, contrast, alt text (hard a11y gate). |
| **DOC-LAYOUT** | a rendered figure / diagram / SVG / generator — the at-a-glance legibility gate. **Only when PUBLISH is installed**, composing its `layout-reviewer` by capability; runs `layout-check.sh` + `raster-lint.sh` on the changed `.svg`/generators as the free mechanical pre-flight. |

Worked examples (**one agent, three lenses** each): a bash-script + docs change → CORRECTNESS +
REGRESSION + DOCUMENT; an auth change → CORRECTNESS + SECURITY + REGRESSION; a public-API change →
CORRECTNESS + API-CONTRACT + REGRESSION; an agent/prompt change → CORRECTNESS + PROMPT-INJECTION +
DOCUMENT. **Name the lenses you composed and the conditional ones that were not-applicable** in the
report (no silent narrowing).

> **Per-project override.** When the project declares a **review profile**
> (`.deliver/review-profile.md` — PLAN 0073.002), it **pins** the lens set/count (or forces a single
> holistic pass) and **overrides** this auto-select — because different projects need different
> review profiles. Absent ⇒ the auto-select above. It never changes the "one composed reviewer"
> shape, only *which* lenses that one reviewer carries.

> **If the SECURE plugin is installed**, also run `/scan-all` over the changed tree and fold its verdict
> in as the **authoritative security lens** — it supersedes the reviewer's SECURITY lens for the
> mechanical lenses (secrets, supply-chain, PII). The composed reviewer's SECURITY lens then narrows to
> the logic the SECURE plugin can't see (authz bypass, session/state design, business-logic abuse), cites
> CWE/OWASP IDs, and does **not** re-report what the gate already owns (the dedup boundary in
> [`../../agents/reviewer.md`](../../agents/reviewer.md) §SECURITY-REVIEWER). When the SECURE plugin is absent,
> the SECURITY lens widens back to the OWASP floor and the report notes machine scanning did not run.

## 3. Adversarially refute every surviving HIGH/CRITICAL — MANDATORY

For **every** HIGH/CRITICAL finding, the second-pass refutation must run: argue it is a **false
positive** ("show this is wrong") — looking for the guard, test, config, or sanitiser that defeats
it. **Keep the finding only if it survives.** This is **intrinsic to the composed reviewer** (it
self-refutes each finding per §Self-refutation pass) — it does **not** add more agents. The
orchestrator's job is only to confirm, before gating, that each surviving HIGH/CRITICAL carries the
evidence that proves it — a block must survive a genuine attempt to break it. This kills
plausible-but-wrong blocks before they cost a revision cycle. Record each refutation outcome
(survived / dropped, and why) in the report's `[verified]` column. *(Only if a HIGH/CRITICAL is
genuinely contested and the diff is high-stakes may the orchestrator spawn one independent refuter
for that single finding — the exception, never the default.)*

## 4. Synthesise the verdict

Deduplicate overlapping findings, then apply the **same verdict rule DELIVER uses everywhere**
(matches the SECURE plugin's gate and the reviewer agent):

| Verdict | Condition |
|---|---|
| **BLOCK** | ≥1 surviving **CRITICAL** finding (correctness bug, security hole, guaranteed regression). |
| **NEEDS_REVISION** | No CRITICAL, but ≥1 **HIGH**, or ≥1 **MEDIUM** left **unresolved**. |
| **PASS** | Only **LOW / SUGGESTION** findings — plus any **MEDIUM** that was explicitly **resolved or accepted with a recorded rationale**. Each finding documented. |

The verdict is the **highest *unresolved* severity across all lenses** — a clean architecture lens
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
**Range:** <base>..<head>   **Files:** N   **Reviewer:** 1 composed agent
**Lenses composed:** … (not-applicable: …)   **Profile:** auto-select | .deliver/review-profile.md

## Verdict rationale         (one paragraph — why this verdict)
## Findings                  (table: severity · file:line · claim · evidence · suggested fix · lens · [verified])
## Security (SECURITY)        (gate verdict + link, or "not installed")
## What was NOT reviewed      (lenses not-run, files excluded, metadata/CI unavailable — and why)
```

If `--post` is given and `gh` is available, **the orchestrator** (not the gather-diff script) posts
the verdict + findings as a PR comment: `gh pr comment <PR#> --body-file PR_REVIEW.md`. The script
only assembles the packet; posting is an explicit, separate action so a review can never silently
mutate a PR.

## 6. Gate behaviour & merge governance

PR-REVIEW **reports**; it does not merge. What happens after a **PASS** is decided by the project's
**merge-governance mode** ([`../../knowledge/protocols/merge-governance.md`](../../knowledge/protocols/merge-governance.md)),
read from `.deliver/governance.md` (absent ⇒ default `pr-approval`):

- **`pr-approval`** (default): push the branch, open a PR whose body carries this verdict + findings,
  then **stop** — the human merges. The agent never self-merges.
- **`direct-merge`** (autonomy): on PASS, the delivery step merges to `main` and pushes; the verdict
  is recorded in the commit trail / `PR_REVIEW.md`.

In **both** modes a non-PASS verdict (`NEEDS_REVISION`/`BLOCK`) halts the merge and loops back to
revision — autonomy means "merge on PASS", never "merge regardless." Keeping the verdict separate
from the merge keeps the reviewer honest and the merge decision accountable.

### Gate failure — what the operator does next

A `NEEDS_REVISION` or `BLOCK` verdict is **not a dead end** — it is the BUILD ⇄ ASSURE back-edge
turning. On a non-PASS verdict, print this recovery procedure so the operator knows the concrete next
step instead of facing a merge halt with no instruction:

1. **Open the report** — `PR_REVIEW.md` (in the project root). Read the **Findings** table:
   each row names a `severity · file:line · claim · suggested fix`.
2. **Fix in BUILD** — address the named findings at their loci (fix the code/tests, re-commit). This
   is a return to the **BUILD** phase; the lifecycle's `fail ASSURE` (below) has already set
   `loop_state` back to BUILD and incremented `loop_pass`.
3. **Re-run the gate** — `/deliver:pr-review` again over the revised diff.
4. **The loop exits only when all three gates are green** — a PASS here advances to **SECURE**
   (`/secure:scan-all`); the loop reaches PUBLISH only once BUILD, ASSURE, **and** SECURE are
   simultaneously satisfied.

---

## Product lifecycle (by capability)

DELIVER owns the **ASSURE** phase — the adversarial quality gate, distinct from the **SECURE** phase
(security) that follows it (quality ≠ security) and from the **BUILD** phase that precedes it. When the
**i2p** plugin is installed, drive the lifecycle from the verdict so the marketplace product lifecycle
and the status line track the BUILD ⇄ ASSURE ⇄ SECURE loop:

```bash
# on a PASS verdict — quality certified, advance to SECURE (loop)
/i2p:lifecycle done ASSURE   # order-safe & idempotent — a no-op unless a lifecycle is running at ASSURE

# on a NEEDS_REVISION or BLOCK verdict — re-enter BUILD (loop back-edge: loop_state→BUILD, loop_pass++)
/i2p:lifecycle fail ASSURE   # order-safe & idempotent — a no-op unless a lifecycle is running at ASSURE
```

`fail ASSURE` is the back-edge that makes the loop turn: the status line renders `⇄ ×N` for the
iteration count, and the **Gate failure** procedure above tells the operator what to fix before the
re-run. Degrades silently when i2p is absent. The canonical model is `i2p/knowledge/product-lifecycle.md`.

---

## Self-improvement covenant

Inherits the reviewer covenant. Additionally: whenever a real defect ships past a PASS, add the lens
or refutation prompt that would have caught it, so the same class cannot pass again — and if the
missed defect belonged to a lens the auto-select *dropped*, tune the §2a selection rule (or the
project's `.deliver/review-profile.md`) so that surface pulls its lens next time. Record the lesson
where the reviewer agent can read it. **Default shape is one composed reviewer** (§2) — resist
reintroducing a role-per-agent panel; scale rigour by composing *more lenses into the one agent* (or
declaring a profile), not by spawning more agents.
