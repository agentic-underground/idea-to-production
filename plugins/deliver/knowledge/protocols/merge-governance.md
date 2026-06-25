# Merge Governance — how a passing change reaches `main`

> Canonical policy for the **last step** of the conveyor: once a change is built and the
> adversarial review passes, *who performs the merge?* DELIVER supports two modes; the user
> chooses up-front and can switch any time. The **adversarial review gate is always-on** — the
> modes differ only in who merges *after* a PASS, never in whether the gate runs.

---

## The always-on gate (both modes)

Before anything reaches `main`, `/deliver:pr-review` (see [`../../skills/pr-review/SKILL.md`](../../skills/pr-review/SKILL.md))
runs an adversarial review of the change and returns one verdict:

- **BLOCK** or **NEEDS_REVISION** → the change does **not** merge in either mode. Revise and re-review.
- **PASS** → proceed to merge **according to the active governance mode** (below).

A passing review is necessary in both modes. The mode only decides the hand that merges.

---

## The two modes

### `pr-approval` (default — human merges)

The safe default, and the right choice for shared, mission-critical, or production repos — or
simply when the user wants to *see and approve* what the value-handlers produced.

1. Commit on a feature branch.
2. Push the branch.
3. Open a **pull request** whose body carries the adversarial-review verdict + findings summary.
4. **STOP.** The human reviews and clicks merge + close.

#### Interactive merge offer (pr-approval + in-session)

When the build session is still active at the AWAITING MERGE boundary, the orchestrator
**offers an in-session merge** rather than silently halting:

> **Merge PR now? [yes/no]**

- **yes** — the orchestrator runs `gh pr merge {pr_number} --merge`, verifies
  `state == "MERGED"` via `gh pr view {pr_number} --json state`, then immediately
  invokes the post-merge completion handler (ROADMAP.md → COMPLETE, DELIVERY_COMPLETE
  sentinel, flow canvas sync, DoD audit, completion summary). The human said yes in-session
  — this is still `pr-approval` because the human approved; the agent did not self-initiate.
- **no** — the orchestrator halts as before: PR stays open, the user merges externally,
  and sends the post-merge signal.
- **gh unavailable or merge fails** — the orchestrator surfaces the error, does NOT emit
  DELIVERY_COMPLETE, does NOT modify ROADMAP.md, and falls back to the manual-merge path.
  No sentinel corruption occurs.

This is still `pr-approval` mode: the human explicitly approves the merge at the prompt.
The agent never self-merges without a "yes" answer from the human.

The agent **never self-merges** in this mode. (GitHub also structurally forbids approving your own
PR, so a human approval is both a policy choice and a platform reality.) The value: a final human
gate, full visibility into the direction of each feature branch, and an audit trail in the PR.

### `direct-merge` (autonomy — agent merges)

For high-autonomy / solo / low-stakes repos where the user has granted DELIVER the authority to
ship. The adversarial review is still always-on; the user has simply pre-delegated the merge.

1. Commit on a feature branch (or work on a short-lived integration branch).
2. Run the adversarial review.
3. On **PASS**: merge to `main` and push. Record the verdict in the commit trail / `PR_REVIEW.md`.

No PR object is required. `NEEDS_REVISION`/`BLOCK` still halts — autonomy is "merge **on PASS**",
never "merge regardless."

---

## PR base — target `main`; stacked PRs are opt-in

Under `pr-approval`, **every PR targets `main` by default** — one branch, one PR, one reviewed change
a human merges into trunk. This keeps the merge graph legible and sidesteps the stacked-PR trap below.

**Stacked PRs** (PR *B* based on PR *A*'s branch instead of `main`) are a deliberate strategy for a
planned sequence of dependent changes — **never a default**. Use them only when the work genuinely
calls for it (e.g. one large feature split into dependent, separately-reviewable slices), and **only
after surfacing the plan to the user and getting explicit approval**. If you are about to base a
branch on anything other than `main`, **stop and ask first**.

> **Stacked-PR retargeting guard — THE ONLY WAY.** When a stacked strategy *is* approved, a PR based
> on another feature branch **must be retargeted to `main` (or the next still-open base) the moment
> its base PR merges**, and the stack merged **base → tip in order**. A stacked PR left pointing at an
> already-merged base will merge into that dead branch instead of `main`, **silently stranding its
> work off trunk** — a real, observed failure mode (a reviewed-and-approved feature once landed on a
> merged branch, not `main`, exactly this way). Merge a stack **bottom-up (base → tip)**; each time
> the current bottom PR merges:
> 1. Retarget the PR(s) **directly stacked on the just-merged branch** to their next still-open base
>    — which is `main` if nothing remains between them and `main`, otherwise the next open PR's branch:
>    `gh pr edit <n> --base <main|next-open-base>`. (For a stack A←B←C: when A merges, retarget B to
>    `main`; C stays based on B until B merges, then C retargets to `main`. Never point a PR at `main`
>    while an open PR sits between it and `main`.)
> 2. Re-confirm that PR's diff is now **only its own commits**, not its base's.
> 3. After it merges, **verify it landed on `main`** (e.g. `git cat-file -e main:<a-changed-file>`),
>    not on a feature branch — then proceed to the next PR up the stack.

---

## Org allowlist — when issues + PRs are raised at all

The two modes above decide *who merges*; the **org allowlist** decides *whether the change is
governed through GitHub issues and PRs at all*. It is a configurable list of anchored `owner/repo`
globs (**default `agentic-underground/*`**) matched against the **full `owner/repo` slug parsed from
the git `origin` remote** (e.g. `git@github.com:agentic-underground/foo.git` → slug
`agentic-underground/foo`).

> **Match the full slug, anchored — never a bare-owner prefix.** The glob `agentic-underground/*`
> matches any repo under *exactly* that owner because the literal `/` anchors the owner segment:
> `agentic-underground/foo` matches; **`agentic-underground-evil/foo` does NOT** (it lacks the
> `agentic-underground/` prefix). Implement this as a glob/`case` match on the whole `owner/repo`
> string — do **not** prefix-match the bare owner, or a look-alike org would be wrongly allowlisted
> (a Broken-Access-Control bug). If `git`/`gh` cannot resolve the slug, treat it as **not matched**.

- **Origin owner matches the allowlist** → full Commit→Issue→PR governance:
  1. The value system **raises a GitHub issue per completed work item** (one issue, one item) if
     the item does not already have one. Its commit carries the `GITHUB_ISSUE: #N` trailer
     ([`commit-message.md` §2](commit-message.md)).
  2. The **PR body MUST carry `Closes #N`** for each item's issue, so the human's merge closes
     those issues automatically. This obeys the active mode — under `pr-approval` (default) the PR
     is opened and **the human merges**; under `direct-merge` the same `Closes #N` references ride
     the merge commit.
- **Origin owner does NOT match** → **commits + local docs only**. No GitHub issue is raised and no
  PR automation runs; delivery records the item in the roadmap/plan as usual. The always-on
  adversarial gate still runs, and the agent **still never self-merges**.

The allowlist is configured project-locally (default applies when unset). `gh` being unavailable or
unauthenticated is treated the same as a non-match: skip the issue/PR steps, report the gap,
continue (see [`../../agents/ds-step-9-commit-push.md`](../../agents/ds-step-9-commit-push.md)).

> The org allowlist is **orthogonal to the merge mode**: it gates GitHub issue/PR *automation*; the
> mode gates *who merges* a PR once it exists. The "agent never self-merges / a human merges" rule
> holds on every allowlisted origin regardless of mode.

---

## How the mode is set, stored, and changed

- **Asked up-front.** On first setup of a project's production line, **FOUNDER asks the user which
  mode** ([`../../agents/founder.md`](../../agents/founder.md) §0 discovery), explains the trade-off,
  and records the choice. FOUNDER's READOUT always states the active mode.
- **Stored** in a project-local marker the delivery step reads:
  **`.deliver/governance.md`**, containing the line:
  ```
  **Merge mode:** pr-approval        # or: direct-merge
  ```
  Absent or unreadable ⇒ **default to `pr-approval`** (safe by default; never assume autonomy).
- **Switchable any time.** "switch to direct-merge" / "give DELIVER merge autonomy" or
  "require PR approvals" / "go back to PR mode" rewrites the marker. The change takes effect on the
  next delivery; in-flight branches finish under the mode that was active when they started unless
  the user says otherwise. State the new mode back to the user when you switch.

> **Choosing:** prefer `pr-approval` for anything running in production, anything with more than one
> maintainer, or whenever the user wants eyes on direction. Prefer `direct-merge` only where the
> user has explicitly granted autonomy and the always-on adversarial review is trusted as the gate.

This policy is consumed by the delivery step ([`../../agents/ds-step-9-commit-push.md`](../../agents/ds-step-9-commit-push.md))
and the delivery lifecycle state ([`../../skills/lifecycle-states/states/delivery.md`](../../skills/lifecycle-states/states/delivery.md)).
