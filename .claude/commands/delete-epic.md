---
description: List an EPIC + every plan in its ## Plans table and, on your go/no-go, permanently delete them via scripts/roadmap/delete-epic.sh
argument-hint: <epic-order>   e.g. 0042 (or 42)
---

The user wants to delete a roadmap EPIC and the plans contained in it, using the committed tool
`scripts/roadmap/delete-epic.sh`. The requested EPIC order is: **$ARGUMENTS**

Follow this flow exactly — never hand-roll `gh issue delete`, and never delete without the go/no-go:

1. **If no order was given** (`$ARGUMENTS` is empty), ask the user which EPIC order to target (4-digit,
   leading zeros optional) and stop until they answer.

2. **LIST the targets (read-only).** Run:
   ```
   bash scripts/roadmap/delete-epic.sh $ARGUMENTS
   ```
   This resolves the EPIC issue + every PLAN in its `## Plans` table (handling both table formats and
   both numbering schemes) and prints the target set. Show the user that list (issue #, state, title).
   If it reports no EPIC found, say so and stop.

3. **Go/no-go.** Present an `AskUserQuestion` with two options — "Go — delete permanently" (first,
   recommended-style) and "No-go — cancel" — naming the exact issue numbers about to be deleted.
   Deletion is **permanent** (`gh issue delete`): gone from GitHub and the project board, no history.

4. **On "Go" only**, run:
   ```
   bash scripts/roadmap/delete-epic.sh $ARGUMENTS --delete
   ```
   Then confirm what was deleted. On "No-go", change nothing and say so.

Notes: LIST mode is the safe default; deletion requires the explicit `--delete`. The tool validates the
order to 1–4 digits (fail-closed). This command only targets an EPIC **and its own plans**; to delete a
single stray PLAN issue that is not part of an EPIC's `## Plans` table, handle that as a one-off and
confirm first.
