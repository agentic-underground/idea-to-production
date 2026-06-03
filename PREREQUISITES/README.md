# PREREQUISITES — the software musculature for the `idea-to-production` marketplace

This folder documents every external tool that the marketplace plugins (**foundry**, **sentinel**,
**pressroom**) can use to do their best work, and **how to install it** — including paste-ready
Ansible fragments under [`ansible/`](ansible/) for machine provisioning.

The plugins are designed to **degrade gracefully**: a missing tool narrows a capability or a
coverage lens, it does not crash a run. Nothing here is required just to load the plugins. What it
buys you is the *high-powered* experience: live browser feedback, semantic code intelligence,
debuggers, real security scanners, and dual-engine publishing.

## How to read this folder

| File | Covers |
|---|---|
| [`00-core.md`](00-core.md) | Shared baseline every plugin assumes (git, node, python, rust, jq, ripgrep). |
| [`10-foundry.md`](10-foundry.md) | FOUNDRY: language toolchains, test runners, Playwright + browser, debuggers. |
| [`20-sentinel.md`](20-sentinel.md) | SENTINEL: SCA / SAST / secret scanners across ecosystems. |
| [`30-pressroom.md`](30-pressroom.md) | PRESSROOM: dual-engine typesetting (Typst + LaTeX), diagrams, DTP/conversion. |
| [`40-mcp.md`](40-mcp.md) | MCP servers the plugins ship (Playwright, Semgrep) + optional extras, and how plugin MCP works. |
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
/foundry:check        # or: bash plugins/foundry/skills/check/scripts/check.sh
/sentinel:check
/pressroom:check
```

`/foundry:prerequisites` emits a project-local `PREREQUISITES.md` assembled from this folder, scoped
to the plugins you actually have installed.

> **Source of truth.** The machine-readable lists live in each plugin's
> `skills/check/requirements.tsv`. The prose here is curated to match; if they drift, the `.tsv`
> wins (it is what `-check` executes).
