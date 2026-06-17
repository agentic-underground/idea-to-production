---
name: flow-server-tool-naming-drift
description: flow-server MCP gate tool is named set_wait_go in code; EARS/README/feature docs call it set_gate (the HTTP/store method name) — recurring vocabulary drift
metadata:
  type: project
---

In `plugins/mission-control/flow-server`, the MCP gate-control tool is named
**`set_wait_go`** (TOOLS array + `call_tool` match arm in `src/mcp.rs`; HTTP route handler
`set_wait_go` in `api.rs`). The underlying **store/domain method** is `set_gate`
(`store.rs`, `domain/model.rs`). These are two different names for related things.

Docs repeatedly call the MCP tool `set_gate` by mistake — seen in item [37]'s
`.foundry/[37]-ears.md` ("five tools ... `set_gate`"), `README.md` MCP section, and
`.foundry/[37].feature`. The actual tests correctly use `set_wait_go`.

**Why:** the store API verb (`set_gate`) leaked into user-facing tool documentation; the
MCP surface has always exposed `set_wait_go`. Not a code defect — a vocabulary-consistency
(SMU) drift across artefacts.

**How to apply:** when reviewing flow-server MCP work, don't flag `set_wait_go` in tests as
wrong — it is the real tool name. Do flag docs that promise a `set_gate` MCP tool, since an
agent reading the doc and calling `set_gate` over MCP gets method-not-found. Candidate
KAIZEN fix: align the EARS/README/feature vocabulary to `set_wait_go` (or rename the tool).
Related: [[project-plugin-count-drift]] is the same doc-vs-source drift class.

**Generalised to ARGUMENT vocabulary, not just tool names (PR #102, item [41]):** the
`/flow carry` command/skill docs tell the agent to call `post_status` and "set the new
stage" using the front-matter labels `PENDING`/`IN PROGRESS`/`DONE` (and lane name
`backlog`). But `post_status` deserializes `Status` via `#[serde(rename_all="lowercase")]`
(`domain/model.rs:14-22` → `Do`/`Doing`/`Done`) through `arg_enum` (`mcp.rs:308,456`), so
it ONLY accepts `"do"`/`"doing"`/`"done"` — and there is no enum value for the
backlog/PENDING state at all. An agent following the doc verbatim gets `invalid_params` on
the most common move. Flag docs that name an MCP-verb argument value the typed Rust surface
won't accept, the same way you flag wrong tool names. Note: the `annotate` tool description
says "(pauses the item)" but `store.annotate` (`store.rs:381`) only appends + commits an
`Annotated` event — it flips no gate; don't flag a carry route's `annotate` call as pausing.
