---
description: Pull the next roadmap backlog item and drive it to a delivered increment — the intuitive user-facing verb that wraps foundry's internal builder.
---

The **pull** command is the headline value verb: *"I want to pull from the backlog."* It selects the
**next `.i2p/roadmap/` backlog item**, carries it into the active lane, and drives it through foundry's
internal builder to a delivered increment — wrapping today's `/foundry:foundry` cycle behind an intuitive,
user-facing name. (Owner directive, epic [93] / [`docs/SLASH_COMMANDS.md`](../../../docs/SLASH_COMMANDS.md):
*"I want to pull from the backlog" ≠ "/foundry:foundry"* — the build orchestrator is non-intuitive;
`/flow:pull` is the intended verb.)

**This is a thin verb — it COMPOSES, it does not re-implement.** Selection and the carry transition reuse
the already-shipped [`flow`](flow.md) carry path (roadmap [41]); the build rigour is foundry's
`/foundry:foundry` conveyor (the internal engine), referenced and invoked, never re-built here.

## 1. Select the next item

"Next" is the **groomed, ready-to-pull item**, resolved in this order (defer to the roadmapper's "next"
definition, do not invent your own):

1. The **`do` lane** (`.i2p/roadmap/do/`) is the groomed "ready to pull" queue — the next item is the
   single item there, lowest `id` first.
2. If `do/` is empty, fall back to the **lowest-`id` `PENDING` item in `backlog/`** whose `depends_on`
   are all already `done`.

Use the flow-mcp `render_roadmap` / `list_items` verbs to read the tree (the same source `/flow report`
uses); do not ad-hoc-scan unless the binary is stale (see [`flow.md`](flow.md) `ping`).

## 2. Refuse on empty or ambiguous — never guess

This is the **unwanted-behaviour guard** (EARS): `/flow:pull` SHALL refuse and ask, never guess which item
to build, when ANY of these hold:

- The backlog is **empty** — no item in `do/` and none `PENDING` in `backlog/`. → STOP, report "nothing to
  pull", ask the user to add an item (`/foundry:roadmapper`).
- The next item is **ambiguous** — more than one equal candidate (e.g. multiple same-`id`-tier items in
  `do/`, or several `PENDING` items with no ordering signal). → STOP, list the candidates, ask the user
  which one.
- The next item has **unmet dependencies** — a `depends_on` that is not yet `done`. → STOP, name the
  blocking item, ask the user whether to pull the blocker first or override.

Refuse before carrying anything. No file moves, no build, until the user disambiguates.

## 3. Carry it into the active lane

Reuse the [`flow`](flow.md) **carry** path exactly — call its MCP verbs (`get_item` to check the gate,
`post_status item-N doing`, `append_spend`, `annotate`); do not `git mv` or hand-edit front-matter, and
**respect the `Wait` gate** (refuse if gated, as `/flow carry` does). The item lands in `doing/` with its
who/what/cost recorded.

## 4. Drive it through foundry's internal builder

Invoke `/foundry:foundry` (the internal engine) **scoped to this one item** — pass the carried item as the
cycle's scope so builder-lead → lifecycle-orchestrator drive it through steps 0–9 + story with the full
reviewer + perf-delta gates. The rigour is foundry's, unchanged; `/flow:pull` only chose the item and
carried it. On a delivered increment, carry the item forward to `done/` via the same `/flow carry` path.

```bash
# Routing is agent-driven (the steps above are MCP + skill composition, not shell).
echo "flow pull: select next .i2p/roadmap/ item → carry → /foundry:foundry"
```
