---
description: Value-flow — carry a roadmap item to its next stage (recording who/what/cost), or report the current flow state.
---

The **flow** command is the lightweight value-carry verb: advance one item through the
`.i2p/roadmap/` lanes without reaching for the heavyweight FOUNDRY cycle, and report the current
state of value flow. Pick the route by `$ARGUMENTS` (default: `report`).

**Contract — defer to the flow-server, do not paraphrase it.** The lanes, the status vocabulary, and
the file move are all owned by the flow-server's typed MCP verbs; this command drives them, it does not
re-implement them. The canonical lane chain (see [`.i2p/roadmap/README.md`](../../../.i2p/roadmap/README.md)) is:

```
backlog → do → doing → done        (folder = status; backlog is intake)
```

The board status the verbs accept is **`do` · `doing` · `done`** (the three `post_status` values).
`backlog` is the intake folder (status `do`); carrying *forward* from it lands in `do`.

## `report` (default) — render the current value flow

Call the MCP verb **`render_roadmap`** (`mcp__…__flow-server__render_roadmap`; it's a deferred tool —
if it's not in your tool list, `ToolSearch` for `flow-server__render_roadmap` first). Print its text
verbatim — it groups items by stage at ~0 LLM tokens. Then, for any item carried this session, append
its **who / what / cost** (the `annotate` text and `append_spend` total you wrote on carry).

If `render_roadmap` returns empty while `.i2p/roadmap/` has files on disk, the pinned MCP binary is
stale — call **`ping`** (below) to confirm, then fall back to scanning the tree directly: list each
lane folder and its `.md` items. Never print an empty/misleading report when the tree is non-empty.

## `carry <item> [to <stage>]` — advance one item

The flow-server's **`post_status`** is the single writer: it moves the item file between
`.i2p/roadmap/` folders **and** rewrites its `status:` front-matter itself. So `carry` calls the verbs;
it never `git mv`s the file or edits front-matter by hand (doing both would double-write and fight the
server). Each verb is deferred — `ToolSearch` for `flow-server__<verb>` if it's not in your tool list,
and pass the item id as the slug **`item-N`** (the numeric tree id `N` prefixed with `item-`).

1. **Resolve `<item>`** to exactly one roadmap item — by id number (e.g. `41` → `item-41`) or an
   unambiguous title match. **If zero or more than one match, STOP and ask; never guess.**
2. **Resolve the target status** — `to <stage>` must be one of **`do` · `doing` · `done`** (else STOP
   and ask). Omitted ⇒ the next status forward in the chain (`do`→`doing`→`done`; from the `backlog`
   intake, forward is `do`). Refuse if already at `done`.
3. **Check the gate.** Read the item (`get_item item-N`); **if its `gate` is `Wait`, STOP and refuse** —
   `post_status`/`append_spend` are rejected on a WAIT-gated item. Tell the user to clear it with
   `set_wait_go item-N go` first. Move nothing until the gate is `Go`.
4. **`post_status item-N <status>`** — the authoritative transition. The server moves the file to the
   `<status>` folder and updates `status:` (`do`→PENDING, `doing`→IN PROGRESS, `done`→DONE).
5. **`append_spend item-N <tokens>`** — add the cost spent carrying it, if known. (Do this *before*
   step 6 so it is recorded even if a later call gates.)
6. **`annotate item-N "<who> — <what>"`** — record the who/what on the card (the agent/handler and the
   activity, e.g. `"handler:foundry — implementing #41"`), mirroring the carriage-agent model. Do this
   last.
7. **Report** the move: `item-N <from> → <to>`, plus the who / what / cost you recorded.

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
