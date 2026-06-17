# Headless Browser — the domain ledger for browser tooling

> Canonical reference for **how the marketplace resolves a browser**, and the one failure class
> that wastes the most time when it doesn't. One copy; every browser-consuming skill links here
> rather than restating any of it.
>
> This is a **domain ledger** in the sense of
> [`../protocols/guardrails-ledger.md`](../protocols/guardrails-ledger.md): it follows that
> pattern (symptom → cause → fix, stable IDs) and **owns** the browser-tooling entries — the
> pattern file itself holds none, because "domain ledgers live with the skill that owns the
> domain." Define once here; reference, never paraphrase.

---

## 1. Two resolvers, one browser, many slots

The marketplace owns exactly **two** browser consumers, and **each resolves a browser
differently** — this is the whole source of the pain below:

| Consumer | How it finds a browser | Marketplace-shipped? |
|---|---|---|
| **mmdc / puppeteer** (mermaid-cli → puppeteer) | a **pinned Chrome revision** under `~/.cache/puppeteer`, **or** whatever `PUPPETEER_EXECUTABLE_PATH` points at | yes (publish uses `mmdc` to render diagrams) |
| **Playwright MCP** (`npx @playwright/mcp`) | a **slot** under `~/.cache/ms-playwright` (`PLAYWRIGHT_BROWSERS_PATH`), including a per-MCP `mcp-chromium-<hash>/` slot | yes (`atelier`, `foundry` `.mcp.json`) |

A browser also lives **system-wide**, discoverable with `command -v chromium`
(`chromium-browser`, `google-chrome`). The decisive fact: **the same browser is usually on disk
in several places at once** — a system `chromium`, a populated puppeteer revision, one or more
ms-playwright slots — and a tool reports "not installed" only because **its own** resolver points
at an empty or mismatched location, not because no browser exists.

> A presence probe (`command -v chromium`) answers "is a browser on the box?" — **not** "can
> *this consumer* launch one?" Those are different questions; conflating them is the trap below.

---

## 2. Ledger entries

### TC-BROWSER-1 — "browser not installed" while a browser is on disk
- Symptom: mmdc / a browser MCP reports "could not find Chrome / not installed", yet
  `command -v chromium` succeeds and another tool just rendered with it.
- Cause: each consumer resolves a browser differently (pinned puppeteer revision, an
  ms-playwright slot incl. mcp-chromium-<hash>, /opt/google/chrome). A presence check
  passes while the consumer's own slot is empty/mismatched. "Install" re-downloads what
  exists, often into yet another slot.
- Fix → THE ONLY WAY: DIAGNOSE before installing. Locate any real browser, re-point the
  consumer (PUPPETEER_EXECUTABLE_PATH for puppeteer/mmdc; repair the ms-playwright stub
  for the MCP), then VERIFY the healed path launches. If one tool just rendered with a
  browser, every sibling "not installed" is a WIRING lie. See ensure-browser.sh (P0-3).

The repair tool is [`scripts/ensure-browser.sh`](../../../../scripts/ensure-browser.sh): `--check`
diagnoses (locate every browser on disk, name the empty slot); `--fix` re-points the resolver and
atomically repairs an empty ms-playwright stub, then **verifies the healed slot actually launches**
before reporting success. A heal that can't prove itself is not a heal.

---

## 3. THE ONLY WAY — the behavioural rule

> **THE ONLY WAY:** on "browser not installed", **LOCATE** an existing browser (system `PATH`, a
> populated `ms-playwright` slot, or the puppeteer cache) and **RE-POINT** the tool
> (`export PUPPETEER_EXECUTABLE_PATH=…`; run `scripts/ensure-browser.sh --fix`); **NEVER install
> before diagnosing — a sibling tool that just rendered proves a browser exists.**

The reasoning travels with the rule (per `guardrails-ledger.md`): reinstalling is the *expensive
wrong move* — it re-downloads a browser that is already present, frequently into a third slot,
leaving the failing consumer still mis-wired and the disk fatter. The 5-second diagnosis
(`ls ~/.cache/ms-playwright`, `command -v chromium`) settles it. Installing fresh is justified
*only* when the diagnosis finds **no** browser anywhere — and then it is the documented last
resort (`npx playwright install --with-deps chromium`), not the reflex.

---

## Referenced by

Browser-consuming skills link here for the resolver model and TC-BROWSER-1 — they do not restate it:

- `atelier/ui-review` — crawls routes via the Playwright MCP (ms-playwright slot resolver).
- `atelier/mockup` — screenshots renderable HTML/CSS via the Playwright MCP.
- `publish/rich-pdf-with-diagrams` — renders Mermaid via `mmdc`/puppeteer.
- **foundry story phases** — live STORY feedback through the Playwright MCP.
- **operate's** browser-using skills — runtime/observability surfaces that drive a browser.

Discovery/install prose for both resolvers lives in the marketplace
[`PREREQUISITES/40-mcp.md`](../../../../PREREQUISITES/40-mcp.md) ("Headless-browser discovery");
this doc owns the *pattern* and the *ledger*, that doc owns the *setup env*.
