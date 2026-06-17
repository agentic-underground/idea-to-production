# Flow server — the roadmap MCP core

The standing **roadmap-tracking surface** of the idea-to-production value system: one Rust binary that
ingests a project's `.i2p/roadmap/` tree and exposes it to an agent as a **token-authenticated MCP verb
surface over stdio**. It is the **sole serialized writer** of the roadmap markdown + JSONL event log, so
every read and mutation flows through one authoritative path.

> **Roadmap #39 — web UI removed.** The flow-server once *also* served an interactive SVG governance
> board over HTTP + a WebSocket delta stream + a REST surface. That web UI was removed in roadmap #39;
> the binary now runs the MCP stdio core only. The launcher passes `--mcp` (retained as a harmless
> no-op — stdio is the only transport), so nothing changes for the registered MCP server.

## What it does (roadmap items #1, #3–#6, #8, #15)

| Item | Capability |
|------|-----------|
| **#1** | One Rust binary: the MCP verb surface over stdio, **sole serialized writer** of the roadmap markdown + JSONL event log, stable slug IDs, cycle/broken-dep graph guard |
| **#3** | Carriage telemetry: ancestor **token roll-up** (a spend on a child accrues up the dependency tree) |
| **#4** | Comment / pause / annotate / rewrite: `annotate` pauses the item; a `request_rewrite` bumps the draft# |
| **#5** | Roadmap ingest (`--roadmap`) of the `.i2p/roadmap/` tree |
| **#6** | System-message feed via `append_sysmsg` / `list_events` |
| **#8** | Per-job model selection: `set_item_model` (Haiku/Sonnet/Opus/Fable) |
| **#15** | `render_roadmap` — "what's on the roadmap" answered by local compute, ~0 LLM tokens |

## Run it

```bash
cargo run --bin flow-server -- --mcp \
  --data .flow \
  --roadmap .i2p/roadmap
# Speaks newline-delimited JSON-RPC on stdin/stdout (the MCP stdio transport).
```

`--roadmap` takes the `.i2p/roadmap/` **tree** (folder = status) — the authoritative source (roadmap
[42]); a single `ROADMAP.md` file is still accepted (legacy). Omit it entirely and the server
auto-detects `.i2p/roadmap/` in the cwd. The `--mcp` flag is accepted for back-compat but is a no-op:
stdio is the only transport. A token file is created at `--token` (default `.flow/token`) on first run;
the stdio transport has no auth layer, so the token is not presented on a request.

## Architecture

A **pure domain core** (`src/domain/`: ids · model · graph · event · telemetry · roadmap_view · annotation —
no IO, parse-don't-validate, no cycles by construction) behind **thin adapters** (`store.rs` the one writer ·
`auth.rs` the token type · `api.rs` the shared `AppState` + JSON render helpers · `mcp.rs` the 14-verb
JSON-RPC `dispatch`). The single source of truth is the roadmap markdown + the append-only JSONL log.

## Tests

- **Rust**: `cargo test --workspace`; `cargo clippy --workspace -D warnings` + `cargo fmt --check` clean.
  The MCP verbs are exercised through `mcp::dispatch` directly; `tests/stdio_story.rs` drives the binary
  end-to-end over real stdin/stdout.

← back to the [mission-control plugin](../README.md) · the [marketplace root](../../../README.md)

## MCP registration (stdio transport)

The flow-server speaks the [MCP stdio transport](https://modelcontextprotocol.io/docs/concepts/transports)
when started with `--mcp`. The **mission-control plugin registers it itself** — `../.mcp.json` declares
the `flow-server` server, so its tools (`list_items`, `render_roadmap`, `post_status`, `set_wait_go`,
`append_spend`, …) surface as `mcp__flow-server__*` in any session where the plugin is enabled, with no
project-level `.claude/settings.json` entry. (Like every plugin MCP server, it is approval-gated under
default permissions — `claude mcp list` shows it `⏸ Pending approval` until you approve it.)

### Finishing the install (the smooth path)

After installing/updating mission-control, two one-time steps remain — and the plugin makes both as
frictionless as the harness allows:

1. **Restart Claude Code.** A plugin's `.mcp.json` is read only at startup, so a restart is required
   after an install/update for `flow-server` to appear (`/reload-plugins` loads skills/hooks but **not**
   new MCP servers).
2. **Approve it once** — run `/mcp`, find `flow-server` (⏸ *Pending approval*), approve. This one-time
   approval **cannot** be pre-granted by any setting, CLI command, or launch flag — it's a deliberate
   Claude Code security gate for plugin-shipped MCP servers. After approving once, it connects
   immediately and future sessions need nothing.

What the plugin automates around those steps: a SessionStart hook
([`hooks/scripts/flow-mcp-onboard.sh`](../hooks/scripts/flow-mcp-onboard.sh)) **pre-warms** the binary in
the background (so approval starts the server instantly, no transient "connecting/failed") and surfaces a
gentle one-time nudge; the agent then **detects** whether `mcp__flow-server__*` is connected from its own
tool list and guides only when it isn't. Run **`/mission-control:flow-setup`** any time for a guided,
verified walkthrough (it pre-caches the binary, walks the approval, and confirms the connection with a
`render_roadmap` probe). Until it's connected, "what's on the roadmap" still works via a direct scan of
the `.i2p/roadmap/` tree — the MCP path just makes it instant and ~0-token.

### No Rust toolchain required — the launcher retrieves a prebuilt binary

The registered command is the launcher [`bin/flow-server-mcp`](bin/flow-server-mcp), not `cargo`. It
obtains the binary by this ladder and execs it:

The launcher runs a **pinned release** — [`bin/RELEASE`](bin/RELEASE) names the exact tag and
[`bin/SHA256SUMS`](bin/SHA256SUMS) is the committed integrity source of truth. It execs by this ladder:

1. **Cached** — a previously-retrieved binary whose SHA256 still matches the **committed**
   `SHA256SUMS` (no network). The cache dir is keyed on the tag **plus** a fingerprint of the committed
   checksum, so a bumped/re-cut pin lands in a fresh dir — a stale cache is never re-selected.
2. **Retrieve** — download this platform's asset from the pinned
   [GitHub Release](https://github.com/agentic-underground/idea-to-production/releases) and **verify it
   against the committed checksum** (a mismatch is refused, never run). No compiler needed.
3. **Build** — *dev fallback only*: if `cargo` is present and the source is alongside, `cargo build
   --release`. A contributor's machine; never required on a destination.

Diagnose any launch with **`bin/flow-server-mcp --doctor`** — it prints the pin, the expected-vs-cached
SHA (match/mismatch), the cache dir, and the resolved project root + roadmap item count.

> **Integrity & determinism posture.** Pinning is the deliberate, owner-chosen posture (it aligns with
> `scripts/verify-prereqs.sh` §K — no floating tags). Every machine converges on ONE SHA-verified binary;
> a release is adopted only by a reviewed PR that bumps the pin. This replaced an earlier "track latest"
> launcher whose tag-keyed cache let a **re-cut** `flow-server-v0.2.0` strand machines on stale bytes
> (defect [92]). The binary now also bakes its git rev into the version it self-reports (`ping` →
> `0.2.2+<rev>`), so two builds are never confusable.

**Cutting a release — the bump-and-cut flow** (NEVER re-cut a tag; bump the version every time):

```sh
# 1. bump plugins/mission-control/flow-server/Cargo.toml `version`, then:
git tag flow-server-v0.2.2 && git push origin flow-server-v0.2.2   # → .github/workflows/flow-server-release.yml
# 2. the workflow's `preflight` refuses a re-cut tag or tag≠Cargo version, then cross-builds
#    linux/macOS/Windows (x86_64+arm64), publishes each asset + a SHA256SUMS, and notes the next step:
# 3. copy the published SHA256SUMS lines into bin/SHA256SUMS, set bin/RELEASE to the tag, commit.
```

The launcher trusts **only** the committed `bin/SHA256SUMS`, so step 3 is what activates a release.
Between step 1 and step 3 (the *bootstrap window*) destinations without `cargo` cannot fetch a binary
and devs use the source-build fallback; `verify-prereqs.sh` §P notes the window and `smoke-pinned.sh`
SKIPs until the checksums are committed. On every PR, `flow-server-mcp-smoke` (in
`.github/workflows/verify.yml`) spawns the launcher and asserts the handshake; `flow-server-mcp-pinned`
boots the **pinned** release against the tree and asserts the roadmap renders non-empty at the pinned
version (skipping in the bootstrap window).

The MCP launcher resolves the roadmap **independent of the spawn directory**: it walks up from the
working directory to the project root (the dir holding `.i2p/roadmap/`) and passes the flow-server an
absolute `--roadmap` and a root-anchored `--data`. So the roadmap is populated even when the harness
spawns the server from somewhere other than the repo root — a stale binary, not a wrong CWD, is the only
remaining way the roadmap can come up empty.
