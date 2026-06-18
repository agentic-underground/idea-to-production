# Flow MCP — the roadmap MCP core

The standing **roadmap-tracking surface** of the idea-to-production value system: a **Ruby server**
(Ruby ≥ 3.3.8, standard library only) that ingests a project's `.i2p/roadmap/` tree and exposes it to an
agent as an **MCP verb surface over stdio**. It is the **sole serialized writer** of the roadmap markdown
+ JSONL event log, so every read and mutation flows through one authoritative path.

> **Why Ruby, not a binary.** flow-mcp was a compiled Rust binary distributed as a SHA-pinned GitHub
> release. That model was chronically broken — release-sync friction, stale binary caches, undead
> binaries, and **zero visibility** into what happened during a call. It was re-homed to an interpreted
> Ruby reference: **no artifact-drift** (nothing to build, download, pin, or checksum), and every fault is
> investigable immediately (rich stderr logging + full backtraces). The behavioural contract is frozen,
> language-neutrally, in [`spec/EARS.md`](spec/EARS.md) (+ the Gherkin suite in [`spec/features/`](spec/features/)),
> so the *behaviour* survives the implementation change. The lesson is written up in
> [`../../foundry/knowledge/architecture/mcp-language-choice.md`](../../foundry/knowledge/architecture/mcp-language-choice.md).

## What it does

| Capability |
|-----------|
| The 14-verb MCP surface over stdio; **sole serialized writer** of the roadmap markdown + JSONL event log; stable slug IDs; cycle/broken-dep graph guard |
| Carriage telemetry: ancestor **token roll-up** (a spend on a child accrues up the dependency tree) |
| Comment / pause / annotate / rewrite: `annotate` records a comment; `request_rewrite` bumps the draft# |
| Roadmap ingest of the `.i2p/roadmap/` tree (folder = status), with `post_status` write-back; legacy single `ROADMAP.md` also accepted |
| System-message feed via `append_sysmsg` / `list_events` |
| Per-job model selection: `set_item_model` |
| `render_roadmap` — "what's on the roadmap" answered by local compute, ~0 LLM tokens |

## Run it

```bash
ruby exe/flow-mcp --mcp --data .flow --roadmap .i2p/roadmap
# Speaks newline-delimited JSON-RPC on stdin/stdout (the MCP stdio transport).
```

`--roadmap` takes the `.i2p/roadmap/` **tree** (folder = status) — the authoritative source; a single
`ROADMAP.md` file is still accepted (legacy). Omit it and the server auto-detects `.i2p/roadmap/` in the
cwd. `--mcp` is accepted for back-compat but is a no-op: stdio is the only transport. The server requires
**no gems** — only the Ruby standard library.

## Architecture

A **pure domain core** (`lib/flow_mcp/`: `ids` · `model` (graph) · `event` · `telemetry` · `roadmap_view`
· `annotation` — no IO, parse-don't-validate, acyclic by construction) behind **thin adapters**
(`store.rb` the one writer · `history.rb` roadmap ingest · `mcp.rb` the 14-verb JSON-RPC `dispatch` ·
`config.rb` · `server.rb` the stdio loop). `exe/flow-mcp` wires them together with a top-level
backtrace-to-stderr handler. The single source of truth is the roadmap markdown + the append-only JSONL log.

## Tests

Run on **bare Debian-13 system Ruby** with **no `gem install`** — `minitest` is bundled, the Gherkin
FEATURE suite runs via a stdlib step runner (no cucumber), and coverage uses the stdlib `Coverage`
module (no simplecov). On the fleet, bundler — if ever needed — is `bundle3.3`, never bare `bundle`.

```bash
rake coverage   # full suite + line/branch coverage gate
rake smoke      # boot the server and exchange a JSON-RPC handshake over stdio
ruby -Itest -Ilib test/test_mcp.rb   # a single file
```

Every behaviour is traced to an `EARS-FLOW-NNN` id; `test/test_features.rb` enforces the spec↔test
traceability invariant.

← back to the [flow plugin](../.claude-plugin/plugin.json) · the [marketplace root](../../../README.md)

## MCP registration (stdio transport)

The flow-mcp server speaks the [MCP stdio transport](https://modelcontextprotocol.io/docs/concepts/transports).
The **flow plugin registers it itself** — [`../.mcp.json`](../.mcp.json) declares the `flow-mcp` server
via the launcher [`bin/flow-mcp`](bin/flow-mcp), so its tools (`render_roadmap`, `list_items`,
`post_status`, `set_wait_go`, `append_spend`, …) surface as `mcp__flow-mcp__*` in any session where the
plugin is enabled. Like every plugin MCP server it is approval-gated under default permissions
(`⏸ Pending approval` until you approve it).

### Finishing the install

After installing/updating flow, two one-time steps remain:

1. **Restart Claude Code.** A plugin's `.mcp.json` is read only at startup, so a restart is required
   after an install/update for `flow-mcp` to appear (`/reload-plugins` loads skills/hooks but **not**
   new MCP servers).
2. **Approve it once** — run `/mcp`, find `flow-mcp` (⏸ *Pending approval*), approve. This one-time
   approval **cannot** be pre-granted by any setting, CLI command, or launch flag — a deliberate Claude
   Code security gate. After approving once it connects immediately and future sessions need nothing.

Run **`/flow:flow-setup`** any time for a guided, verified walkthrough. A SessionStart hook
([`../hooks/scripts/flow-mcp-onboard.sh`](../hooks/scripts/flow-mcp-onboard.sh)) surfaces a gentle
one-time nudge and the standing routing rule; the agent detects whether `mcp__flow-mcp__*` is connected
from its own tool list and guides only when it isn't.

### The launcher

The registered command is [`bin/flow-mcp`](bin/flow-mcp): it finds a **Ruby ≥ 3.3.8** (`$FLOW_MCP_RUBY`,
then `ruby` / `ruby3.3` / `ruby3.4`, then common Homebrew/rbenv/asdf shims) and execs the Ruby server.
There is no download, cache, checksum, or build step — an interpreted server has nothing to drift. If no
compliant Ruby is found, the launcher exits non-zero pointing at the **`/flow:flow-by-hand`** markdown
fallback runbook (the agent operates the `.flow/` files by hand — same semantics, slower, no server).

Diagnose any launch with **`bin/flow-mcp --doctor`** — it prints the resolved Ruby + version, the
project root, and the roadmap item count.

The launcher resolves the roadmap **independent of the spawn directory**: it walks up from the working
directory to the project root (the dir holding `.i2p/roadmap/`) and passes the server an absolute
`--roadmap` and a root-anchored `--data`, so the board is populated even when the harness spawns the
server from elsewhere. On every PR, `flow-mcp-ruby` (in `.github/workflows/verify.yml`) runs the test
suite + coverage on Ruby 3.3.8 and drives a stdio handshake through this launcher.
