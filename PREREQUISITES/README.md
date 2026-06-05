# PREREQUISITES — the software musculature for the `idea-to-production` marketplace

This folder documents every external tool that the marketplace plugins (**market-scanner**, **ideator**,
**foundry**, **sentinel**, **pressroom**) can use to do their best work, and **how to install it** —
including paste-ready Ansible fragments under [`ansible/`](ansible/) for machine provisioning.

---

## ⮕ HANDOFF TO THE PROVISIONING AGENT

> **You (the next agent) are building/updating an Ansible project from this folder.** Read this first;
> it is the contract. Everything below is designed so you can provision a machine that gives this
> marketplace its *high-powered* experience without guessing.

**The rules that make this frictionless:**

1. **`requirements.tsv` is canonical.** Each plugin's `skills/check/requirements.tsv` is the
   machine-readable source of truth (`name <TAB> probe <TAB> tier <TAB> install-hint`). The prose in
   this folder is curated to match; **if they ever drift, the `.tsv` wins** (it is what `…:check` runs).
   Drive your playbook off the union of the five `.tsv` files.
2. **Installable vs runtime-secret.** Provision **binaries and launchers** (`uvx`, `npx`, `cargo`,
   `apt`, …). **Never** bake an **API key** into the playbook — Tavily/Exa/GitHub/Context7-optional keys
   are **runtime secrets**, injected via env at use time. MCP servers themselves launch ephemerally
   (`uvx …`, `npx -y …`); ensuring `uv` and `node` are present is the whole job.
3. **Tiers gate inclusion.** `required` (rare — core promise), `recommended` (install on any real dev
   box), `optional` (stack/lens-specific). A sensible default playbook installs required + recommended.
4. **Idempotent + plugin-tagged.** The fragments in [`ansible/`](ansible/) use `creates:` / `changed_when`
   guards and `tags: [foundry, sentinel, …]` so you can subset by capability (`--tags pressroom`).

**Checklist:**
- [ ] Run [`ansible/core-bootstrap.yml`](ansible/core-bootstrap.yml) **first** (installs rustup/uv/Volta into the user `$HOME`).
- [ ] Then [`apt.yml`](ansible/apt.yml), [`cargo.yml`](ansible/cargo.yml), [`npm.yml`](ansible/npm.yml), [`uv.yml`](ansible/uv.yml), [`binaries.yml`](ansible/binaries.yml) in any order, tagged to the tiers you want.
- [ ] Leave API keys to runtime env (document which servers need which key; do not store them).
- [ ] Verify with the per-plugin `…:check` (advisory) — a clean run means the box matches the spec.
- [ ] See [`50-awesome-software.md`](50-awesome-software.md) for the curated pin-list + high-value additions.

**What changed in the latest pass (2026-06-05):** added the two front-end plugins (**market-scanner**,
**ideator**) and their web-research tier ([`05-discovery.md`](05-discovery.md)); the marketplace now
ships **two more MCP servers** — **Fetch** (discovery, keyless `uvx mcp-server-fetch`) and **Context7**
(foundry, keyless `npx -y @upstash/context7-mcp`) — joining Playwright + Semgrep; documented optional
research/runtime MCPs (Tavily, Exa, official GitHub, Postgres, Sentry) in [`40-mcp.md`](40-mcp.md).

---

The plugins are designed to **degrade gracefully**: a missing tool narrows a capability or a
coverage lens, it does not crash a run. Nothing here is required just to load the plugins. What it
buys you is the *high-powered* experience: live browser feedback, semantic code intelligence,
debuggers, real security scanners, and dual-engine publishing.

## How to read this folder

| File | Covers |
|---|---|
| [`00-core.md`](00-core.md) | Shared baseline every plugin assumes (git, node, python, rust, jq, ripgrep). |
| [`05-discovery.md`](05-discovery.md) | MARKET-SCANNER + IDEATOR: the web-research tier (WebSearch/WebFetch, Fetch MCP, optional Tavily/Exa). |
| [`10-foundry.md`](10-foundry.md) | FOUNDRY: language toolchains, test runners, Playwright + browser, Context7 docs, debuggers. |
| [`20-sentinel.md`](20-sentinel.md) | SENTINEL: SCA / SAST / secret scanners across ecosystems. |
| [`30-pressroom.md`](30-pressroom.md) | PRESSROOM: dual-engine typesetting (Typst + LaTeX), diagrams, DTP/conversion. |
| [`40-mcp.md`](40-mcp.md) | MCP servers the plugins ship (Playwright, Semgrep, Fetch, Context7) + optional extras, and how plugin MCP works. |
| [`45-lsp.md`](45-lsp.md) | Language servers wired via the marketplace manifest, + the official LSP companion plugins. |
| [`50-awesome-software.md`](50-awesome-software.md) | "Software I found that is awesome" — curated for the Ansible provisioning project. |

## Tiers

Every tool is tagged with a tier. The per-plugin `/…:check` skills read the same tiering from each
plugin's `skills/check/requirements.tsv` and report ✓/✗ against it:

- **required** — the plugin's core promise needs it (rare; most things degrade).
- **recommended** — materially better output / feedback; install on any real dev machine.
- **optional** — nice to have for a specific stack or lens.

## Verifying a machine

Run the per-plugin checks (advisory by default; `--strict` exits non-zero on a missing **required** tool):

```bash
/market-scanner:check # or: bash plugins/market-scanner/skills/check/scripts/check.sh
/ideator:check
/foundry:check
/sentinel:check
/pressroom:check
```

`/foundry:prerequisites` emits a project-local `PREREQUISITES.md` assembled from this folder, scoped
to the plugins you actually have installed.

> **Source of truth.** The machine-readable lists live in each plugin's
> `skills/check/requirements.tsv`. The prose here is curated to match; if they drift, the `.tsv`
> wins (it is what `-check` executes).
