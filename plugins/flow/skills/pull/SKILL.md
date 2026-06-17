---
name: pull
description: >
  Pull the next roadmap item to a delivered increment — the headline user-facing verb that selects the
  next `.i2p/roadmap/` backlog item, carries it into the active lane, and drives it through foundry's
  internal builder. Trigger with /flow:pull (or "pull from the backlog", "pull the next item", "build the
  next roadmap item", "take the next thing to product", "what's next — build it"). The intuitive name for
  today's `/foundry:foundry` cycle: it COMPOSES the flow carry path + the foundry conveyor, it does not
  re-implement the build. Refuses and asks when the backlog is empty or the next item is ambiguous —
  never guesses which item to build.
---

# pull — pull the next item, carry it, build it

`/flow:pull` is the **user-facing entry to the BUILD conveyor**. The owner directive (epic [93],
[`docs/SLASH_COMMANDS.md`](../../../../docs/SLASH_COMMANDS.md)) is that *"I want to pull from the backlog"*
must map to an intuitive verb, **not** to `/foundry:foundry` by name — so this skill is the intuitive
wrapper, and `/foundry:foundry` remains the internal engine it drives.

**This skill is thin by design — the rigour is foundry's, unchanged.** It composes two already-shipped
capabilities and adds only the selection + refuse-on-ambiguity logic:

- **carry** — the [`flow`](../flow/SKILL.md) skill's carry path (roadmap [41]): the typed flow-mcp verbs
  that move an item between lanes and record who/what/cost. `pull` reuses it verbatim; it never `git mv`s
  files or hand-edits front-matter, and it respects the `Wait` gate.
- **the foundry builder** — `/foundry:foundry`, the internal conveyor (builder-lead →
  lifecycle-orchestrator → ds-step-* + handlers, gated by the reviewer panel). `pull` invokes it scoped to
  the one carried item; it does not re-implement any conveyor station.

## 1. Select the next item

Defer to the roadmapper's "next" definition (do not invent one):

1. The **`do/` lane** is the groomed "ready to pull" queue — the next item is the single item there,
   lowest `id` first.
2. If `do/` is empty, fall back to the **lowest-`id` `PENDING` `backlog/` item** whose `depends_on` are
   all `done`.

Read the tree via the flow-mcp `render_roadmap` / `list_items` verbs (same source `/flow report` uses).

## 2. Refuse on empty or ambiguous — the unwanted-behaviour guard

**EARS (unwanted behaviour): IF the backlog is empty OR the next item is ambiguous THEN `/flow:pull` SHALL
refuse and ask, never guess which item to build.** Concretely, STOP and ask — moving and building nothing —
when:

- **Empty backlog** — nothing in `do/` and nothing `PENDING` in `backlog/`. Report "nothing to pull";
  point at `/foundry:roadmapper` to add an item.
- **Ambiguous next** — more than one equal candidate (multiple items competing for "next" with no ordering
  signal). List them; ask which.
- **Unmet dependencies** — the next item has a `depends_on` not yet `done`. Name the blocker; ask whether
  to pull it first or override.

## 3. Carry → build → deliver

1. **Carry** the selected item into `doing/` via the [`flow`](../flow/SKILL.md) carry path (gate-check with
   `get_item`; `post_status item-N doing`; `append_spend`; `annotate "<who> — <what>"`).
2. **Build** — invoke `/foundry:foundry` scoped to that one item; the conveyor drives it through steps 0–9
   + story at 100% coverage with the reviewer + perf-delta gates. The build is foundry's, not re-stated
   here.
3. **Deliver** — on a green delivered increment, carry the item forward to `done/` via the same carry path.

## Why a wrapper, not a rename

`/foundry:foundry` is not deleted or renamed — it stays the documented internal engine
([`../../../foundry/commands/foundry.md`](../../../foundry/commands/foundry.md)). `/flow:pull` adds an
intuitive front door over it. Foundry's conveyor skills (`builder`, `lifecycle-states`, …) and the
`ds-step-*` agents stay **agent-internal** — invoked by the conveyor, never typed by a user.
