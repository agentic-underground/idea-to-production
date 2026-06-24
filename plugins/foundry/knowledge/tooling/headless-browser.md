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

## 1. ONE BROWSER — one binary per host, two consumers

The marketplace consolidates on **exactly one browser per host** — the system Chromium
(`command -v chromium`/`chromium-browser`/`google-chrome`; on FLEET the apt `/usr/bin/chromium`).
Both marketplace consumers point at that one binary:

| Consumer | How it finds the browser | Marketplace-shipped? |
|---|---|---|
| **mmdc / puppeteer** (mermaid-cli → puppeteer) | whatever `PUPPETEER_EXECUTABLE_PATH` points at (the system Chromium), `PUPPETEER_SKIP_DOWNLOAD=1` | yes (publish renders diagrams) |
| **`chrome-devtools` MCP** (navigate/click/fill/screenshot/a11y/console/network) | **host-provided** — the host registers it pointed at the system Chromium (`--executablePath … --isolated`) | **no — host-provided, not bundled** |

> **History (the collision this fixed).** The marketplace once shipped a `@playwright/mcp` server in
> `atelier`/`foundry` `.mcp.json`. It defaulted to a Google-Chrome channel headless hosts don't
> install, *and* it pinned/GC'd browsers in the shared `~/.cache/ms-playwright` — its registry GC
> deleted other tools' pinned browser (the "flappy chromium" bug). The **ONE BROWSER** cutover removed
> it in favour of the host `chrome-devtools` driving the single system Chromium. There is no
> `~/.cache/ms-playwright` slot in the picture any more.

> A presence probe (`command -v chromium`) answers "is a browser on the box?" — **not** "can it
> actually launch?" Those are different questions; conflating them is the trap below (and the reason
> the readiness probe must drive a real browser action, not just a handshake).

---

## 2. Ledger entries

### TC-BROWSER-1 — "browser not installed" while a browser is on disk
- Symptom: mmdc / a browser consumer reports "could not find Chrome / not installed", yet
  `command -v chromium` succeeds and another tool just rendered with it.
- Cause: a consumer resolves a browser by its **own** wiring (puppeteer's pinned revision or
  `PUPPETEER_EXECUTABLE_PATH`; a stray `~/.cache/puppeteer` / `~/.cache/ms-playwright` left by an old
  install). A presence check passes while the consumer's own pointer is empty/mismatched. "Install"
  re-downloads what already exists, often into yet another cache.
- Fix → THE ONLY WAY: DIAGNOSE before installing. Locate any real browser, **re-point the consumer at
  the system Chromium** (`PUPPETEER_EXECUTABLE_PATH` for puppeteer/mmdc; `--executablePath` for the
  chrome-devtools MCP), then VERIFY the path launches. If one tool just rendered with a browser, every
  sibling "not installed" is a WIRING lie. See `ensure-browser.sh` (P0-3).

The repair tool is [`scripts/ensure-browser.sh`](../../../../scripts/ensure-browser.sh): `--check`
diagnoses (locate every browser on disk); `--fix` re-points the resolver at the system Chromium and
**verifies it actually launches** before reporting success. A heal that can't prove itself is not a heal.

---

## 3. THE ONLY WAY — the behavioural rule

> **THE ONLY WAY:** on "browser not installed", **LOCATE** an existing browser (system `PATH` or the
> puppeteer cache) and **RE-POINT** the tool at it
> (`export PUPPETEER_EXECUTABLE_PATH=…`; run `scripts/ensure-browser.sh --fix`); **NEVER install
> before diagnosing — a sibling tool that just rendered proves a browser exists.**

The reasoning travels with the rule (per `guardrails-ledger.md`): reinstalling is the *expensive
wrong move* — it re-downloads a browser that is already present, frequently into a third cache,
leaving the failing consumer still mis-wired and the disk fatter. The 5-second diagnosis
(`command -v chromium`, `ls ~/.cache/puppeteer`) settles it. Installing fresh (`apt-get install -y
chromium`) is justified *only* when the diagnosis finds **no** browser anywhere — the last resort, not
the reflex.

---

## 4. Browser-MCP rules — the ONE BROWSER maintenance contract

Any browser MCP the marketplace ever ships (today: **none** — it depends on the host `chrome-devtools`)
MUST obey all five, or it recreates the collision the cutover fixed:

1. **Never default to `channel: chrome`.** That assumes Google Chrome at `/opt/google/chrome/chrome`,
   which headless/server hosts don't install. Default to a bundled chromium **or** a host-supplied
   executable.
2. **Never pin/download a browser into a shared cache** (`~/.cache/ms-playwright`) that another tool's
   registry GC can prune — that is what caused the flappy-browser collisions.
3. **Always honour an executable-path / env override** so a host can supply its own browser
   (`--executablePath`, or read `${BROWSER_EXEC}`/`PUPPETEER_EXECUTABLE_PATH`).
4. **Prefer the host's system browser when present.** One browser per host = fewer version/GC collisions.
5. **A handshake is not health.** If you gate on MCP health, exercise a **real browser action**
   (launch → navigate → screenshot), never just `initialize`.

---

## Referenced by

Browser-consuming skills link here for the resolver model and TC-BROWSER-1 — they do not restate it:

- `atelier/ui-review` — crawls routes via the chrome-devtools MCP (host-provided, system Chromium).
- `atelier/mockup` — screenshots renderable HTML/CSS via the chrome-devtools MCP.
- `publish/rich-pdf-with-diagrams` — renders Mermaid via `mmdc`/puppeteer (system Chromium).
- **foundry story phases** — live feedback through the chrome-devtools MCP; the committed STORY test
  uses the Playwright **runner** (a per-project browser, separate from the marketplace MCP).
- **operate's** browser-using skills — runtime/observability surfaces that drive a browser.

This doc owns the *pattern*, the *ledger*, and the *browser-MCP rules*; setup-env prerequisites are outside its scope.
