---
name: flow
description: >
  Carry value through the roadmap — the lightweight verb that advances ONE `.i2p/roadmap/` item to its
  next lane (recording who is processing it · what they are doing · the running cost), and reports the
  current state of value flow. Trigger with /flow [report|carry <item> [to <stage>]|ping] (or "carry 41
  to doing", "advance this item", "what's the flow state?", "report the roadmap flow"). Use this instead
  of reaching for the heavyweight FOUNDRY cycle just to move an item one stage. The flow-mcp server is a
  data-only MCP service; carry and report both go through its typed, token-authenticated MCP verbs.
---

# flow — carry value, report flow

The flow-mcp server ([`../../flow-mcp/`](../../flow-mcp/README.md)) is a **data-only MCP service**: it
ingests the `.i2p/roadmap/` tree and serves typed verbs for stage transitions and telemetry. There is no
running web board — the live SVG governance UI was removed (roadmap [39]); `report` is its on-demand
successor view. This skill is the manual front door for advancing items and reporting state.

## The lanes — owned by the flow-mcp server, not restated here

The canonical lane chain ([`.i2p/roadmap/README.md`](../../../../.i2p/roadmap/README.md)) is
**`backlog → do → doing → done`** (folder = status; `backlog` is intake). The board status the verbs
accept is the three values **`do · doing · done`**; `backlog` maps to status `do`. **Defer to that
contract** — the `post_status` verb owns the status vocabulary and the file move; this skill drives the
verbs rather than paraphrasing the model (a recurring drift this skill must not reintroduce).

## `/flow report` (default)

Render the current value flow. Call the MCP verb **`render_roadmap`** (a ~0-token rendered table grouped
by stage) and print it verbatim; for items carried this session, append the **who / what / cost** you
recorded. If it returns empty while the tree is non-empty, the pinned binary is stale — `ping` to
confirm, then fall back to scanning the lane folders directly. Never emit an empty report over a
non-empty tree.

## `/flow carry <item> [to <stage>]`

`post_status` is the **single writer** — it moves the item file between `.i2p/roadmap/` folders *and*
rewrites its `status:` front-matter. So carry calls the verbs and never `git mv`s or edits front-matter
by hand. Pass ids as the slug **`item-N`**.

1. **Resolve the item** to exactly one file (id `N` → `item-N`, or unambiguous title). Zero/many
   matches → **stop and ask, never guess**.
2. **Resolve the status** — a named `to <stage>` must be one of `do · doing · done` (else stop and ask);
   omitted means the next status forward (`do`→`doing`→`done`; from `backlog`, forward is `do`). Refuse
   past `done`.
3. **Check the gate** — read the item (`get_item`); if its `gate` is `Wait`, **refuse the carry** (the
   server rejects `post_status`/`append_spend` on a WAIT item) and tell the user to `set_wait_go … go`
   first. Move nothing until it is `Go`.
4. **`post_status item-N <status>`** — the authoritative transition (server moves the file + updates
   `status:`).
5. **`append_spend item-N <tokens>`** — the cost, recorded before the annotation so a later call can't
   drop it.
6. **`annotate item-N "<who> — <what>"`** — who is processing it + the activity, last. This mirrors the
   **carriage-agent** who/what/cost model ([`../../agents/`](../../agents)): one carry, one annotated
   transition, so state is always reportable.

## `/flow ping`

MCP health check — prints the server `message`, `version`, `items`, and `source`, and flags a stale
pinned binary (fix: `/flow:flow-setup`).

## Roadmap resolution

The flow-mcp server resolves its source in order: `$FLOW_ROADMAP` (env override) → the **`.i2p/roadmap/`
tree** (the authoritative file-per-item source, folder = status; roadmap [42]) → a legacy single
`ROADMAP.md`. The tree is auto-detected — no pin needed. Item count is the number of `.md` files across
the lane folders.

## The flow-mcp verbs — the deterministic `/flow` bindings

The `/flow` surface is a **thin command layer over the `flow-mcp` MCP verbs**: the verbs are the
**deterministic, CPU-layer (client-side) actions** — typed, token-authenticated, the sole serialized
writer of the roadmap markdown + JSONL event log. They are **never typed directly** (`/mcp__…` is not a
command); `/flow`, `/flow:pull`, and `/flow:flow-setup` *call* them. This is the binding map (folded here
from the slash-command catalog's MCP appendix so the surface and its backend live in one place); it
matches the 14 verbs shipped in [`../../flow-mcp/src/mcp.rs`](../../flow-mcp/src/mcp.rs) exactly — a
documented verb that is not in the binary (or vice versa) is drift to reconcile, never a phantom.

**Read verbs** (no mutation — safe, ~0 LLM tokens):

| Verb | Does | Bound by |
|---|---|---|
| `render_roadmap` | Render the whole roadmap as a stage-grouped table | `/flow report`, `/flow:pull` (select), `/flow:flow-setup` (verify) |
| `list_items` | Items grouped `pending{wait,go}` / `in_progress` / `done` | `/flow:pull` (select), `/flow report` |
| `get_item` | One item incl. deps + annotations + **gate** | `/flow carry` (gate check), `/flow:pull` |
| `list_events` | The append-only JSONL event log (optional `kind` filter) | flow telemetry / audit |
| `validate_connection` | Check a `from→to` dependency edge without writing | dependency-graph guard |
| `ping` | Health check — `message` · `version` · `items` · `source`; flags a stale pinned binary | `/flow ping`, `/flow:flow-setup` |

**Mutating verbs** (the writer path — the server moves files + rewrites front-matter itself, so callers
never `git mv` or hand-edit):

| Verb | Does | Bound by |
|---|---|---|
| `post_status` | The **single writer**: move the item file between lane folders + rewrite `status:` | `/flow carry`, `/flow:pull` (carry → `doing`, then → `done`) |
| `append_spend` | Add to the running token cost (rolls up the dependency tree) | `/flow carry`, `/flow:pull` |
| `annotate` | Record who/what on the card (also pauses the item) | `/flow carry`, `/flow:pull` |
| `set_wait_go` | Set an item's gate `Wait`/`Go` (a `Wait` item refuses carry) | gate control (clear before carry) |
| `set_item_model` | Pin the per-job model (Haiku/Sonnet/Opus/Fable) | model selection |
| `mutate_connection` | Add/remove a dependency edge (`op: add|remove`) | dependency-graph editing |
| `request_rewrite` | Bump an item's draft# with a comment | rewrite request |
| `append_sysmsg` | Append to the system-message feed | sysmsg feed |

So `/flow report` → `render_roadmap`; `/flow carry` (and `/flow:pull`) → `get_item` (gate) ·
`post_status` · `append_spend` · `annotate`; `/flow ping` → `ping`. Each is a **deferred** tool —
`ToolSearch` for `flow-mcp__<verb>` if it isn't already in your tool list. When the verbs are absent
entirely, the server isn't connected: run `/flow:flow-setup`.
