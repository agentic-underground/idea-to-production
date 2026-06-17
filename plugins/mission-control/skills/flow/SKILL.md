---
name: flow
description: >
  Carry value through the roadmap — the lightweight verb that advances ONE `.i2p/roadmap/` item to its
  next lane (recording who is processing it · what they are doing · the running cost), and reports the
  current state of value flow. Trigger with /flow [report|carry <item> [to <stage>]|ping] (or "carry 41
  to doing", "advance this item", "what's the flow state?", "report the roadmap flow"). Use this instead
  of reaching for the heavyweight FOUNDRY cycle just to move an item one stage. The flow-server is a
  data-only MCP service; carry and report both go through its typed, token-authenticated MCP verbs.
---

# flow — carry value, report flow

The flow-server ([`../../flow-server/`](../../flow-server/README.md)) is a **data-only MCP service**: it
ingests the `.i2p/roadmap/` tree and serves typed verbs for stage transitions and telemetry. There is no
running web board — the live SVG governance UI was removed (roadmap [39]); `report` is its on-demand
successor view. This skill is the manual front door for advancing items and reporting state.

## The lanes

The lanes are exactly the subfolders of `.i2p/roadmap/`, in flow order — today
**`backlog` → `doing` → `done`** (folder = stage). Adding a lane is adding a folder; this skill reads
whatever lanes exist rather than hard-coding a chain. Each item is one `.md` file with `status:`
front-matter; the lane it sits in is the authoritative stage, and its `status:` mirrors the lane
(`backlog`→`PENDING`, `doing`→`IN PROGRESS`, `done`→`DONE`).

## `/flow report` (default)

Render the current value flow. Call the MCP verb **`render_roadmap`** (a ~0-token rendered table grouped
by stage) and print it verbatim; for items carried this session, append the **who / what / cost** you
recorded. If it returns empty while the tree is non-empty, the pinned binary is stale — `ping` to
confirm, then fall back to scanning the lane folders directly. Never emit an empty report over a
non-empty tree.

## `/flow carry <item> [to <stage>]`

Advance one item one lane forward (or to a named lane):

1. **Resolve the item** to exactly one file (by id number or unambiguous title). Zero/many matches →
   **stop and ask, never guess**.
2. **Resolve the stage** — a named `to <stage>` must be an existing lane (else stop and ask); omitted
   means the next lane in flow order (refuse past the last lane).
3. **`git mv`** the file between lane folders and **update `status:`** to match the destination.
4. **Record who / what / cost** against the item id through the flow-server telemetry verbs —
   **`post_status`** (the authoritative transition), **`annotate`** (who is processing it + the
   activity), **`append_spend`** (tokens spent). This mirrors the **carriage-agent** who/what/cost model
   ([`../../agents/`](../../agents)): one carry, one annotated transition, so state is always reportable.

## `/flow ping`

MCP health check — prints the server `message`, `version`, `items`, and `source`, and flags a stale
pinned binary (fix: `/mission-control:flow-setup`).

## Roadmap resolution

The flow-server resolves its source in order: `$FLOW_ROADMAP` (env override) → the **`.i2p/roadmap/`
tree** (the authoritative file-per-item source, folder = status; roadmap [42]) → a legacy single
`ROADMAP.md`. The tree is auto-detected — no pin needed. Item count is the number of `.md` files across
the lane folders.
