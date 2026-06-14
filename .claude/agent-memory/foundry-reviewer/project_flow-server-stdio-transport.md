---
name: flow-server-stdio-transport
description: flow-server --mcp stdio transport security shape — where the live risk is and which vectors are already mitigated
metadata:
  type: project
---

flow-server's `--mcp` flag runs a newline-delimited stdio JSON-RPC loop (`run_stdio` in
`src/main.rs`) that delegates to the transport-agnostic `mcp::dispatch` (shared with the
HTTP `/mcp` handler). Reviewed on branch feature/items-37-38-mcp-stdio (items 37/38).

**Why:** the stdio transport is a pipe — any local process that can write to the child's
stdin drives it, so it must be defended like an untrusted boundary even though the
registered peer is trusted Claude Code.

**How to apply — what's the LIVE risk vs already-mitigated (don't re-flag the mitigated):**
- LIVE: `BufReader::read_line` in `run_stdio` has NO max-line cap → unbounded String
  growth / OOM (CWE-400/770). The HTTP sibling has axum's default body limit; stdio does
  not, so it's a regression relative to the surface it mirrors. Fix = cap the per-line read.
- MITIGATED (do not re-report): IO-error disclosure (`store_error` in mcp.rs maps Io/Serialize
  to generic "internal store error", drops the OS string); auth bypass via
  `Token::new("stdio-noop")` (`state.token` is never read in the dispatch path — only
  api.rs build_router uses it); path traversal via id/title (`ItemId::new` is `[a-z0-9-]`≤64,
  `plan_doc_filename` collapses non-alnum to `_`); command injection (no MCP arg reaches
  process::Command — that's history.rs/git only); serde_json id-nesting (default depth 128).
- KAIZEN: unbounded-read-on-a-transport-boundary is a recurring DoS class — pair it with
  [[project-marketplace-supply-chain]] (auto-executed `cargo run` via `.claude/settings.json`
  on repo open is the same auto-exec-on-open property, repo-local but worth a trust-model note).
