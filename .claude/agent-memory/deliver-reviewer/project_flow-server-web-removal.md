---
name: flow-server-web-removal
description: PR #39 removed flow-server's HTTP/WS/SVG-board surface → stdio-MCP-only; security/regression facts — net-positive removal, residual dead auth+token-path wiring, board docs owned by separate #102
metadata:
  type: project
---

Roadmap **[39]** (branch `chore/flow-server-remove-web-ui`, PR #103) turned flow-server into a
**stdio-MCP-only** service: deleted `static/`, `ws.rs`, `http_*_intest.rs`, `build_router`, all REST
handlers, `ServeDir`, the `/mcp` HTTP handler, the token middleware, the `--host/--port/--static`
flags, and Cargo deps axum/tower-http/tokio-tungstenite/futures-util/tower/http-body-util.

**Security verdict facts (net-positive removal — don't re-litigate as a loss):**
- NO network listener survives in production `src/` (TcpListener/axum::serve/ServeDir/bind all gone;
  only doc-comment mentions remain). The old board bound `0.0.0.0` guarded by a bearer token — its
  removal is a security *improvement*, not a lost property.
- `--host/--port/--static` are now hard-rejected as `UnknownFlag` (live test
  `config.rs::removed_web_flags_are_unknown`) — a stale `--port` errors, never silently runs default.
- SHA256SUMS bootstrap-window (RELEASE bumped to v0.2.2, no checksum lines committed): the launcher
  `bin/flow-server-mcp` is **unchanged by #39** and **fails closed** — `pinned_sum_for` returns empty
  → `retrieve()` refuses to download (`[ -n "$expected" ] || return 1`), only `build_from_source`
  (cargo) can exec. No unverified-download path. Consequence is availability (cargo-less destinations
  can't launch until v0.2.2 assets ship post-merge), not integrity. Intended + documented.

**Residual half-wired auth (MEDIUM, the one thing to flag on #39):** `auth.rs` keeps the `Token` type
but `main.rs` now sets `Token::new("stdio-noop")` and NEVER calls `Token::load_or_create`. So
`load_or_create`/`generate_token`/`matches`/`from_bearer_header` are referenced ONLY from
`#[cfg(test)]` (survive `dead_code` solely via `pub`-API exemption — that's why clippy `-D warnings`
passes). `Config.token_path` + `--token` parsing are likewise parsed/stored but never read. The
`auth.rs` module doc-comment FALSELY claims "main still loads/creates the token file" — it doesn't.
Behaviour is safe (no transport reads the token); the defect is a security-module doc that lies about
the auth posture + fully-dead `--token`/`token_path` wiring.

**Scope discipline — board docs belong to the SEPARATE open PR #102** (`chore/repurpose-flow-command`,
item [41]): `commands/flow.md`, `skills/flow/SKILL.md`, `mission-control/README.md` still describe the
SVG board / `0.0.0.0` / statusline URL and reference the 3 DELETED hooks
(flow-advertise/flow-roadmap-watch/flow-statusline-widget). #39 does NOT touch these — do not charge
#39 for them. On `main`, `flow.md` is already partly repurposed (MCP language) but `SKILL.md` is not.
`deliver/agents/ds-step-9-commit-push.md` still has a `curl POST /api/items/{N}/status` *fallback*
(deliver-owned, not #102) — but it PREFERS MCP `post_status` and the curl path degrades gracefully
(connection-refused → log + continue), so it's stale-but-harmless LOW, not a broken-delivery regression.

All MCP verbs the live surfaces promise exist on the branch: render_roadmap, list_items, post_status,
ping, set_wait_go, append_spend, annotate, list_events. Related: [[flow-server-stdio-transport]]
(unbounded read_line OOM still the live stdio risk), [[flow-server-pin-parse]] (launcher fails closed),
[[provenance-archive]] (.i2p/roadmap/done/*, .deliver/[37]*, docs/internal/*_PLAN.md keep HTTP/WS refs
by design — not dangling).
