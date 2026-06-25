# BUILDER-LEAD Memory Index

- [Flow server domain gap: PR and commit data](project_flow-domain-gap.md) — Item struct has no PR/commit fields; cycles must work around with placeholders
- [canvas.js write-conflict pattern](feedback_canvas-write-conflict.md) — When two parallel items both touch canvas.js, assign it exclusively to one agent and defer the other's wiring to Round 2
- [axum extractor coupling pattern](feedback_axum-extractor-coupling.md) — mcp::handle uses axum extractors making it uncallable outside the chain; always author a dispatch() core with a thin transport wrapper
- [.claude/settings.json absent](project_settings-json-absent.md) — File does not exist as of 2026-06-14; item [38] creates it; always read-then-merge defensively
