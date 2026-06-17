# Foundry Reviewer — Memory Index

- [Marketplace supply-chain risk class](project_marketplace-supply-chain.md) — unpinned third-party exec (@latest/uvx/curl|sh/releases-latest) recurs in .mcp.json & ansible; flag + push systematic fix
- [Provenance archive is rename-exempt](project_provenance-archive.md) — examples/ + docs/ + rust-webapp-rollout keep old FORGE/forge- names by design; not dangling refs
- [Rewrite-changeset regression patterns](feedback_rewrite-regressions.md) — where to look first when a script/interface is rewritten under a stable caller
- [Plugin-count drift](project_plugin-count-drift.md) — nine plugins; hardcoded counts in docs/figures/alt-text drift; CI canonical-copy checks N=KAIZEN.md, O=inject-kaizen.sh (SOUL Checks E/F retired)
- [KAIZEN covenant rename](project_kaizen-covenant-rename.md) — SOLID covenant→KAIZEN (reframe); preserve code-SOLID (solid.md/code-quality/DESIGN-REVIEWER); CI N/O = KAIZEN parity
- [Model-id drift](project_model-id-drift.md) — literal model ids restated inline in ~45 files vs reference-don't-pin canon; KAIZEN systemic flag, NOT a per-PR gate
- [Wiki-publisher asset exfil](project_wiki-publisher-exfil.md) — publish-wiki.sh guard blocklists http/abs/< but misses ../; blocklist-not-allowlist sanitiser class recurs marketplace-wide
- [flow-server stdio transport](project_flow-server-stdio-transport.md) — --mcp stdio loop: LIVE risk is unbounded read_line (OOM); IO-disclosure/auth/traversal/injection already mitigated, don't re-flag
- [flow-server tool-naming drift](project_flow-server-tool-naming-drift.md) — MCP gate tool is set_wait_go in code; EARS/README/feature docs wrongly call it set_gate (= store method); tests are right
- [flow-server pin-parse robustness](project_flow-server-pin-parse.md) — launcher SHA256 pin-parser NOW hardened (skips #/blank, requires 64-hex); empty pin → retrieve() refuses download; exec gate fails closed
- [flow-server web removal (PR #39)](project_flow-server-web-removal.md) — stdio-MCP-only; no listener survives (net-positive), launcher fails closed; residual MEDIUM = dead Token/--token wiring + lying auth.rs doc; board docs owned by separate #102
- [flow-server status/lane model](project_flow-server-status-lane-model.md) — Status=do|doing|done (3) over folders backlog/do/doing/done (4); post_status writes tree itself + refuses on WAIT; id=item-N; facts /flow carry docs must match
- [flow-server roadmap-tree wiring](project_flow-server-roadmap-tree.md) — item [42]: apply_roadmap refactor faithful; auto-ingest+write-back is a default-behaviour change; watch-hook trigger gap deferred to [39]; 341+3 green (ignore stale zzz_attack ghost tests)
- [flow-server release/bootstrap window](project_flow-server-release-window.md) — pinned-release two-phase model; §P+smoke-pinned PASS empty SHA256SUMS; bump opens cargo-less-destination outage until tag published → MEDIUM owned-follow-up; main pin was finalized v0.2.1
- [flow-server mutate-before-IO window](project_flow-server-mutate-before-io.md) — Store advances in-memory flow before fallible .await? IO, no rollback/no poison → memory/journal divergence on IO Err; IO-under-lock itself is the consistent pattern, don't flag
- [SessionStart bg-detach pattern](project_sessionstart-bg-detach.md) — `( cmd >/dev/null 2>&1 & ) >/dev/null 2>&1` inner redirect severs fd so $(...)/check-L timeout return instantly while bg download runs
- [Pressroom knowledge scaffold](project_pressroom-knowledge-scaffold.md) — pressroom lacks foundry's knowledge/ tree; foundry-copied handlers import broken knowledge links; target covenant→pressroom/knowledge/covenant.md; CI Check I skips ${CLAUDE_PLUGIN_ROOT} refs so they pass CI yet break at runtime
