---
metadata:
  phase: [cross-cut]
---
# Board Status — the lifecycle state-machine + the web-UI-only option rule

> **Single source of truth** for the project board's **Status** single-select field: the canonical
> option set, what each state means, and the **one hard rule** that keeps the board safe —
> *options are added and edited through the GitHub web UI only, never the API.* The companion
> [`code-issue-pr-linkage.md`](code-issue-pr-linkage.md) owns how a unit of work is *tied to* its
> board item; this doc owns the **Status column itself**.

This backs PLAN 0072.007. The canonical list lives in code at
[`scripts/roadmap/gh-pipeline.sh`](../../../../scripts/roadmap/gh-pipeline.sh) (`_GHP_STATUS_OPTIONS`)
and is pinned by that script's `--self-test`.

---

## 1. The canonical Status options

```
Backlog · To Do · In Progress · Review · Revise · Done · Delivered
```

| Status | Meaning | Issue state |
|---|---|---|
| **Backlog** | captured, not yet scheduled (the seed state on a fresh board-add) | open |
| **To Do** | plan-approved, ready to build | open |
| **In Progress** | actively being built | open |
| **Review** | built; **under** adversarial review (`/deliver:pr-review` running / PR open) | open |
| **Revise** | review requested changes; back with the builder | open |
| **Done** | merged / accepted — a **terminal** state | **closed** |
| **Delivered** | shipped to production (terminal, distinct from Done for delivery tracking) | **closed** |

`Review` (under-review) is **distinct** from `Revise` (changes-requested) — do not collapse them.

**Terminal ⇒ closed.** `set-status` keeps the issue's open/closed state in lockstep with Status:
moving to `Done`/`Delivered` closes the issue; moving back out reopens it (see `_ghp_status_closes`,
PLAN 0072.012). **A hidden status is still a valid status** — set the true lifecycle state regardless
of which board *view* happens to hide that column.

---

## 2. The hard rule — add/edit options via the WEB UI only

**Never** create, rename, reorder, or delete a Status option through the API
(`gh project field-create` on an existing field, `updateProjectV2Field`, or any GraphQL option
mutation). A programmatic option **edit or delete mints new option IDs and orphans every item's
existing value** — it silently wipes the whole column. This is not hypothetical: it caused a full
Status wipe of project #4 on 2026-08-11.

**To add or change an option:** open the board in the GitHub web UI → the Status field settings →
add/rename/reorder there. Then run `ensure-project` once so the field cache picks up the new option
(the cache also self-refreshes on a miss + retries — PLAN 0072.013 — so a freshly-added option like
`Review` resolves even without the manual refresh).

### What the code *is* allowed to do

`gh-pipeline.sh` treats `_GHP_STATUS_OPTIONS` two ways, both non-destructive:

1. **First-time creation only** — if the Status field does **not exist**, it is created once with the
   full canonical list (`_ghp_ensure_status_field`, guarded on the field being absent).
2. **Drift warning** — if the field exists, each canonical option missing from the live board emits a
   **warning that tells you to add it via the web UI**. The code never mutates existing options.

So reconciling the canonical list (this plan) changes *what gets warned about* and *what a
from-scratch board would be seeded with* — it can never touch a live board's options.

---

## 3. Keeping the list in sync

The canonical list is code (`_GHP_STATUS_OPTIONS`) + this doc + the live board. When they diverge:

- **code vs board** → the `ensure-project` drift warning surfaces it; resolve by adding the option in
  the web UI (board follows code) **or** by amending the list + this doc (code follows a deliberate
  board decision). Pin any change with the `canonical Status options` self-test.
- **PARKED / view-local extras** — a board may carry extra options (e.g. `PARKED`) not in the
  canonical set. The drift check only warns on canonical options *missing*; board-only extras are
  left untouched and are not an error.
