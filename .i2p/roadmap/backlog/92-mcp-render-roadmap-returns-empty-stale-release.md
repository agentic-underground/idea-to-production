---
id: 92
title: "flow-server MCP render_roadmap returns empty (stale pinned release) + roadmap-read routing gaps"
status: PENDING
priority: HIGH
added: 2026-06-16
depends_on: "—"
---

# [92] flow-server MCP `render_roadmap` returns empty (stale pinned release) + roadmap-read routing gaps

> **DISPOSITION (2026-06-16).** Filed by a downstream project (branch `mcp-issue`) and confirmed **live**:
> the connected MCP's `render_roadmap` returned empty against a 92-item tree because the launcher pins
> `flow-server-v0.1.0`, which predates the tree ingest of item [42]. Adopted fixes: **R1** (re-cut
> `flow-server-v0.2.0` + re-pin RELEASE/SHA256SUMS + a CI guard that tests the *pinned release binary*,
> not a source build — that gap is why CI was green while users were broken), **R3** (a `ping` health
> verb reporting version/items/source + an empty-`render_roadmap` diagnostic, so an empty result is never
> silently authoritative), **R4** (mission-control injects its own read-via-MCP routing), **R2** (one
> binary + one resolution path across MCP/HTTP). **Deferred:** R5 (PreToolUse ad-hoc-read guard —
> intrusive once the MCP works + routes) and R6 (downstream adopter snippet — separate concern; capture
> as its own item).

**Brief Description**

A consuming agent (Claude Code, in a downstream repo that adopted the `.i2p/roadmap/` tree) was asked
"what's on the roadmap" and answered by `ls`/`head`-ing the tree files instead of calling the flow-server
MCP verb `render_roadmap`. Adversarial review traced this to a real defect, not operator error: **the MCP
read path returns empty against a populated roadmap tree**, so raw file reading is the only path that
yields an answer. Three routing/visibility gaps compound it.

### Verified root cause

**L1 — PRIMARY: stale pinned MCP release.** `.mcp.json` launches the stdio server via
`flow-server/bin/flow-server-mcp`, which `exec`s the release pinned in `bin/RELEASE` =
`flow-server-v0.1.0`. Tree-reading (item [42]) landed **after** the v0.1.0 tag
(`git merge-base --is-ancestor flow-server-v0.1.0 a1393f1` → true). v0.1.0 has no
`ingest_source`/`ingest_roadmap_tree`; with no `--roadmap` arg, `cfg.roadmap_path = None` → empty store →
`render_roadmap`/`list_items` return empty. The HTTP board runs a newer build invoked with `--roadmap`,
which ingests and renders. **MCP and HTTP transports ran different binary versions.** An empty-but-
successful MCP response is the worst failure mode — it looks authoritative and trains agents to bypass.

**L2 — routing reaches the wrong audience.** The "do NOT ad-hoc-read → use `render_roadmap`" rule lived
only in `.i2p/roadmap/README.md` (not injected) and foundry's `roadmapper` skill (foundry may be absent).
mission-control — which *ships* the server — injected nothing about reading the roadmap.

**L3 — transport invisibility.** The harness *defers* MCP tools past a tool-count threshold; a deferred
verb is name-only and needs `ToolSearch` first, so the already-loaded `Bash` won.

**L4 — consumer drift.** Downstream repos adopt the tree but describe it as storage ("the folder is the
status") without the read-via-MCP rule.

### EARS Specification

**Ubiquitous**
- The system SHALL render the roadmap identically over the MCP (`render_roadmap`/`list_items`) and HTTP
  transports for the same `.i2p/roadmap/` tree.
- The pinned MCP release SHALL contain every capability the marketplace's own roadmap tree relies on (at
  minimum, `.i2p/roadmap/` tree ingest, item [42]).

**Event-driven**
- WHEN the stdio server starts in `--mcp` mode, THE SYSTEM SHALL resolve and ingest the `.i2p/roadmap/`
  tree by the same default as HTTP.
- WHEN mission-control loads at SessionStart, THE SYSTEM SHALL inject a roadmap-read routing line naming
  `render_roadmap` as the ~0-token authoritative path.

**Unwanted behaviour**
- IF the store is empty but a `.i2p/roadmap/` tree with ≥1 item exists, THEN `render_roadmap` SHALL return
  a diagnostic (not a silent empty success), and `ping` SHALL surface version + item count + source.
- IF the MCP read verb is deferred, THEN the injected routing SHALL name the verb so the agent knows to
  `ToolSearch` for it.

### Acceptance Criteria

1. Given a populated `.i2p/roadmap/` tree, When an agent calls `render_roadmap` over MCP, Then it returns
   the same non-empty table the HTTP board shows.
2. Given the pinned release in `bin/RELEASE`, When CI runs, Then a regression test boots
   `<pinned-binary> --mcp` against a fixture tree and asserts `render_roadmap` is non-empty — failing the
   build if the pinned release predates tree support.
3. Given a fresh session with mission-control enabled (foundry absent), When asked "what's on the
   roadmap", Then injected context routes to `render_roadmap` (verb named) without reading tree files.
4. Given an empty store, When `render_roadmap`/`ping` is called, Then the response carries a
   stale/misconfig diagnostic (version/items/source), not a bare empty success.

### Implementation Notes

- **R1** — cut `flow-server-v0.2.0` (includes [42] + the `ping` verb), re-pin `bin/RELEASE` + `bin/SHA256SUMS`;
  add the AC-2 CI job that tests the **pinned release binary** (the user-facing one), not a source build.
- **R3** — `ping` verb `{message,"version","items","source"}` + empty-`render_roadmap` note.
- **R4** — mission-control SessionStart injects the read-via-MCP routing (don't depend on foundry).
- **R2** — confirm the stdio server's cwd resolves `.i2p/roadmap`; if not, the launcher passes `--roadmap`/`--data`.
- KAIZEN: L1 is a *defect*; L2/L4 are *transport/hand-off waste*; the file-read fallback is *rediscovery*
  (the 8th waste). Fix upstream once (R1+R3+R4) so no future consumer pays for it again.

### Known risks / open questions

- Does Claude Code launch plugin MCP servers with cwd = project root? (Decides whether R2 needs a launcher
  arg or just the cwd default — verified during the fix.)
- Release-cut cadence for flow-server: the AC-2 CI guard makes a stale pin un-shippable regardless.
