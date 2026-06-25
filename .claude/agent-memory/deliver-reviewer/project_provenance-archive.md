---
name: provenance-archive
description: Which directories intentionally retain old FORGE/forge- identifiers and must NOT be flagged as dangling references during rename reviews
metadata:
  type: project
---

During the FORGE→DELIVER purge, old identifiers (`FORGE`, `forge-plan`/`forge-ears`/etc., `FORGE_HELLO.md`, `~/.claude`) were intentionally retained in a provenance archive and are NOT live-surface dangling references.

The inspector's portability sweep (plugins/deliver/agents/inspector.md, Phase 3 item 7) explicitly allowlists:
- `plugins/deliver/docs/HISTORY.md`, `docs/MIGRATION.md`, `docs/DEPRECATED.md`
- the entire `plugins/deliver/examples/` directory (historical worked examples)
- the lowercase `forge` rust **sample-project** names (`forge-core`, `{{crate_prefix}}=forge`) in `rust-webapp-rollout` — a sample project, not FORGE-the-system

**Why:** these are frozen teaching/provenance artefacts; rewriting them would falsify history.
**How to apply:** when reviewing a rename, grep live surfaces only — exclude `examples/`, `docs/`, and `rust-webapp-rollout/`. A `forge-*` hit inside those is expected, not a regression. The live phase definitions (skills/phase-sensor/phases/phase-*.md) DO use the new `deliver-*` names. See [[rewrite-regressions]].
