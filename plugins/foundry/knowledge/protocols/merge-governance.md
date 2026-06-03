# Merge Governance — how a passing change reaches `main`

> Canonical policy for the **last step** of the conveyor: once a change is built and the
> adversarial review passes, *who performs the merge?* FOUNDRY supports two modes; the user
> chooses up-front and can switch any time. The **adversarial review gate is always-on** — the
> modes differ only in who merges *after* a PASS, never in whether the gate runs.

---

## The always-on gate (both modes)

Before anything reaches `main`, `/foundry:pr-review` (see [`../../skills/pr-review/SKILL.md`](../../skills/pr-review/SKILL.md))
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

The agent **never self-merges** in this mode. (GitHub also structurally forbids approving your own
PR, so a human approval is both a policy choice and a platform reality.) The value: a final human
gate, full visibility into the direction of each feature branch, and an audit trail in the PR.

### `direct-merge` (autonomy — agent merges)

For high-autonomy / solo / low-stakes repos where the user has granted FOUNDRY the authority to
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
> merged branch, not `main`, exactly this way). When a base PR merges:
> 1. Retarget each dependent PR's base to `main`: `gh pr edit <n> --base main` (top of the stack down).
> 2. Re-confirm the dependent PR's diff is now **only its own commits**, not the base's.
> 3. Merge in order, and **verify each landed on `main`** (e.g. `git cat-file -e main:<a-changed-file>`),
>    not on a feature branch.

---

## How the mode is set, stored, and changed

- **Asked up-front.** On first setup of a project's production line, **FOUNDER asks the user which
  mode** ([`../../agents/founder.md`](../../agents/founder.md) §0 discovery), explains the trade-off,
  and records the choice. FOUNDER's READOUT always states the active mode.
- **Stored** in a project-local marker the delivery step reads:
  **`.foundry/governance.md`**, containing the line:
  ```
  **Merge mode:** pr-approval        # or: direct-merge
  ```
  Absent or unreadable ⇒ **default to `pr-approval`** (safe by default; never assume autonomy).
- **Switchable any time.** "switch to direct-merge" / "give FOUNDRY merge autonomy" or
  "require PR approvals" / "go back to PR mode" rewrites the marker. The change takes effect on the
  next delivery; in-flight branches finish under the mode that was active when they started unless
  the user says otherwise. State the new mode back to the user when you switch.

> **Choosing:** prefer `pr-approval` for anything running in production, anything with more than one
> maintainer, or whenever the user wants eyes on direction. Prefer `direct-merge` only where the
> user has explicitly granted autonomy and the always-on adversarial review is trusted as the gate.

This policy is consumed by the delivery step ([`../../agents/ds-step-9-commit-push.md`](../../agents/ds-step-9-commit-push.md))
and the delivery lifecycle state ([`../../skills/lifecycle-states/states/delivery.md`](../../skills/lifecycle-states/states/delivery.md)).
