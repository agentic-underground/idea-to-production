# flow-mcp — EARS Specification

> The **canonical, language-neutral** behavioural contract for the flow-mcp server. This is the
> source of truth: the Ruby reference implementation (`../lib/flow_mcp/`), the Gherkin FEATURE suite
> (`features/`), and the markdown fallback runbook (`flow-by-hand`) all conform to *these* statements,
> not to any one implementation. EARS form reference:
> [`../../../foundry/knowledge/specs/ears.md`](../../../foundry/knowledge/specs/ears.md).
>
> **ID convention:** `EARS-FLOW-NNN`, three digits, permanent — never reuse or renumber. Every
> statement is covered by ≥1 `@EARS-FLOW-NNN`-tagged Gherkin scenario and ≥1 test referencing
> `# @EARS-FLOW-NNN`, across happy / unhappy / abuse paths.
>
> **"The server"** = the flow-mcp process (or, under the fallback, the agent performing the verb by
> hand). All JSON-RPC is **newline-delimited JSON-RPC 2.0 over stdio**; the only MCP protocol version
> is `2024-11-05`.

---

## 1. Transport & protocol

- **EARS-FLOW-001** — The server SHALL read one JSON-RPC request per newline-delimited line from
  stdin and write exactly one newline-terminated JSON-RPC response line to stdout for every request
  that carries an `id`.
- **EARS-FLOW-002** — WHEN the server receives an `initialize` request, THE SYSTEM SHALL respond with
  `result.protocolVersion`, `result.capabilities.tools` (an object), and `result.serverInfo`
  containing `name = "flow-mcp"` and a non-empty `version` string.
- **EARS-FLOW-003** — WHEN an `initialize` request names a `protocolVersion` the server implements
  (`2024-11-05`), THE SYSTEM SHALL echo that version in the response.
- **EARS-FLOW-004** — IF an `initialize` request names a `protocolVersion` the server does not
  implement, THEN THE SYSTEM SHALL respond with its own latest supported version (`2024-11-05`) rather
  than the requested one.
- **EARS-FLOW-005** — WHEN the server receives a request with no `id` member (a JSON-RPC
  notification, e.g. `notifications/initialized`), THE SYSTEM SHALL apply it and write no response.
- **EARS-FLOW-006** — WHEN the server receives a `tools/list` request, THE SYSTEM SHALL respond with
  `result.tools` as an array in which every element has `name`, `description`, and an `inputSchema`
  object.
- **EARS-FLOW-007** — The `tools/list` result SHALL contain exactly the 16 verbs `ping`,
  `list_items`, `get_item`, `set_wait_go`, `post_status`, `append_spend`, `set_item_model`,
  `validate_connection`, `mutate_connection`, `append_sysmsg`, `render_roadmap`, `annotate`,
  `request_rewrite`, `list_events`, `create_item`, `delete_item` — and every advertised name SHALL be
  dispatchable by `tools/call`.
- **EARS-FLOW-008** — The `inputSchema` of each arg-taking verb SHALL declare its real `properties`
  and `required` fields (not a hollow `{"type":"object"}`), with the `status` enum
  `["do","doing","done"]`, the `gate` enum `["wait","go"]`, and the `op` enum `["add","remove"]`.
- **EARS-FLOW-009** — IF a line read from stdin is empty or is not parseable JSON, THEN THE SYSTEM
  SHALL write a JSON-RPC error response with `id = null` and `error.code = -32700`, and continue
  reading subsequent lines.
- **EARS-FLOW-010** — IF a request names a `method` other than `initialize`, `notifications/initialized`,
  `initialized`, `tools/list`, or `tools/call`, THEN THE SYSTEM SHALL respond with `error.code =
  -32601` (method not found).
- **EARS-FLOW-011** — IF a `tools/call` names a tool that is not one of the 14 verbs, THEN THE SYSTEM
  SHALL respond with `error.code = -32602` and a message identifying the unknown tool.
- **EARS-FLOW-012** — WHEN stdin reaches EOF, THE SYSTEM SHALL exit the read loop and terminate with
  process exit code 0.
- **EARS-FLOW-013** — The server SHALL preserve each request's `id` verbatim in the corresponding
  response.

## 2. Item identity (ItemId)

- **EARS-FLOW-014** — The server SHALL accept an item id only WHERE it is non-empty, at most 64
  characters, composed solely of `[a-z0-9-]`, has no leading or trailing `-`, and contains no `--`.
- **EARS-FLOW-015** — IF a verb is called with an `id` (or `from`/`to`) argument that is not a string
  or is not a valid item id, THEN THE SYSTEM SHALL respond with `error.code = -32602` (invalid params)
  and SHALL NOT mutate any state.
- **EARS-FLOW-016** — The display sequence number `[N]` SHALL NOT be the item's identity; the slug id
  SHALL be, so reordering or board moves never invalidate edges, telemetry, or references.

## 3. Reading the board — `list_items`, `get_item`

- **EARS-FLOW-017** — WHEN `list_items` is called, THE SYSTEM SHALL return
  `{"pending":{"wait":[…],"go":[…]},"in_progress":[…],"done":[…]}`, placing each item by status
  (Do→pending, Doing→in_progress, Done→done) and, for pending items, by gate (Wait→pending.wait,
  Go→pending.go).
- **EARS-FLOW-018** — `list_items` SHALL list items within each group in the board's display order.
- **EARS-FLOW-019** — Each rendered item object SHALL carry `id`, `title`, `status`, `gate`, `tokens`,
  `model`, `draft`, `deps` (the ids this item depends on), `annotations` (its annotation texts in log
  order), `commits` (an empty array this cycle), and `pr` (null this cycle).
- **EARS-FLOW-020** — WHEN `get_item` is called with the id of an existing item, THE SYSTEM SHALL
  return `{"item": …}` rendered as in EARS-FLOW-019.
- **EARS-FLOW-021** — IF `get_item` names an id that is not an item in the flow, THEN THE SYSTEM SHALL
  respond with `error.code = -32004` (unknown item).
- **EARS-FLOW-022** — `list_items` and `get_item` SHALL NOT mutate any state.

## 4. Governance gate — `set_wait_go`

- **EARS-FLOW-023** — WHEN `set_wait_go` is called with a known id and `gate` in `{wait, go}`, THE
  SYSTEM SHALL set that item's gate to the given value and respond `{"ok": true}`.
- **EARS-FLOW-024** — Setting the gate SHALL be allowed regardless of the item's current gate (a WAIT
  item may be toggled, since toggling the gate is not itself a carriage-advance action).
- **EARS-FLOW-025** — IF `set_wait_go` names an id that does not exist, THEN THE SYSTEM SHALL respond
  with `error.code = -32000` and `error.data.error = "unknown"`, mutating nothing.
- **EARS-FLOW-026** — WHEN a gate is set, THE SYSTEM SHALL append a `gate_set` event to the event log
  before reporting success.
- **EARS-FLOW-027** — WHEN a gate is set, THE SYSTEM SHALL write the full id→gate map to the
  `gates.json` sidecar atomically (write a temp sibling, then rename).
- **EARS-FLOW-028** — IF writing the `gates.json` sidecar fails, THEN THE SYSTEM SHALL emit a warning
  to stderr and still report the gate change as successful (the event log is authoritative; the
  sidecar is a fast-restore convenience).

## 5. Carriage status — `post_status`

- **EARS-FLOW-029** — WHEN `post_status` is called with a known id and `status` in `{do, doing, done}`
  WHILE the item's gate is GO, THE SYSTEM SHALL set the item's status and respond `{"ok": true}`.
- **EARS-FLOW-030** — IF `post_status` targets an item WHILE its gate is WAIT, THEN THE SYSTEM SHALL
  refuse the change with `error.code = -32000` and `error.data.error = "waiting"`, leaving the status
  unchanged.
- **EARS-FLOW-031** — IF `post_status` names an id that does not exist, THEN THE SYSTEM SHALL respond
  with `error.code = -32000` and `error.data.error = "unknown"`.
- **EARS-FLOW-032** — WHEN a status change succeeds, THE SYSTEM SHALL append a `status_posted` event
  to the event log.
- **EARS-FLOW-033** — WHERE the board was ingested from a `.i2p/roadmap/` tree, WHEN a status change
  succeeds, THE SYSTEM SHALL write the change back to the tree by moving the item's file into the
  destination folder (`do`/`doing`/`done`) and rewriting its `status:` front-matter to the canonical
  label (`PENDING`/`IN PROGRESS`/`COMPLETE`).
- **EARS-FLOW-034** — IF the tree write-back fails, THEN THE SYSTEM SHALL roll the in-memory status
  back to its prior value and return the error, so memory never diverges from the unchanged tree.
- **EARS-FLOW-035** — WHERE more than one tree file shares the item's numeric id, THE SYSTEM SHALL
  write back the last match in folder order (the loader's authoritative copy) and SHALL emit a warning
  naming the duplicate.
- **EARS-FLOW-036** — WHERE the item has no file in the tree (e.g. a synthesized item), the tree
  write-back SHALL be a no-op and the status change SHALL still succeed.

## 6. Token spend — `append_spend`

- **EARS-FLOW-037** — WHEN `append_spend` is called with a known id and a non-negative integer `delta`
  WHILE the item's gate is GO, THE SYSTEM SHALL add `delta` to that item's own token tally and respond
  `{"total": <new tally>}`.
- **EARS-FLOW-038** — WHEN a spend is recorded, THE SYSTEM SHALL add the same `delta` to the rolled-up
  tally of every transitive ancestor of the item (each item it depends on, recursively).
- **EARS-FLOW-039** — The ancestor roll-up SHALL be applied even WHILE an ancestor is in WAIT, because
  a roll-up is a derived sub-tree total, not that ancestor's own carriage-advance action.
- **EARS-FLOW-040** — IF `append_spend` targets an item WHILE its own gate is WAIT, THEN THE SYSTEM
  SHALL refuse the spend with `error.code = -32000` and `error.data.error = "waiting"`, adding nothing.
- **EARS-FLOW-041** — IF `append_spend` names an id that does not exist, THEN THE SYSTEM SHALL respond
  with `error.code = -32000` and `error.data.error = "unknown"`.
- **EARS-FLOW-042** — IF `append_spend` is called without an integer `delta`, THEN THE SYSTEM SHALL
  respond with `error.code = -32602` (invalid params).
- **EARS-FLOW-043** — Token tallies SHALL saturate at the unsigned 64-bit maximum rather than
  overflow.
- **EARS-FLOW-044** — WHEN a spend succeeds, THE SYSTEM SHALL append a `spend_appended` event (with
  `delta` and the new `total`) to the event log and append one telemetry record
  (`{ts,item_id,agent,activity,tokens_delta,tokens_total,ancestors[]}`) to the telemetry ledger.
- **EARS-FLOW-045** — A spend recorded through `append_spend` SHALL be attributed to agent
  `"carriage-agent"` and activity `"spend"` in the telemetry record.

## 7. Model assignment — `set_item_model`

- **EARS-FLOW-046** — WHEN `set_item_model` is called with a known id and a string `model`, THE SYSTEM
  SHALL set that item's resolved model and respond `{"ok": true}`.
- **EARS-FLOW-047** — IF `set_item_model` names an unknown id, THEN THE SYSTEM SHALL respond with
  `error.code = -32000` and `error.data.error = "unknown"`.
- **EARS-FLOW-048** — IF `set_item_model` is called without a string `model`, THEN THE SYSTEM SHALL
  respond with `error.code = -32602` (invalid params).
- **EARS-FLOW-049** — WHEN a model is set, THE SYSTEM SHALL append a `model_set` event to the event
  log.

## 8. Dependency graph — `validate_connection`, `mutate_connection`

- **EARS-FLOW-050** — WHEN `validate_connection` is called with two known ids whose `from → to` edge
  would keep the graph acyclic, THE SYSTEM SHALL respond `{"ok": true}` and mutate nothing.
- **EARS-FLOW-051** — IF a proposed connection names an endpoint that is not a known item, THEN THE
  SYSTEM SHALL respond with `error.code = -32000` and `error.data.error = "unknown"`.
- **EARS-FLOW-052** — IF a proposed connection is a self-edge (`from == to`) or would make `from`
  reachable from itself (a cycle), THEN THE SYSTEM SHALL respond with `error.code = -32000` and
  `error.data.error = "cycle"`.
- **EARS-FLOW-053** — WHEN `mutate_connection` is called with `op = "add"` and a valid `from → to`
  edge, THE SYSTEM SHALL add the edge, append a `connection_added` event, and respond `{"ok": true}`.
- **EARS-FLOW-054** — Adding an edge that already exists SHALL be idempotent (no duplicate edge, still
  `{"ok": true}`).
- **EARS-FLOW-055** — WHEN `mutate_connection` is called with `op = "remove"` and an existing
  `from → to` edge, THE SYSTEM SHALL remove the edge, append a `connection_removed` event, and respond
  `{"ok": true}`.
- **EARS-FLOW-056** — IF `mutate_connection` with `op = "remove"` names an edge that does not exist
  (both endpoints known), THEN THE SYSTEM SHALL respond with `error.code = -32000` and
  `error.data.error = "broken_dep"`.
- **EARS-FLOW-057** — IF `mutate_connection` is called with an `op` other than `add` or `remove`, THEN
  THE SYSTEM SHALL respond with `error.code = -32602` (invalid params).
- **EARS-FLOW-058** — A refused connection mutation SHALL leave the edge set unchanged.

## 9. Comment & rewrite loop — `annotate`, `request_rewrite`

- **EARS-FLOW-059** — WHEN `annotate` is called with a known id and `text`, THE SYSTEM SHALL append a
  markdown annotation block for that comment and respond `{"ok": true}`.
- **EARS-FLOW-060** — The annotation block SHALL be appended to the item's `doc/<TITLE>_PLAN.md` plan
  document WHERE that file exists, otherwise to a per-item ledger `annotations/<id>.md` created on
  first use. (`<TITLE>` is the item title uppercased with each run of non-alphanumerics collapsed to a
  single `_` and surrounding `_` trimmed, suffixed `_PLAN.md`.)
- **EARS-FLOW-061** — The annotation block SHALL be the deterministic form
  `"\n<!-- annotation: <id> -->\n### Annotation on \`<id>\`\n\n<comment-trimmed-of-trailing-ws>\n"`.
- **EARS-FLOW-062** — WHEN an annotation is recorded, THE SYSTEM SHALL append an `annotated` event to
  the event log.
- **EARS-FLOW-063** — IF `annotate` names an unknown id, THEN THE SYSTEM SHALL respond with
  `error.code = -32000` and `error.data.error = "unknown"`.
- **EARS-FLOW-064** — WHEN `request_rewrite` is called with a known id and `comment`, THE SYSTEM SHALL
  increment that item's draft counter, append a `rewrite_requested` event carrying the comment and new
  draft number, and respond `{"draft": <new draft number>}`.
- **EARS-FLOW-065** — `request_rewrite` SHALL be allowed even WHILE the item is in WAIT, because
  requesting a re-draft is exactly the human-in-the-loop action a paused item is paused for.
- **EARS-FLOW-066** — IF `request_rewrite` names an unknown id, THEN THE SYSTEM SHALL respond with
  `error.code = -32000` and `error.data.error = "unknown"`.
- **EARS-FLOW-067** — The actual re-draft SHALL be external orchestration; `request_rewrite` SHALL
  only record the request.

## 10. Event feed — `append_sysmsg`, `list_events`

- **EARS-FLOW-068** — WHEN `append_sysmsg` is called with `text`, THE SYSTEM SHALL append a `sys_msg`
  event and respond `{"ok": true}`.
- **EARS-FLOW-069** — IF `append_sysmsg` is called without a string `text`, THEN THE SYSTEM SHALL
  respond with `error.code = -32602` (invalid params).
- **EARS-FLOW-070** — WHEN `list_events` is called with no filter, THE SYSTEM SHALL return
  `{"events": […]}` containing every event in append (oldest-first) order, each in its `kind`-tagged
  shape.
- **EARS-FLOW-071** — WHERE a string `kind` argument is supplied to `list_events`, THE SYSTEM SHALL
  return only events whose `kind` tag equals it.
- **EARS-FLOW-072** — IF the `kind` argument to `list_events` is present but not a string, THEN THE
  SYSTEM SHALL ignore it and return the full log (rather than erroring).

## 11. Local-compute render — `render_roadmap`

- **EARS-FLOW-073** — WHEN `render_roadmap` is called, THE SYSTEM SHALL return `{"rendered": <text>}`
  containing a deterministic, byte-stable board: a `ROADMAP` header, an `N item(s)` count, and `DO` /
  `DOING` / `DONE` sections listing each item in display order as
  `  · <id> · <title> · <STATUS> · <GATE> · <tokens> tok · d<draft>`, with `  (none)` for an empty
  section.
- **EARS-FLOW-074** — IF the store contains zero items, THEN THE SYSTEM SHALL append a diagnostic line
  to the rendered output warning that the store is empty and pointing the caller at `ping`.
- **EARS-FLOW-075** — `render_roadmap` SHALL produce identical bytes for identical board state across
  repeated calls.

## 12. Health & staleness — `ping`

- **EARS-FLOW-076** — WHEN `ping` is called, THE SYSTEM SHALL return `message`, the server `version`,
  the ingested item count (`items`), and the roadmap `source` (the ingested tree path, or null when
  none).

## 13. Startup, configuration & ingest

- **EARS-FLOW-077** — On startup the server SHALL, in order: open (creating if absent) the data
  directory and load the event log into memory, **ingest** the roadmap source to establish items, then
  **replay** the event log to layer runtime state on top (ingest → replay).
- **EARS-FLOW-078** — Replay SHALL run strictly **after** ingest, so the runtime fields the log carries
  (gate, tokens, model, draft) are layered onto the freshly-ingested items and are not reset; gates are
  restored by replaying `gate_set` events (the log is authoritative), not by reading the sidecar.
- **EARS-FLOW-079** — The server SHALL resolve the data directory from `--data` (default `.flow`) and
  the roadmap source from `--roadmap`, and SHALL accept `--mcp` as a no-op.
- **EARS-FLOW-080** — IF a known flag is supplied without its value, THEN THE SYSTEM SHALL exit with a
  configuration error naming the flag.
- **EARS-FLOW-081** — IF an unrecognised flag is supplied, THEN THE SYSTEM SHALL exit with an
  unknown-flag error rather than silently ignoring it.
- **EARS-FLOW-082** — WHERE no `--roadmap` is given, THE SYSTEM SHALL ingest the `.i2p/roadmap/` tree
  in the current working directory if it exists.
- **EARS-FLOW-083** — WHEN ingesting a directory source, THE SYSTEM SHALL treat it as the
  file-per-item tree where the folder is the status (`backlog`/`do`→Do, `doing`→Doing, `done`→Done)
  and each `.md` carries `id`/`title`/`status`/`depends_on` front-matter.
- **EARS-FLOW-084** — WHEN ingesting a file source, THE SYSTEM SHALL parse it as the legacy single
  `ROADMAP.md` (`## [N] TITLE` headings, `> STATUS:` lines, `> DEPENDS ON:` / `blocks on` dependency
  lines).
- **EARS-FLOW-085** — IF no roadmap source resolves, or the file source is unreadable, THEN THE
  SYSTEM SHALL start with an empty board and emit a diagnostic to stderr (never fatal).
- **EARS-FLOW-086** — WHILE ingesting, IF a declared dependency would form a cycle or names an unknown
  endpoint, THEN THE SYSTEM SHALL skip that edge and still load the item (the roadmap is authoritative;
  a malformed dependency must not abort ingest).
- **EARS-FLOW-087** — The roadmap parsers SHALL tolerate duplicate ids (last heading/file wins),
  self-edges (dropped), `—`/`-` dependency placeholders (no edge), and garbage lines (ignored).

## 14. Persistence & replay

- **EARS-FLOW-088** — Ownership: the `.i2p/roadmap/` tree OWNS item identity (existence, title, status,
  declared deps) and is re-ingested each boot; the append-only event log (`events.jsonl`, one
  `kind`-tagged JSON object per line) OWNS runtime state (gate, tokens, model, draft, runtime edge
  mutations, annotations). The markdown board, gate sidecar, and telemetry ledger SHALL be derived
  artifacts.
- **EARS-FLOW-089** — WHEN any **runtime mutation** commits, THE SYSTEM SHALL append its event to
  `events.jsonl` and re-render the markdown board (`ROADMAP.flow.md`) under a single serialized writer
  so the files never interleave or corrupt. **Ingest SHALL NOT journal events** (the tree is the
  durable record of identity), so the log does not grow across restarts.
- **EARS-FLOW-090** — Replay SHALL be non-clobbering and deterministic: an `item_upserted` SHALL create
  an item only if absent (never reset an existing item's runtime fields); a `spend_appended` SHALL
  re-apply the own-spend plus the roll-up onto its **stored ancestor set**; `status_posted` SHALL be a
  no-op WHERE a tree owns the status (and apply it only when there is no tree); `annotated` SHALL
  rebuild the annotation index; `sys_msg` SHALL be a no-op.
- **EARS-FLOW-091** — A blank line in `events.jsonl` SHALL be skipped on load; a line that is not a
  valid event — malformed JSON **or** a recognised-JSON object with an unknown event `kind` — SHALL
  abort the open with an error rather than silently dropping state.
- **EARS-FLOW-092** — The `gates.json` sidecar SHALL be a single JSON object mapping item id → `"wait"`
  / `"go"`, serialized in sorted-key order, written on every gate change as a human-readable external
  view.
- **EARS-FLOW-093** — The `gates.json` sidecar SHALL NOT be read on startup: gate state is restored by
  replaying `gate_set` events (the event log is authoritative). A missing, empty, or malformed sidecar
  SHALL therefore never affect startup.
- **EARS-FLOW-094** — Runtime state recorded via MCP verbs — token spend (with its ancestor roll-up),
  assigned model, draft count, and WAIT/GO gate — SHALL survive a restart that re-ingests the tree
  (replay layers it back onto the ingested items).
- **EARS-FLOW-095** — A store-level IO or serialization failure on a write path SHALL surface as
  `error.code = -32603` (internal error) and SHALL NOT be conflated with a domain refusal.

## 15. Observability & build identity

- **EARS-FLOW-096** — The server SHALL write structured diagnostics (warnings, ingest counts, startup
  state) to stderr, and SHALL emit a full backtrace to stderr on an unexpected internal error, so any
  fault is investigable from the live session (the visibility the retired compiled build lacked).
- **EARS-FLOW-097** — Telemetry SHALL be recorded to the append-only ledger `telemetry.jsonl` (one
  record per spend), which is the single telemetry sink. The server SHALL NOT push to any external
  endpoint, and a spend SHALL NEVER fail on account of telemetry. (The retired Rust reference carried a
  Grafana/Loki push shim that built a payload but never transmitted; it is removed — the ledger is the
  sink.)
- **EARS-FLOW-098** — The server's reported `version` SHALL identify the running build distinctly
  enough that `ping` can prove which build is live.

## 16. Runtime & fallback (port-specific)

- **EARS-FLOW-099** — The server SHALL run on Ruby ≥ 3.3.8 using only the Ruby standard library at
  runtime (no third-party gem required to serve).
- **EARS-FLOW-100** — IF no Ruby ≥ 3.3.8 is available on the host, THEN the launcher SHALL exit
  non-zero with an actionable message and SHALL point the operator at the markdown fallback runbook,
  rather than silently doing nothing.
- **EARS-FLOW-101** — The markdown fallback runbook SHALL define, for each verb, a by-hand procedure
  over the same on-disk files (`events.jsonl`, `gates.json`, `ROADMAP.flow.md`, the roadmap tree) that
  yields the same resulting state this specification requires of the server.

## 17. Restart integrity (no-growth · deterministic roll-up)

- **EARS-FLOW-102** — Re-ingesting the same roadmap tree across restarts SHALL NOT grow the event log:
  ingest is idempotent and unjournaled, so `events.jsonl` carries only runtime-mutation events and
  `list_events` SHALL NOT accumulate duplicate `item_upserted`/`connection_added` entries per boot.
- **EARS-FLOW-103** — A `spend_appended` event SHALL carry the transitive ancestor set used for its
  roll-up, and replay SHALL apply that stored set (not a recomputation from the current graph), so a
  restart reproduces the same rolled-up tallies even after intervening edge changes.

## 18. Item lifecycle — `create_item`, `delete_item`

- **EARS-FLOW-104** — WHEN `create_item` is called with a `title` (and optional `status` in
  `{do,doing,done}`, default `do`, and optional `depends_on` list), THE SYSTEM SHALL assign the next
  free `item-N` id (max existing numeric id + 1), add the item with that status and dependencies, and
  respond `{"id": "<new id>"}`. WHERE a tree owns identity, it SHALL write the new item back to the
  tree (`<status-folder>/<N>.md` with `id`/`title`/`status`/`depends_on` front-matter). `create_item`
  is WAIT-independent.
- **EARS-FLOW-105** — WHEN `delete_item` is called with a known id, THE SYSTEM SHALL remove the item
  and every edge incident on it, and respond `{"ok": true}`; WHERE a tree owns identity, it SHALL
  delete the item's tree file and prune the id from other items' `depends_on`. IF the id is unknown,
  THEN THE SYSTEM SHALL respond with `error.code = -32000` and `error.data.error = "unknown"`.
  `delete_item` is WAIT-independent.
- **EARS-FLOW-106** — A `create_item` / `delete_item` SHALL survive a restart: in tree mode via the
  written/removed tree file (re-ingest), and in every mode via the `item_created` / `item_deleted`
  events (replay) — without growing the log on subsequent restarts.
- **EARS-FLOW-107** — IF `create_item` names a `depends_on` entry that is not a known item, THEN THE
  SYSTEM SHALL refuse with `error.code = -32000` and `error.data.error = "unknown"`, creating nothing;
  a malformed dependency id SHALL be `error.code = -32602` (invalid params).
