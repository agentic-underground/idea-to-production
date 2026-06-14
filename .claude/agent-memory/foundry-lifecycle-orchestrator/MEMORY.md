# Memory index

- [Item 28 RHS detail panel delivery](item-28-rhs-detail-panel.md) — coverage gap pattern: defensive `||` branches and null-fallback arms in detail.js needed explicit tests to reach 100%
- [Item 31 commit-graph view](item-31-commit-graph.md) — one-line delegation upgrade pattern; class name migration in existing tests when renderer is replaced; single-expand closure pattern
- [Item 36 gate persistence](item-36-gate-persist.md) — sequencing trap (restore_gates after ingest_roadmap), MCP shape-change breaks existing intest consumers, atomic write tmp pattern, warn-and-continue fault simulation
- [Item 37 MCP stdio transport](item-37-mcp-stdio.md) — axum extractor decoupling pattern; io-std feature required for stdin/stdout; CARGO_BIN_EXE only works in tests/ not src/; PathBuf has no .path()
