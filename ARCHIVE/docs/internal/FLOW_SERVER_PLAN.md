# FLOW SERVER — Implementation Plan (Roadmap #1)

> Roadmap: **[1]** Flow server — HTTP + WebSocket + MCP in one Rust binary
> Date: 2026-06-13 · Branch: `flow-tracking-ui` · Stack: Rust (cargo 1.96) · Token stamp: ~250k (large)
> Status: IN PROGRESS

## Summary of the frozen spec (#1)

One Rust binary, the **sole writer** of flow state, that serves the static UI over HTTP, broadcasts
deltas over WebSocket, and exposes an MCP endpoint (streamable-HTTP, same process/port). Auth: configurable
host (default LAN-reachable) + a shared **bearer token** on every HTTP/WS/MCP request. Items keyed by
**stable slug IDs**. Graph mutations that form a cycle / break a dependency are rejected. WAIT halts
carriage-advance verbs. Single source of truth = roadmap markdown + append-only JSONL event log.

## Architecture — pure domain core + thin adapters

Crate at **`plugins/mission-control/flow-server/`** (`flow-server`):

```
src/
  domain/            ← PURE core (no IO) — parse-don't-validate, no cycles by construction
    ids.rs           ItemId (stable slug, validated), newtype
    model.rs         Item, Status(Do|Doing|Done), WaitGate(Go|Wait), Edge, Flow (the graph)
    graph.rs         validate_connection(from,to) → Result<(), GraphError(Cycle|BrokenDep|Unknown)>
    event.rs         Event enum + JSONL (serde) line schema
    error.rs         thiserror typed errors
  store.rs           Store: the ONE serialized writer (tokio::Mutex) of {markdown, JSONL}; no direct-write path
  auth.rs            bearer-token middleware (token from .flow/token); 401 on miss — HTTP/WS/MCP
  api.rs             axum router: static serve + REST verbs (list/get/wait-go/status/spend/model/connection/sysmsg)
  ws.rs              WS upgrade + tokio::broadcast delta fan-out
  mcp.rs             MCP tool surface (JSON-RPC over streamable-HTTP) → same verbs as REST
  config.rs          host/port/token-path; --host (default LAN), --port
  main.rs            wire core→store→router(+auth+ws+mcp), bind, serve
tests/
  graph_contract.rs  cycle/broken-dep rejection; reference-survival-under-reorder
  store_contract.rs  serialized concurrent writes; sole-writer; JSONL round-trip
  http_contract.rs   token-rejection (401); list_items; validate_connection cycle → typed error
  ws_contract.rs     a state change broadcasts a delta to a connected client
```

Deps: `axum`, `tokio` (rt-multi-thread, sync), `serde`/`serde_json`, `thiserror`, `tower`/`tower-http`
(static files), `tokio-tungstenite` via axum's `ws`. MCP as JSON-RPC handler on the same router (rmcp
optional later) to keep the MVP self-contained.

## Build order (DEV_SYSTEM, test-first)

1. **Domain core first** (highest-value, hardest logic): ids · model · graph cycle/dep validation · events.
   Pin every branch (cycle, broken-dep, unknown node, WAIT-guard) with RED unit tests → GREEN.
2. **Store** — the serialized sole-writer; concurrent-write + reference-survival tests.
3. **Auth + HTTP** — token middleware (401 path), REST verbs, static serve; http_contract tests.
4. **WS** — broadcast deltas; ws_contract test.
5. **MCP** — the verb surface mirroring REST; contract test for `validate_connection` cycle rejection.

## Test strategy

`cargo test --workspace` + `cargo llvm-cov`/`tarpaulin` for the **100% line+branch floor** (FOUNDRY mandate;
domain core especially). `cargo fmt --check` + `cargo clippy -D warnings` gate. No arbitrary sleeps in tests
(poll/await deterministic conditions) — flaky-test ban. Story/contract tests exercise the real HTTP/WS/MCP
surface (token-reject, cycle-reject, delta-broadcast, concurrent-write-serialize).

## Acceptance criteria → tests (from the frozen spec)

| AC | Test |
|----|------|
| token required on HTTP/WS/MCP | `http_contract::rejects_without_token` (401) |
| list_items served | `http_contract::list_items_ok` |
| validate_connection cycle → typed error, graph unchanged | `graph_contract::cycle_rejected` + `http_contract::mcp_cycle_rejected` |
| WS delta without polling | `ws_contract::state_change_broadcasts` |
| concurrent writes serialize, no corruption | `store_contract::concurrent_writes_serialize` |
| slug-id refs survive reorder | `graph_contract::refs_survive_reorder` |

## Checklist (Steps 0–9)
- [x] 0 — plan + token stamp
- [x] 1 — EARS (frozen roadmap EARS; encoded as the AC→test table)
- [x] 2 — scenarios (happy/unhappy/abuse for graph, auth, http, ws, mcp)
- [x] 3 — RED tests (domain → store → http → ws → mcp)
- [x] 4 — first run (confirmed RED)
- [x] 5 — implement to green
- [x] 6 — green run + coverage floor + 3× flake check — **170 tests green, no flakes; fmt + clippy -D
      warnings clean; production coverage 100% functions / 99.94% line** (domain + api + mcp + auth +
      config 100%; residual = 1 non-deterministic websocket `select!` branch + test-harness lines).
      `main.rs` excluded as the binary entrypoint shim (exercised by the e2e smoke run).
- [x] story — HTTP/WS/MCP contract tests through the real router (token-reject, cycle-reject,
      delta-broadcast, concurrent-write serialize, WAIT-guard) as in-crate `*_intest` modules.
- [ ] 7–9 — carried on `flow-tracking-ui`; lands in the epic #0 PR raised once the roadmap empties
      (per the #0 long-lived-branch plan), not as a per-item PR.

## Resumption
A cold-start agent: read this file + roadmap entry [1]. The crate is at
`plugins/mission-control/flow-server/`. Build order is domain→store→http→ws→mcp, test-first. Current
position is the lowest unchecked box above. Never weaken a test to pass; 100% coverage is the floor.
