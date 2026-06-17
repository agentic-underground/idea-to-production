---
description: Value-flow — carry a roadmap item to its next stage (recording who/what/cost), or report the current flow state.
---

The **flow** command is the lightweight value-carry verb: advance one item through the
`.i2p/roadmap/` lanes without reaching for the heavyweight FOUNDRY cycle, and report the current
state of value flow. Pick the route by `$ARGUMENTS` (default: `report`).

The **lanes** are exactly the subfolders of `.i2p/roadmap/`, in flow order — today
**`backlog` → `doing` → `done`** (folder = stage). The carry verb moves an item one lane forward
(or to a named lane) and records *who is processing it · what they are doing · the running cost* via
the flow-server's typed MCP telemetry verbs, so the board state is always reportable.

## `report` (default) — render the current value flow

Call the MCP verb **`render_roadmap`** (`mcp__…__flow-server__render_roadmap`; it's a deferred tool —
if it's not in your tool list, `ToolSearch` for `flow-server__render_roadmap` first). Print its text
verbatim — it groups items by stage at ~0 LLM tokens. Then, for any item carried this session, append
its **who / what / cost** (the `annotate` text and `append_spend` total you wrote on carry).

If `render_roadmap` returns empty while `.i2p/roadmap/` has files on disk, the pinned MCP binary is
stale — call **`ping`** (below) to confirm, then fall back to scanning the tree directly: list each
lane folder and its `.md` items. Never print an empty/misleading report when the tree is non-empty.

## `carry <item> [to <stage>]` — advance one item

1. **Resolve `<item>`** to exactly one roadmap item — by leading id number (e.g. `41`) or an
   unambiguous title match across all lane folders. **If zero or more than one match, STOP and ask;
   never guess** (EARS unwanted-behaviour: ambiguous item → refuse).
2. **Resolve the target stage.** With `to <stage>`, it must name an existing lane folder under
   `.i2p/roadmap/`; **if it is not a valid lane, STOP and ask.** Without `to <stage>`, carry the item
   **one lane forward** in flow order (`backlog`→`doing`→`done`); refuse if it is already in the last
   lane.
3. **Move the file** with `git mv .i2p/roadmap/<from>/<file> .i2p/roadmap/<to>/<file>`.
4. **Update the `status:` front-matter** to match the destination lane:
   `backlog` → `PENDING`, `doing` → `IN PROGRESS`, `done` → `DONE`.
5. **Record telemetry** against the item id through the flow-server MCP verbs (each is deferred —
   `ToolSearch` for `flow-server__<verb>` if absent):
   - **`post_status`** — set the item's status to the new stage (the authoritative transition).
   - **`annotate`** — write the **who / what**: the agent/handler processing it and the activity
     (e.g. `"carried to doing — handler:foundry, implementing #41"`).
   - **`append_spend`** — add the **cost** (tokens) spent carrying it, if known.
6. **Report** the move back to the user: `<id> <from> → <to>`, plus the who / what / cost you recorded.

## `ping` / `hello` — MCP health check

Call the MCP verb **`ping`** and print its `message` ("hello from the flow MCP") plus `version`,
`items`, and `source`. **Flag staleness:** if `items` is 0 (or `source` is null) while `.i2p/roadmap/`
has files on disk, the pinned MCP binary is stale — the fix is `/mission-control:flow-setup` to
re-cache and re-verify. If you have no `mcp__…__flow-server__*` tools at all, it isn't connected —
restart Claude Code after install/update, then `/mcp` and approve `flow-server`.

```bash
# Routing is agent-driven (the verbs above are MCP calls, not shell). Default route: report.
echo "flow route: ${ARGUMENTS:-report}"
```

The web governance board has been removed (roadmap [39]); there is no `start`/`stop`/`url`/`build`
daemon to control — the flow-server is now a data-only MCP service, and `report` is its on-demand view.
