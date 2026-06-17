# FLOW — Deliver the roadmap flow

> The DELIVER stage of the value cycle — the roadmap surface and its deterministic MCP backend,
> shipped together so "what's on the roadmap" is one local, ~0-token answer that travels with the project.

FLOW owns the **DELIVER** phase of the idea-to-production lifecycle — between IDEATE and DESIGN, where the
IDEA package becomes a dependency-ordered roadmap. It ships the first-party **flow-mcp** Rust binary and the
`/flow` command surface in one self-contained plugin: the command resolves its backend through
`${CLAUDE_PLUGIN_ROOT}` only, with no dependency on any sibling plugin. Install it standalone, or alongside
[`operate`](../operate/) as the DELIVER companion.

## What's inside

| Component | What it does | Command |
|---|---|---|
| **flow** | carry value — advance one `.i2p/roadmap/` item to its next lane (recording who/what/cost via the flow-mcp MCP), or report the current flow state | `/flow [report\|carry <item> [to <stage>]\|ping]` |
| **flow-setup** | finish setting up the **flow-mcp MCP** (the roadmap server — `render_roadmap` answers "what's on the roadmap" at ~0 tokens): pre-cache the binary, walk the one-time `/mcp` approval, verify the connection | `/flow-setup` |

## The flow-mcp MCP

`flow-mcp` is the marketplace's own Rust binary — a launcher that retrieves a **pinned** prebuilt release
(tag in `bin/RELEASE`) from GitHub Releases and SHA256-verifies it against the **committed** `bin/SHA256SUMS`
(no Rust toolchain required on the destination). Its verbs — `render_roadmap`, `list_items`, `post_status`,
`set_wait_go`, `append_spend`, `ping`, … — surface as `mcp__flow-mcp__*` once the one-time MCP approval is
granted (`/flow-setup` walks it). `render_roadmap` answers "what's on the roadmap" by local compute at
~0 LLM tokens; the raw `.i2p/roadmap/` scan is the slow fallback. See the
[flow-mcp README](flow-mcp/README.md) for the binary, its registration, and the pinned-release model.

← the [marketplace root](../../README.md)
