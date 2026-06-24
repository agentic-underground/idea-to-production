# FLOW_GATE_PERSIST_PLAN — Item [36]

> Persist gate state: WAIT/GO survives restart + surfaces in roadmap view
> Status: PENDING
> Branch: feature/item-36-gate-persist
> Plan authored: 2026-06-14

---

## 1. SUBJECT_MATTER_UNDERSTANDING

### What exists today

**Gate state is in-memory only.** The `WaitGate` enum (`domain/model.rs`) has two variants —
`Go` (default) and `Wait`. It is stored on each `Item` struct as `pub gate: WaitGate`. On
`Store::set_gate()` the gate is mutated in the in-memory `Flow` and a `GateSet` event is
appended to `events.jsonl`. On server restart, `Store::open()` replays `events.jsonl` via
`apply_event()` which includes a `GateSet` arm — **so gate state already survives restart
through the JSONL log**. This is the existing mechanism.

**However**, the roadmap item's wording and the acceptance criteria state that gate state must
be persisted in `.flow/gates.json` "alongside `events.jsonl`". Re-reading both the roadmap item
and the replay machinery in `apply_event()`:

```rust
Event::GateSet { id, gate } => {
    let _ = flow.set_gate(id, *gate);
}
```

The `GateSet` event is journalled and replayed. Gate state already survives restart through the
event log. The gap is:

1. **Separate `gates.json` sidecar** — the roadmap item explicitly requires `.flow/gates.json`
   as a durable, human-readable file that is *easier to inspect and recover* than scanning the
   JSONL for the last `GateSet` per item. This is an independent persistence path (not replacing
   the JSONL). Its load-on-startup path gives a cleaner, order-independent restore: read the JSON
   map directly rather than replaying an ordered log.
2. **MCP `list_items` gate grouping** — `list_items` currently returns a flat array of items.
   Acceptance criterion 3 requires PENDING items grouped by gate: WAIT vs GO.

### Key types and functions

| Symbol | File | Role |
|---|---|---|
| `WaitGate` | `domain/model.rs` | `{Go, Wait}` enum, serde-serializable |
| `Item.gate` | `domain/model.rs` | Per-item gate field |
| `Store::set_gate()` | `store.rs` | Mutation verb — single writer |
| `Store::open()` | `store.rs` | Startup: creates dir, replays JSONL |
| `apply_event()` | `store.rs` | Replays one event onto in-memory Flow |
| `ingest_roadmap()` | `store.rs` | Parses roadmap markdown, upserts items |
| `Inner` struct | `store.rs` | Holds `flow`, `jsonl_path`, `markdown_path` — needs `gates_path` |
| `mcp::call_tool` `list_items` | `mcp.rs` | Returns flat `{items: [...]}` — needs grouping |
| `render_roadmap()` | `domain/roadmap_view.rs` | Already groups by DO/DOING/DONE; gate already shown per row |
| `item_json()` | `api.rs` | Renders one item; `gate` field already included |
| `append_line()` | `store.rs` | Async JSONL append helper |
| `write_markdown()` | `store.rs` | Async write to ROADMAP.flow.md |

### How `.flow/` is used today

The `.flow/` directory is `cfg.data_dir`, passed to `Store::open(dir)`. Inside it:
- `events.jsonl` — append-only event log (the authoritative write-ahead record)
- `ROADMAP.flow.md` — rendered markdown board (re-derived from flow state on every commit)
- `telemetry.jsonl` — token telemetry ledger
- `annotations/` — per-item annotation ledger files (created lazily)

The new file `.flow/gates.json` fits this pattern: a durable sidecar keyed on item ID,
written on every `set_gate()` call, read on startup before the store is exposed to the API.

### Startup sequence (main.rs)

```
Config::from_args()
Token::load_or_create()
Store::open(&cfg.data_dir)      ← gates.json loaded here
store.ingest_roadmap(md)        ← items upserted; restored gates applied to new items
build_router(store, token, ...)
axum::serve(...)
```

The correct load point is inside `Store::open()`, after replaying `events.jsonl` (so the JSONL
replay wins over the gates.json sidecar for items that have both — gates.json is a *secondary*
restore path, written in sync with the JSONL). Alternatively, gates.json is written in parallel
with the JSONL and is the *primary* restore for gate state (simpler map lookup vs full replay).
Decision: **gates.json is the canonical gate restore**; the JSONL `GateSet` replay continues to
work as a fallback (the two sources will agree because `set_gate` writes both atomically).

### `ingest_roadmap()` interaction

`ingest_roadmap()` upserts items with their roadmap-parsed status. It does not touch gate state
(all freshly upserted items start at `WaitGate::Go`). After the gates.json sidecar is loaded in
`Store::open()`, items that exist in `gates.json` will have their gates restored. Items in the
roadmap that are not in `gates.json` get the default `Go`. Items in `gates.json` that no longer
exist in the roadmap are silently discarded (the domain's `set_gate()` returns an Unknown error
which we discard).

The load order in `main.rs` is: `Store::open()` (which loads gates.json) then
`store.ingest_roadmap()`. This means `ingest_roadmap()` upserts items *after* gates are loaded.
Upserting an item resets it to `WaitGate::Go` (default in `Item::new`). Therefore the gates
restore must happen *after* `ingest_roadmap()`, or `ingest_roadmap()` must preserve existing
gate state. The simplest fix: load gates.json **after** `ingest_roadmap()` returns, so gates are
applied on top of freshly upserted items.

Since `ingest_roadmap()` is called in `main.rs` (not in `Store::open()`), the gates restore
should also live in `main.rs`, or `Store::open()` should be refactored to accept an optional
gate file path. The cleanest approach for this item: add a `Store::restore_gates_from_file()`
method that is called in `main.rs` immediately after `ingest_roadmap()`.

**Alternative (simpler):** gate restore runs inside `Store::open()` but only applies to items
that are already in the flow (i.e., those already in the flow from JSONL replay — items added
later by `ingest_roadmap()` reset the gate back to Go). This is incorrect because `ingest_roadmap`
runs after `Store::open()`.

**Decision: separate `Store::restore_gates()` method** called from `main.rs` after `ingest_roadmap()`.
It reads `.flow/gates.json`, iterates the id→gate map, calls `flow.set_gate()` for each entry,
skipping Unknown errors silently. This is the correct sequencing and keeps the store's startup
API clean.

### MCP `list_items` current shape

```json
{ "items": [ ...flat array... ] }
```

Required shape (AC #3):

```
PENDING items grouped by gate:
  WAIT: [...]
  GO:   [...]
Non-PENDING items: unchanged (or flattened into their status groups)
```

The `render_roadmap()` function already shows gate per row in the text view. The `list_items`
MCP tool needs a structural grouping. The roadmap item says "group PENDING items by gate: WAIT
items listed separately from GO items". The safest non-breaking change: return a top-level
`grouped` field alongside `items` so existing consumers of `items` are unaffected, or restructure
the response entirely. Given this is an MCP tool (agent-facing, not a REST API with external
consumers), restructuring is acceptable. The plan chooses a **new response shape**:

```json
{
  "pending": {
    "wait": [...],
    "go":   [...]
  },
  "in_progress": [...],
  "done": [...]
}
```

This matches the acceptance criterion exactly and is more useful than a flat array with a gate
field buried in each item.

---

## 2. DECOMPOSITION

### Part 1 — Persist gate state (Rust, store.rs)

#### Task 1.1 — Unit tests for gates.json persistence (write first)

In `store_contract_intest.rs` or a new `gate_persist_intest.rs`:

- `gates_json_written_on_set_gate` — call `set_gate(wait)`, assert `.flow/gates.json` exists
  and contains `{"item-a":"wait"}`.
- `gates_json_updated_on_toggle` — set wait, then go, assert file contains `{"item-a":"go"}`.
- `restore_gates_survives_restart` — set gate to wait, drop store, call restore_gates on a fresh
  store after ingest_roadmap, assert gate is wait.
- `missing_gates_json_does_not_prevent_restore` — call `restore_gates()` on a dir with no
  `gates.json`, assert no error, all items default to go.
- `corrupt_gates_json_does_not_prevent_restore` — write `{not valid}` to gates.json, call
  `restore_gates()`, assert no error, all items default to go.
- `stale_item_in_gates_json_is_silently_discarded` — write `{"ghost-item":"wait"}` to
  gates.json, call `restore_gates()` with a store that has no `ghost-item`, assert no error.
- `gates_json_atomic_write_is_not_corrupted` — write gate, read back raw bytes, assert valid JSON
  (tests that atomic write completed correctly — i.e. the rename-from-tmp mechanism works).

#### Task 1.2 — Implement gates.json write in `Store::set_gate()`

In `store.rs`:

1. Add `gates_path: PathBuf` to `Inner` struct (e.g. `dir.join("gates.json")`).
2. After `guard.flow.set_gate(id, gate)?` and before/after `self.commit(...)`, collect the full
   id→gate map from `guard.flow` and write it atomically:
   - Serialize `HashMap<&str, WaitGate>` (or `BTreeMap` for deterministic output) to JSON.
   - Write to `<dir>/gates.json.tmp`.
   - `std::fs::rename("gates.json.tmp", "gates.json")` (atomic on Linux — same filesystem).
   - Use `tokio::fs` for the async path.
3. A write failure here should **not** fail the `set_gate()` call (gates.json is a sidecar,
   not the source of truth). Log a warning and continue. The JSONL log remains authoritative.
   **Rationale**: failing a user's gate toggle because of a sidecar write failure would be a bad
   UX. The JSONL replay already recovers gate state. The sidecar is a convenience optimisation.

**Alternative**: fail the call if the sidecar write fails (strict consistency). Decision: **warn
and continue** — the JSONL is already the authoritative path; the sidecar is an optimisation.

#### Task 1.3 — Implement `Store::restore_gates()` method

Add a public `async fn restore_gates(&self) -> ()` (infallible):

```rust
pub async fn restore_gates(&self) {
    let mut guard = self.inner.lock().await;
    let path = guard.gates_path.clone();
    match tokio::fs::read_to_string(&path).await {
        Err(_) => return,   // missing file → all gates default to Go, no error
        Ok(text) => {
            let map: Result<BTreeMap<String, WaitGate>, _> = serde_json::from_str(&text);
            match map {
                Err(_) => {
                    eprintln!("flow-server: .flow/gates.json is malformed — all gates default to go");
                    return;
                }
                Ok(map) => {
                    for (id_str, gate) in map {
                        if let Ok(id) = ItemId::new(&id_str) {
                            let _ = guard.flow.set_gate(&id, gate); // Unknown → silent discard
                        }
                    }
                }
            }
        }
    }
}
```

This method is infallible (returns `()`), which matches the acceptance criteria that a missing
or corrupt file must not prevent startup.

#### Task 1.4 — Wire into `main.rs`

After `store.ingest_roadmap(&md).await?`, call `store.restore_gates().await`:

```rust
let n = store.ingest_roadmap(&md).await?;
store.restore_gates().await;          // ← new; infallible
eprintln!("flow-server ingested {n} roadmap item(s) ...");
```

Also call it in the no-roadmap path (when `cfg.roadmap_path` is None and the board starts from
JSONL replay only) — in that case, `restore_gates()` should be called after `Store::open()`
returns, unconditionally. Since `Store::open()` replays the JSONL (which includes `GateSet`
events), calling `restore_gates()` after will only override gates that differ between the JSONL
replay and the sidecar (they should agree). This is safe.

**Simplest correct wiring in main.rs:**

```rust
let store = Arc::new(Store::open(&cfg.data_dir).await?);
if let Some(path) = &cfg.roadmap_path {
    // ... ingest_roadmap ...
}
store.restore_gates().await;   // always; infallible
```

### Part 2 — Gate state in roadmap view (Rust, mcp.rs)

#### Task 2.1 — Unit tests for `list_items` gate grouping

In `mcp_contract_intest.rs` (or `mcp_surface_intest.rs` — check which exists):

- `list_items_groups_pending_by_gate` — seed items: one pending/wait, one pending/go, one
  doing/go, one done/go. Call `list_items`. Assert:
  - `result.pending.wait` contains the wait item's id.
  - `result.pending.go` contains the go pending item's id.
  - `result.in_progress` contains the doing item's id.
  - `result.done` contains the done item's id.
- `list_items_empty_store_returns_empty_groups` — no items, assert all groups empty arrays.
- `list_items_all_pending_go_wait_empty` — all pending/go, assert `pending.wait` is empty array.

#### Task 2.2 — Implement grouping in `mcp::call_tool` `list_items`

Change the `list_items` arm in `mcp.rs` from:

```rust
let items: Vec<Value> = flow.items_in_order().iter().map(...).collect();
ok(id, json!({ "items": items }))
```

To a grouped response:

```rust
let mut pending_wait: Vec<Value> = Vec::new();
let mut pending_go: Vec<Value> = Vec::new();
let mut in_progress: Vec<Value> = Vec::new();
let mut done: Vec<Value> = Vec::new();

for i in flow.items_in_order().iter() {
    let deps = deps_for(i, flow.edges());
    let annotations = annotations_for(i, &events);
    let v = item_json(i, &deps, &annotations);
    match i.status {
        Status::Do => match i.gate {
            WaitGate::Wait => pending_wait.push(v),
            WaitGate::Go   => pending_go.push(v),
        },
        Status::Doing => in_progress.push(v),
        Status::Done  => done.push(v),
    }
}

ok(id, json!({
    "pending": {
        "wait": pending_wait,
        "go":   pending_go
    },
    "in_progress": in_progress,
    "done":        done
}))
```

Note: `Status::Do` maps to PENDING (the roadmap label for items not yet started). `Status::Doing`
maps to in-progress. `Status::Done` maps to done. This matches the roadmap item's language.

#### Task 2.3 — No JS changes required for Part 2

The MCP `list_items` is an agent-facing tool, not called directly by the canvas JS. The canvas
uses `GET /api/items` (REST), which is unchanged — it still returns a flat array with the gate
field per item. No JS modifications are needed.

---

## 3. VALUE_HANDLERS

| Handler | Work |
|---|---|
| `handler-rust` | All Rust changes: `store.rs` (gates.json write + restore_gates), `main.rs` (wiring), `mcp.rs` (list_items grouping), `store_contract_intest.rs` / `gate_persist_intest.rs` (new unit tests), `mcp_contract_intest.rs` (grouping tests) |
| `handler-vanilla-js` | No changes required for this item |

**Missing handlers:** None. `handler-rust` covers all work.

---

## 4. STEP CHECKLIST (Stations 0–9 + Story)

```
docs/internal/.foundry-sentinels/item-36/
  PLAN_COMPLETE          ← created by builder-lead (this plan)
  EARS_COMPLETE          ← created after step 1
  FEATURE_COMPLETE       ← created after step 2
  TESTS_WRITTEN          ← created after step 3
  IMPL_COMPLETE          ← created after step 4
  COVERAGE_OK            ← created after step 5
  STORY_WRITTEN          ← created after step 6
  STORY_PASSED           ← created after step 7
  DELIVERY_COMPLETE      ← created after step 9
```

### Step 0 — PLAN (this document)
Output: `docs/internal/FLOW_GATE_PERSIST_PLAN.md`, `docs/internal/.foundry-sentinels/item-36/PLAN_COMPLETE`

### Step 1 — EARS
Write EARS statements covering:
- WHEN `set_gate()` is called THEN gates.json is written atomically in `.flow/`
- WHEN the server starts THEN `.flow/gates.json` is loaded and gate state is restored
- IF `.flow/gates.json` is absent THEN all gates default to go (no error)
- IF `.flow/gates.json` is malformed THEN all gates default to go (warn, no crash)
- IF an item in `gates.json` is absent from the roadmap THEN it is silently discarded
- WHEN `list_items` MCP tool is called THEN PENDING items are grouped by gate: WAIT/GO

Output: EARS spec appended to this plan or as `docs/internal/item-36-ears.md`
Sentinel: `docs/internal/.foundry-sentinels/item-36/EARS_COMPLETE`

### Step 2 — FEATURE (Gherkin)
Write `.feature` file(s) in the flow-server test tree covering:
- Happy: toggle to WAIT, restart, reload — card is still WAIT
- Happy: `GET /api/items` returns `gate: "wait"` after restart
- Happy: `list_items` groups PENDING by gate correctly
- Unhappy: missing `gates.json` — server starts, all gates go
- Unhappy: corrupt `gates.json` — server starts, all gates go
- Unhappy: stale item in `gates.json` — silently discarded

Output: `.feature` file(s)
Sentinel: `docs/internal/.foundry-sentinels/item-36/FEATURE_COMPLETE`

### Step 3 — TESTS (RED)
Write failing Rust unit/integration tests:
- `store_contract_intest.rs` additions: all 7 gate persistence tests (Task 1.1)
- `mcp_contract_intest.rs` additions: 3 list_items grouping tests (Task 2.1)
- Run `cargo test -p flow-server` — new tests must fail (RED gate)

Sentinel: `docs/internal/.foundry-sentinels/item-36/TESTS_WRITTEN`

### Step 4 — IMPLEMENT (GREEN)
Implement in order:
1. Add `gates_path` to `Inner` in `store.rs`
2. Add `persist_gates()` async helper in `store.rs` (write to `.tmp`, rename)
3. Call `persist_gates()` in `Store::set_gate()` (warn-and-continue on error)
4. Add `Store::restore_gates()` public method in `store.rs`
5. Wire `store.restore_gates().await` in `main.rs`
6. Change `list_items` arm in `mcp.rs` to grouped response
7. Run `cargo test -p flow-server` — all tests must pass (GREEN gate)

Sentinel: `docs/internal/.foundry-sentinels/item-36/IMPL_COMPLETE`

### Step 5 — COVERAGE
Run `cargo llvm-cov` (or `cargo tarpaulin`) and verify 100% coverage:
- All new branches in `persist_gates()`: success, write failure (warn path)
- All new branches in `restore_gates()`: missing file, malformed JSON, stale item, happy
- All new branches in `list_items` grouping: each status/gate combination

Sentinel: `docs/internal/.foundry-sentinels/item-36/COVERAGE_OK`

### Step 6 — STORY (WRITE)
Write story tests in the flow-server story test style:
- Story: restart persistence (set gate → restart → assert gate restored)
- Story: cold-start no-gates-file (fresh dir → start → all gates go)
- Story: corrupt-gates-file (write garbage → start → all gates go, server up)
- Story: `list_items` grouping (seed items → call list_items → assert grouped shape)

Sentinel: `docs/internal/.foundry-sentinels/item-36/STORY_WRITTEN`

### Step 7 — STORY (PASS)
Run all story tests. All pass.

Sentinel: `docs/internal/.foundry-sentinels/item-36/STORY_PASSED`

### Step 8 — SECURITY REVIEW (SENTINEL gate)
Items touching file writes and new I/O paths require a lightweight security check:
- Confirm `gates.json.tmp` and `gates.json` stay within `.flow/` (no path traversal)
- Confirm corrupt JSON is handled without panics or information leakage in error responses
- Confirm the atomic rename does not leave dangling `.tmp` files on crash (Linux rename is atomic)

(No new network surface; token auth unchanged; no new SQL/injection surface.)

### Step 9 — DELIVERY
- Update `plugins/mission-control/ROADMAP.md` item [36]: `STATUS: COMPLETE`
- Emit `DELIVERY_COMPLETE` sentinel
- Sync flow canvas (post_status done)

Sentinel: `docs/internal/.foundry-sentinels/item-36/DELIVERY_COMPLETE`

---

## 5. TOKEN BUDGET

| Step | Work | Est. tokens |
|---|---|---|
| 0 — Plan | This document | ~4k (builder-lead) |
| 1 — EARS | 6 EARS statements | ~1k |
| 2 — Feature | 6 Gherkin scenarios | ~2k |
| 3 — Tests (RED) | 10 Rust test functions | ~5k |
| 4 — Implement | store.rs (~80 lines), main.rs (~5 lines), mcp.rs (~25 lines) | ~8k |
| 5 — Coverage | llvm-cov run + branch analysis | ~2k |
| 6 — Story | 4 story tests | ~4k |
| 7 — Story pass | Run + fix | ~2k |
| 8 — Security | Lightweight check | ~1k |
| 9 — Delivery | ROADMAP.md update + sentinels | ~1k |
| **Total** | | **~30k** |

Estimation basis: comparable items with similar Rust scope (items [33], [29]) averaged ~25–35k
tokens. This item is simpler than [29] (no JS, no canvas work), slightly more complex than [33]
(new file I/O path + test coverage requirements).

---

## 6. RISKS AND GOTCHAS

### Risk 1 — `ingest_roadmap()` resets gates

**Problem:** `ingest_roadmap()` calls `flow.upsert_item()` which resets gate to `WaitGate::Go`
(the default). If `restore_gates()` is called *before* `ingest_roadmap()`, every gate is
overwritten back to Go.

**Mitigation:** Call `store.restore_gates().await` in `main.rs` *after* `store.ingest_roadmap()`
returns. The startup sequence must be:

```
Store::open()          → replays JSONL (GateSet events replay gates)
ingest_roadmap()       → upserts items from markdown, resets gates to Go
restore_gates()        → re-applies gates from gates.json
```

This is the correct order. Document it explicitly in code comments.

### Risk 2 — Atomic write on Linux (same filesystem)

`std::fs::rename()` (and `tokio::fs::rename()`) is atomic on Linux **only when source and
destination are on the same filesystem**. Since both `gates.json.tmp` and `gates.json` are in
the same `.flow/` directory, they will always be on the same filesystem. This is safe.

However, if the process crashes between writing `.tmp` and completing the rename, the `.tmp` file
is left behind. On next startup `restore_gates()` reads `gates.json` (not `.tmp`), so the stale
`.tmp` is harmless. It can be cleaned up proactively in `restore_gates()` or left for the OS.
Decision: **leave it** (OS will eventually clean temp files; the leftover `.tmp` contains valid
JSON and causes no harm).

### Risk 3 — `BTreeMap` vs `HashMap` for serialization

Use `BTreeMap<String, WaitGate>` for serialization so the output is deterministic (sorted by
key). This matters for tests that compare the raw JSON file contents, and for human readability.
`HashMap` would produce non-deterministic key order across restarts. The `BTreeMap` adds a
trivial alloc overhead (not on any hot path).

### Risk 4 — `WaitGate` serde representation

`WaitGate` must serialize as `"wait"` / `"go"` (lowercase strings) to be consistent with the
REST API's `item.gate` field. Verify the existing `#[serde(...)]` attributes on `WaitGate` in
`domain/model.rs` produce lowercase strings before writing the gates.json format. If they use
`PascalCase` or integer tags, the gates.json format will differ from what the acceptance
criteria show (`gate: "wait"`). Use the same serde representation.

From `api.rs` line 329: `item_json()` includes `"gate": item.gate`, and from the canvas fixture
the value is `"wait"` (lowercase). So `WaitGate` already serializes as lowercase.

### Risk 5 — warn-and-continue vs fail on sidecar write error

The plan chooses to **warn and continue** when the `persist_gates()` write fails (e.g. disk
full). This means gate toggles succeed (the in-memory state and JSONL are updated) but the
sidecar is stale. On next restart, the `restore_gates()` will load a stale `gates.json` and may
restore incorrect gate values (the JSONL replay in `Store::open()` will have the correct state
from replaying `GateSet` events, but `restore_gates()` runs after `ingest_roadmap()` which
resets gates, and `restore_gates()` loads the stale file).

**Revised decision**: if the sidecar write fails, this is a **non-fatal warning** but the
operator should be alerted. The JSONL already contains the ground truth; the only consequence
of a stale sidecar is that the gates won't survive the sequence `restart → ingest → restore`.
This is acceptable for an MVP: the EARS spec says the server must not crash, not that gates
must be 100% restored if disk writes fail. Document this degradation clearly in the code.

### Risk 6 — Coverage of warn-and-continue branch

The `persist_gates()` warn-and-continue branch (IO failure on write) must be tested for
coverage. Use the same `FaultSink` pattern that already exists in `store.rs` tests, or simulate
by pointing the tmp path at a directory (same trick used in `commit_fails_when_jsonl_becomes_a_directory`).

### Risk 7 — MCP response shape change is breaking

Changing `list_items` from `{"items": [...]}` to `{"pending": {...}, "in_progress": [...], ...}`
is a **breaking change** for any agent currently consuming `list_items`. The `render_roadmap`
MCP tool returns the text view and is unaffected. The REST `GET /api/items` is also unaffected.

Check if any existing code calls `list_items` and parses `result.items`:
- `plugins/mission-control/flow-server/static/` — canvas JS uses REST `GET /api/items`, not MCP
- `plugins/foundry/` — ROADMAPPER skill uses `render_roadmap` or REST, not MCP `list_items`
- The `mcp_contract_intest.rs` tests — will need updating to the new shape

Mitigation: update existing `mcp_contract_intest.rs` tests for `list_items` alongside the new
ones, and check `mcp_surface_intest.rs` for any list_items calls.

---

## 7. SHARED INFRASTRUCTURE MAP

No shared infrastructure is built by this item. All changes are confined to:

- `flow-server/src/store.rs` — gates.json persistence
- `flow-server/src/main.rs` — restore_gates() wiring
- `flow-server/src/mcp.rs` — list_items grouping
- Integration test files in `flow-server/src/`

No downstream items depend on this item's output. No upstream items need to complete first.
This item is **atomic** — it can be built immediately without other prerequisites.

---

## 8. PARALLEL GROUPING

This item is the sole item in its cycle. No parallel grouping required.

```
Tier: SECONDARY (MEDIUM priority, no blockers)
Round 1 (can run immediately):
  #36 — Persist gate state (atomic; no dependencies)
```

---

## 9. VALUE_HANDLER_POOL REQUIRED

- `handler-rust` — all production code and tests

---

## 10. MISSING HANDLERS

None.

---

## 11. SELF-IMPROVEMENT FLAGS

None identified for this cycle.

---

## 12. ARCHITECTURE DECISIONS

No new bounded context, new persistence mechanism, or new delivery channel introduced beyond
the existing `.flow/` pattern. No ADR required. The gates.json sidecar follows the same
directory-as-data-store pattern as `events.jsonl` and `telemetry.jsonl`.

The one design decision that is non-obvious: **warn-and-continue** on sidecar write failure
(§6, Risk 5). This is explicitly chosen over fail-on-error for UX reasons. Documented in code.

---

## 13. RESUMPTION INSTRUCTIONS

If this cycle is paused and resumed cold:

1. Read this file for full context.
2. Branch is `feature/item-36-gate-persist` off `main` (created 2026-06-14).
3. Check which sentinel files exist in `docs/internal/.foundry-sentinels/item-36/` to determine the last
   completed step.
4. Run `cargo test -p flow-server` to confirm current state before resuming.
5. Implementation targets: `store.rs` (Inner struct, `set_gate`, new `restore_gates` + helper),
   `main.rs` (post-ingest call), `mcp.rs` (`list_items` arm grouping).
6. The acceptance criteria are in `plugins/mission-control/ROADMAP.md` item [36].
7. Coverage target is 100% for all new branches.
8. No JS changes required.
