---
name: axum-extractor-coupling
description: mcp::handle uses axum extractors (State, Json) making it uncallable outside the axum chain — always author a dispatch(state: &AppState, req: Value) -> Value core with a thin transport wrapper
metadata:
  type: feedback
---

When a function uses `State<AppState>` and `Json<Value>` as axum extractor parameters, it can only be called through the axum dispatcher — not directly from a test or alternate transport (stdio, gRPC, batch).

**Why:** Discovered when planning [37] stdio MCP transport. The existing `mcp::handle` is locked to axum's dispatch chain. Adding a second transport (stdio) required extracting the logic into a `dispatch(state: &AppState, req: Value) -> Value` function with `handle` as a thin wrapper.

**How to apply:** When authoring any new MCP or HTTP handler that might need a second transport or direct-call testability, start with the dispatch-fn pattern rather than the extractor pattern. The extractor wrapper is one line; the dispatch fn is where all logic lives. See T37-1 in [[items-37-38-plan]].
