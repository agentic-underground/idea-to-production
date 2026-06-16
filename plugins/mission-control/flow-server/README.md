# Flow server — the Flow-Tracking Governance UI

The standing **observability/governance interface** of the idea-to-production value system: a per-project
local web app that renders the live roadmap as an interactive SVG board the human steers. One Rust binary
serves the UI, a WebSocket delta stream, and a token-gated MCP endpoint; a vanilla-JS canvas draws the
roadmap as cards in DO·DOING·DONE columns.

![The flow board, live — the mission-control roadmap ingested and rendered](docs/flow-board.png)

*Above: the running server with this repository's own `mission-control` roadmap ingested — 16 items across
two epics, the masthead reading 38% complete (the six shipped epic-#9 items in DONE).*

## What it does (epic #0, roadmap items #1–#8, #15)

| Item | Capability |
|------|-----------|
| **#1** | One Rust binary: HTTP + WebSocket + MCP on one router, **sole serialized writer** of the roadmap markdown + JSONL event log, **bearer-token** on every surface, stable slug IDs, cycle/broken-dep graph guard |
| **#2** | SVG flow-canvas: rounded-rect cards · curved connectors · DO·DOING·DONE boards · wheel-zoom-about-cursor · click-drag pan · card drag · auto-align · WAIT/GO toggle · badges |
| **#3** | Carriage telemetry: ancestor **token roll-up** (a spend on a child accrues up the dependency tree) → `telemetry.jsonl` → (graceful) local Grafana |
| **#4** | Comment / pause / annotate / rewrite: typing pauses the item, Ctrl-Enter annotates its plan, a rewrite request bumps the draft# |
| **#5** | Roadmap ingest (`--roadmap`) + git-log proxy synthesis for projects that adopted the roadmap late |
| **#6** | Masthead progress bar + pac-man completion gauge (DONE fraction → "run & observe" at 100%) + system-message feed |
| **#8** | Per-job model selection: default shown, per-card override (Haiku/Sonnet/Opus/Fable) |
| **#15** | `render_roadmap` — "what's on the roadmap" answered by local compute (MCP/REST), ~0 LLM tokens |

## Run it

```bash
cargo run --bin flow-server -- \
  --host 127.0.0.1 --port 7433 \
  --data .flow --static plugins/mission-control/flow-server/static \
  --roadmap .i2p/roadmap
# → open http://127.0.0.1:7433/?token=<the token printed to stderr / .flow/token>
```

`--roadmap` takes the `.i2p/roadmap/` **tree** (folder = status) — the authoritative source (roadmap
[42]); a single `ROADMAP.md` file is still accepted (legacy). Omit it entirely and the server
auto-detects `.i2p/roadmap/` in the cwd. `--host` defaults to LAN-reachable; the token is generated to
`--token` (default `.flow/token`) on first run and required on every HTTP/WS/MCP request.

## Architecture

A **pure domain core** (`src/domain/`: ids · model · graph · event · telemetry · roadmap_view · annotation —
no IO, parse-don't-validate, no cycles by construction) behind **thin adapters** (`store.rs` the one writer ·
`auth.rs` token gate · `api.rs` REST · `ws.rs` broadcast · `mcp.rs` 14-verb JSON-RPC). The single source of
truth is the roadmap markdown + the append-only JSONL log; the UI is a view.

## Tests

- **Rust**: `cargo test` → 277 tests; `cargo clippy -D warnings` + `cargo fmt --check` clean; domain core and
  every new module at **100% line+region**, `main.rs` the only excluded shim (an entrypoint, e2e-smoked).
- **Frontend**: `cd static && npm test` → 164 vitest+jsdom tests, 100% coverage.
- **Live**: booted with the real roadmap ingested; HTTP/WS/MCP exercised end-to-end (token-reject, 14
  verbs, cycle-reject, REST+MCP through the one writer, board renders all 16 items — see the screenshot).

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
> `0.2.1+<rev>`), so two builds are never confusable.

**Cutting a release — the bump-and-cut flow** (NEVER re-cut a tag; bump the version every time):

```sh
# 1. bump plugins/mission-control/flow-server/Cargo.toml `version`, then:
git tag flow-server-v0.2.1 && git push origin flow-server-v0.2.1   # → .github/workflows/flow-server-release.yml
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
absolute `--roadmap` and a root-anchored `--data`. So the board is populated even when the harness
spawns the server from somewhere other than the repo root — a stale binary, not a wrong CWD, is the only
remaining way the board can come up empty.
