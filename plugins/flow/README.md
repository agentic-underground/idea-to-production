# FLOW — Deliver the roadmap flow

> The DELIVER stage of the value cycle — the roadmap surface and its deterministic MCP backend,
> shipped together so "what's on the roadmap" is one local, ~0-token answer that travels with the project.

FLOW owns the **DELIVER** phase of the idea-to-production lifecycle — between IDEATE and DESIGN, where the
IDEA package becomes a dependency-ordered roadmap. It ships the first-party **flow-mcp** Ruby server (Ruby
>= 3.3.8, standard library only) and the `/flow` command surface in one self-contained plugin: the command
resolves its backend through `${CLAUDE_PLUGIN_ROOT}` only, with no dependency on any sibling plugin. Install
it standalone, or alongside [`operate`](../operate/) as the DELIVER companion.

## What's inside

| Component | What it does | Command |
|---|---|---|
| **pull** | the headline verb — pull the **next** `.i2p/roadmap/` backlog item, carry it into the active lane, and drive it through foundry's internal builder to a delivered increment (wraps `/foundry:foundry`; refuses on an empty/ambiguous backlog) | `/flow:pull` |
| **flow** | carry value — advance one `.i2p/roadmap/` item to its next lane (recording who/what/cost via the flow-mcp MCP), or report the current flow state | `/flow [report\|carry <item> [to <stage>]\|ping]` |
| **flow-setup** | finish setting up the **flow-mcp MCP** (the roadmap server — `render_roadmap` answers "what's on the roadmap" at ~0 tokens): confirm a compliant Ruby (>= 3.3.8), walk the one-time `/mcp` approval, verify the connection | `/flow-setup` |

`/flow:pull` is the intuitive name for the BUILD cycle: *"I want to pull from the backlog"* maps to
`/flow:pull`, not to `/foundry:foundry` (the internal engine it wraps). See
[`commands/pull.md`](commands/pull.md) / [`skills/pull/SKILL.md`](skills/pull/SKILL.md).

## Common to every plugin

Like every `idea-to-production` plugin, FLOW also ships the universal command trio:

| Command | What it does |
|---|---|
| `/flow:check` | verify FLOW's runtime — Ruby >= 3.3.8 (runs flow-mcp), plus `jq` — a ✓/✗ table by tier; degrades to the `/flow:flow-by-hand` runbook when absent (advisory; `--strict` to fail on a missing required tool) |
| `/flow:inspect` | audit the FLOW plugin itself — its commands, skills, the flow-mcp server, and hooks — for drift, gaps, and duplication → a severity-ranked report |
| `/flow:self-improve` | fold delivery feedback back into FLOW — reflect on one element against the KAIZEN covenant, improve it on a branch, run `/foundry:pr-review`, open a PR (never self-merge) |

## The flow-mcp MCP

`flow-mcp` is the marketplace's own Ruby server — an interpreted server (Ruby >= 3.3.8, standard library
only; no gems, no build, no binary, nothing downloaded or pinned) launched by `bin/flow-mcp`, which finds a
compliant Ruby on the host and execs the Ruby server. Its verbs — `render_roadmap`, `list_items`,
`post_status`, `set_wait_go`, `append_spend`, `ping`, … — surface as `mcp__flow-mcp__*` once the one-time
MCP approval is granted (`/flow-setup` walks it). `render_roadmap` answers "what's on the roadmap" by local
compute at ~0 LLM tokens; the raw `.i2p/roadmap/` scan is the slow fallback. When no compliant Ruby is
present, the `/flow:flow-by-hand` runbook operates the `.flow/` files by hand. See the
[flow-mcp README](flow-mcp/README.md) for the server and its registration.

← the [marketplace root](../../README.md)
