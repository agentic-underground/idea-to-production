---
metadata:
  phase: [cross-cut]
---
# CLEAR-SAFE — the covenant that every boundary is safe to `/clear`

> A standing operating awareness of the **idea-to-production** marketplace, alongside [KAIZEN](../../../../KAIZEN.md):
> **every PLAN/EPIC boundary is a proven-safe checkpoint the user can `/clear` and `resume` from.**
> At the completion of each PLAN or EPIC the agent must **prove — never merely claim —** that the
> work is durably checkpointed, tell the user they are CLEAR-SAFE and exactly what `resume` will do,
> and give an **honest fan-out advisement** for the next items. The report is worthless as a claim;
> it is only worth its proofs.

Why this is a covenant and not a nicety: a session can *look* done while learnings sit uncommitted,
a branch dangles, or the resume-memory is stale — a **false** clear-safety. A user who `/clear`s on a
false checkpoint loses work or resumes into a broken state. CLEAR-SAFE makes the safety a fact.

---

## The four proofs (all four, every boundary)

At each PLAN/EPIC boundary, run the checks and show their output. A claim without its proof does not count.

| # | Claim | Proof (deterministic) | CLEAR-SAFE requires |
|---|---|---|---|
| 1 | **Tree clean** | `git status --porcelain` | empty output |
| 2 | **Upstream in sync** | `git rev-list --left-right --count @{u}...HEAD` | `0	0` (0 behind, 0 ahead) |
| 3 | **Learnings committed** | `git status --porcelain .claude/agent-memory/` (a *tracked* asset) | empty — reviewer/agent learnings are committed, not left dirty |
| 4 | **3-layer STATE current** | resume-memory names the *next* item + its spec; board Status matches; docs mirror (or a logged skip) | the pointer a fresh session auto-loads is accurate |

Notes: **proof 2** requires the branch to track an upstream — push with `-u`; if `@{u}` is unset the
command *errors* (not `0 0`), which is itself NOT clear-safe. **proof 3** is not independent of proof 1
(`.claude/agent-memory/` is tracked, so proof 1 already covers it) — it is a **spotlight** on proof 1's
most-missed subset, because uncommitted learnings are the exact hole this covenant exists to close.

The deterministic gate that runs all four and emits the report is `scripts/verify-clear-safe.sh`
(EPIC 0071 / CS2). Until it lands, run the four commands inline and show the output.

> **Learnings are load-bearing (proof 3).** Subagents (reviewers especially) write durable learnings to
> the tracked `.claude/agent-memory/` ledger, and the KAIZEN reflex folds general lessons back into the
> RULE documents (`knowledge/`). Both must be **committed** at the boundary — an uncommitted learning is
> a lost learning and an unclean tree. This is the exact hole that motivated the covenant.

---

## The completion-report contract

Every PLAN/EPIC completion message MUST carry, in this order:

1. **What landed** — the merged PR(s) / created artifacts, with numbers.
2. **The CLEAR-SAFE proof table** — the four checks above with their actual command output (not prose).
3. **The verdict** — one of:
   - **"CLEAR-SAFE — safe to `/clear` and `resume`."** (all four proofs pass), or
   - **"NOT clear-safe — <what is dirty/unsynced/uncommitted/stale>."** followed by fixing it, then re-proving.
4. **What `resume` will do** — name the exact next item the resume-memory points to and what continuing means.
5. **The fan-out advisement** — see below.

The agent states CLEAR-SAFE **because the proofs pass**, never because it was asked to. If a proof fails,
the honest report is "NOT clear-safe" and the boundary is not done until it is fixed.

---

## The fan-out advisement — *only if they actually can*

At each boundary, tell the user whether the next *N* items can be **fanned out into a workflow** —
built in parallel and merged, rather than one at a time. Two **per-pair predicates** decide whether a
pair is parallelizable — an item pair fans out **iff both hold**:

- **No dependency** — neither item needs the other's output (respect the EPIC/PLAN dependency DAG).
- **Disjoint files** — they do not edit the same file (two slices adding verbs to the *same* script
  collide; two slices touching *different* files do not).

And one **execution constraint** that *always* applies (it is not a per-pair test — it never makes a
pair "more parallel"): **GitHub writes and the merge-to-`main` are serialized.** Board/issue/PR
mutations and merges are inherently serial; concurrent writes race (duplicate order allocation,
board-status clobber). See the ⚠ markers a plan's own decomposition carries.

Honest atomicity: a fan-out is therefore **parallel build + adversarial review, then a serialized merge
+ STATE update** — not a literally-atomic merge. Say so. The mechanism that computes the advisement is
EPIC 0071 / CS3; the mechanism that *executes* it is the `resume … in a workflow` verb (CS4). **Until
CS3/CS4 land, the agent computes the advisement and runs the workflow by hand** — the phrases below are
the coded *intent*, not yet an automated verb.

If the next items are **not** safely parallel (a real dependency, a shared file, a serialize-only
convert), say that too — "the next three must go one at a time because …". Never oversell parallelism.

---

## The vocabulary — coded, unambiguous

These phrases have fixed meaning so intent never has to be re-derived:

- **`resume`** — read the auto-loaded resume-memory, run the deterministic resume probe (board *In
  Progress* → matching `pipeline/*` branch → open PR → `git status`), and continue at the next item the
  pointer names.
- **`resume the next N in a workflow`** (or **`resume the next N items in a workflow`**) — take the next
  *N* items the fan-out advisement marked parallel, and run them as one `Workflow`: worktree-isolated
  parallel **build** → adversarial **review** per item → **serialized** merge + Backlog→In Progress→Done
  + 3-layer STATE update per item. If fewer than *N* of the next items are actually parallel, do the
  ones that are and say which were held back and why (never silently include a non-parallel item).

When the agent says *"the next three can be a workflow"* and the user replies *"ok"*, then `/clear`s and
says *"resume the next three items in a workflow"*, the meaning is exactly the above — no searching.

---

## Relationship to the rest of the canon

- [KAIZEN](../../../../KAIZEN.md) — the lean canon; CLEAR-SAFE is its checkpoint discipline (fold every
  learning back, then *prove* the fold is committed and the boundary is safe).
- [`code-issue-pr-linkage.md`](code-issue-pr-linkage.md) — the linkage the STATE proof (3) relies on.
- [`merge-governance.md`](merge-governance.md) — the merge that precedes a clean, synced tree (proofs 1–2).
- The three-layer STATE (board · resume-memory · docs) is the marketplace's own `/clear`-safe discipline,
  dogfooded on project #4.
