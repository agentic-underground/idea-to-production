---
name: flow-server-status-lane-model
description: flow-server canonical Status enum is do|doing|done (3) over 4 tree folders backlog/do/doing/done; post_status, gate, and front-matter labels — the facts /flow carry docs must match
metadata:
  type: project
---

The flow-server's authoritative value-flow model (verify against source, don't trust docs):

- **Status enum** (`domain/model.rs`): `Do | Doing | Done` — THREE values, serde lowercase `do|doing|done`. There is NO `backlog`/`pending` status.
- **Tree folders** (`history.rs TREE_FOLDERS`): FOUR — `["backlog","do","doing","done"]`. `status_for_folder`: `backlog`→`Do`, `do`→`Do`, `doing`→`Doing`, `done`→`Done`. So **backlog and do BOTH map to Status::Do** (backlog/do/doing/done is the lane chain, not backlog/doing/done).
- **post_status** MCP verb accepts enum `["do","doing","done"]` only (mcp.rs input_schema). `backlog` is NOT a valid status arg — passing it = JSON-RPC -32602.
- **post_status writes the tree itself** (store.rs:230): moves the item file to `tree_folder(status)` AND rewrites `status:` front-matter via `tree_status_label` (`Do`→`PENDING`, `Doing`→`IN PROGRESS`, `Done`→`DONE`), THEN commits in-memory. It is NOT a pure in-memory setter. An agent doing its own `git mv` + front-matter rewrite AND calling post_status double-writes / can conflict (post_status's own move would no-op or clash since the file already moved).
- **post_status / append_spend refuse while gate==WAIT** (`advance_status`/`append_spend` return `FlowError::Waiting`). This is the dependency/governance gate. A carry that does its own git mv but is refused by post_status leaves the tree advanced while the board status didn't change → divergence.
- **annotate** "pauses the item" per its tool description (mcp.rs:78) — using it for who/what telemetry has a side effect (pause), not a neutral note.
- **Item id**: MCP verbs take the slug form `item-N` (e.g. `item-42`), NOT bare `41`. Tree front-matter `id:` is bare `N`; the store maps `item-N`↔`N`.

**Why:** PR #102 (/flow carry+report) docs claimed lanes `backlog→doing→done`, mapped `backlog`→`PENDING`, and told the agent to git-mv AND call post_status with the lane name — all four wrong against this model.

**How to apply:** Any /flow, carriage-agent, or roadmap-carry doc review — check the status arg is do|doing|done, the lane chain includes `do`, who-does-the-tree-write (agent vs post_status, not both), the WAIT-gate refusal path, and item-N id form.
