# I2P_SELF_HEALING_PLAN — making the marketplace heal itself

> **⚠️ Transient coordination document, not part of the marketplace.** Like `REVIEW_ACTION_PLAN.md`,
> this is a backlog for maintainers to schedule. When every item is shipped or consciously dismissed,
> delete it: `git rm I2P_SELF_HEALING_PLAN.md`.
>
> **Governance: `pr-approval`, never self-merge** (`plugins/foundry/knowledge/protocols/merge-governance.md`).
> Each item is a discrete, individually-shippable `/<plugin>:self-improve` target → `/foundry:pr-review` →
> PR for a human to merge. **Honour the four-mirror guardrail** (`REVIEW_ACTION_PLAN.md`): when an item
> changes a skill, update `plugin.json` + the `marketplace.json` entry + `README.md` +
> `skills/check/requirements.tsv` in the same branch and bump the plugin version.
>
> **Authored 2026-06-07; revised after adversarial review (§8).** Origin: a real incident (§2) + a
> marketplace-wide self-healing sweep, then hardened by a five-lens panel that **refuted the first draft**
> (foundry-centric, a broken flagship sketch, two factual overclaims) — all fixed below.

---

## 1 · Purpose & how to use

The marketplace is excellent at **detect → degrade → disclose**: `/<plugin>:check` probes tools, skills
degrade when a companion/tool is absent, and nothing fails silently *that it knows about*. What it does not
yet do is **self-heal** — *detect → diagnose → repair → verify → prevent*. This plan catalogues what already
heals (§4), then enumerates the opportunities to close that gap (§5), prioritised P0→P2, each mapped to an
owning plugin/file and classified on the maturity model (§3). P0 items carry inline reference sketches.

This document **references** canon rather than restating it (the define-once/reference-many rule —
`CLAUDE.md`, `plugins/foundry/knowledge/architecture/self-architecture.md`). Read those, plus
`plugins/foundry/VALUE_FLOW.md` and the three pillars (`plugins/foundry/knowledge/pillars/`), first.

**Non-negotiable design stance:** the marketplace is deliberately **human-gated** for risky change (never
self-merge; reviewers gate every transition). "Self-healing" here means *earlier detection, real diagnosis,
and the safe auto-wiring of **idempotent, non-destructive** things* (a browser path, a canonical re-sync on
a clean tree, a bounded retry) — **not** removing human judgement from destructive operations (auto-revert,
dependency auto-pin, merge). Every item states which side of that line it sits on, and **"safe-auto" is only
earned once the heal VERIFIES its own result** (a heal that can silently leave a broken state is not safe).

**Scope note (from review):** the marketplace is **eight** plugins — `i2p` (front door), `concierge`
(greeter/HUD), `foundry`, `sentinel`, `pressroom`, `atelier`, `ideator`, `market-scanner`. The first draft
addressed almost only `foundry`; this revision adds a cross-plugin batch (§5 P1-B) covering the front-door,
the statusline instruments, the hook substrate, and the marketplace's own supply-chain/security.

---

## 2 · The incident — a WORKED EXAMPLE of the gap

A browser-driven docs workflow burned avoidable time because **multiple tools each discover a browser
differently**, and all were mis-wired to a Chromium that was *already on disk in several places*:

| Tool | How it finds a browser | Marketplace-shipped? | Why it failed |
|---|---|---|---|
| `mmdc` (mermaid-cli → puppeteer) | a *pinned* Chrome revision under `~/.cache/puppeteer` | **yes** (pressroom uses `mmdc`) | the pinned revision was absent; `/usr/bin/chromium` was present |
| Playwright MCP (`npx @playwright/mcp`) | a slot under `~/.cache/ms-playwright` (incl. `mcp-chromium-<hash>/`) | **yes** (`atelier`, `foundry` `.mcp.json`) | the slot was an **empty stub dir**; the real browser sat in a sibling slot |
| chrome-devtools MCP | hardcoded `/opt/google/chrome/chrome` | **NO — host-session artifact, not shipped here** | only `chromium` exists on the box |

**The marketplace owns exactly two of these resolvers** (mmdc/puppeteer and the Playwright MCP); the
chrome-devtools row is included only to show the *pattern*, and is out of scope for any marketplace fix.

**The false green.** `/<plugin>:check`'s `chromium` row probes presence
(`npx --no-install playwright install --dry-run chromium … || command -v chromium …`). It returns **✓** — a
working Chromium *is* present — while every *consumer* of it fails. **A presence probe is not a capability
probe.** This is the highest-leverage lesson in the plan.

**The behavioural failure (the agent's).** Having *just* rendered with `mmdc` pointed at `/usr/bin/chromium`
— proof a browser existed — I reached for **install a fresh browser** when the Playwright MCP said "not
installed," instead of re-pointing it at the browser I'd already found. The 5-second diagnosis
(`ls ~/.cache/ms-playwright` → empty stub) was skipped.

**Ledger entry** — to be added to the **domain ledger that owns browser tooling**, i.e. the new
`plugins/foundry/knowledge/tooling/headless-browser.md` (§5 P0-5). Per
`plugins/foundry/knowledge/protocols/guardrails-ledger.md`, that file is a *pattern* with **no entries** —
"domain ledgers live with the skill that owns the domain" — so this entry goes in the tooling doc, **not**
into the pattern file:

```
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
```

---

## 3 · The self-healing maturity model

1. **DETECT** — notice the degraded state. (Strong today.)
2. **DIAGNOSE** — identify the *specific* cause.
3. **HEAL** — repair automatically *only when safe and idempotent*.
4. **VERIFY** — confirm the repair worked (the heal isn't done until it proves itself).
5. **PREVENT** — fold a guardrail upstream so the class can't recur (waste-elimination pillar).

Current centre of gravity: mostly **DETECT** + graceful-degrade, with a few DETECT+HEAL islands and
RECOVER/RESUME mechanisms. The opportunity is to lift the common, safe cases to **HEAL/VERIFY/PREVENT**.

---

## 4 · What already self-heals (credit before extending)

(Class: **D** detect-only · **D+H** detect-and-heal · **R** recover/resume.)

| Mechanism | Where | Class |
|---|---|---|
| `scripts/verify-prereqs.sh` (CI `verify.yml`) — checks **A** check.sh parity · **B** tsv 4-TAB-field well-formed · **C** `.mcp.json`↔`PREREQUISITES/40-mcp.md` parity · **D** no-download probe rule (`npx -y`/`uvx`…) over `PREREQUISITES/*.md` · **E** SOUL.md parity (root+8) · **F** inject-soul.sh parity | repo root | **D** (CI gate) |
| flaky-test-fixer (edits + commits within the gate) | `plugins/foundry/agents/flaky-test-fixer.md` | **D+H** |
| coverage-loop + `IN_PROGRESS.md` disaster-recovery | `plugins/foundry/agents/coverage-loop-agent.md` | **R** |
| self-improve (per plugin) — reflect → cleave/reference → branch → pr-review → PR | `plugins/*/skills/self-improve` | **D+H** (human-gated merge) |
| inspector (per plugin) — drift/portability/canonical-copy/manifest audit | `plugins/*/agents/inspector.md` | **D** |
| scorecard — disk-measured product + marketplace health series | `plugins/foundry/skills/scorecard` | **D** |
| SOUL injection dedup (idempotent, once per session across 8 plugins) | `plugins/*/hooks/inject-soul.sh` | **R** |
| phase-sensor — detect phase, auto-install next skill (idempotent) | `plugins/foundry/skills/phase-sensor` | **R** |
| lifecycle-orchestrator loop-state + NEEDS_REVISION≤3 escalation | `plugins/foundry/agents/lifecycle-orchestrator.md` | **R** |
| graceful enhancement — companions by **capability**, degrade when absent | `plugins/foundry/VALUE_FLOW.md` §4 | **R/D** |
| dependency-audit — vulns/unpinned/abandoned/typosquat (static fallback) | `plugins/sentinel/skills/dependency-audit` | **D** |
| merge-governance + pr-review — always-on adversarial gate | `plugins/foundry/...` | gating |
| context-sentinel / handoff-schema — resumable phase state | `plugins/foundry/knowledge/protocols/` | **R** |
| guardrails-ledger (pattern; domain ledgers live with their skill) | `plugins/foundry/knowledge/protocols/guardrails-ledger.md` | **PREVENT** |

**Takeaway:** detection + CI integrity are strong (`verify-prereqs.sh` is the spine). Gaps are (a)
**capability** vs presence, (b) **HEAL** where safe, (c) **runtime** resilience, and (d) **non-foundry**
surfaces (hooks, HUD, front-door, the marketplace's own supply chain).

---

## 5 · The opportunity register

Per item: **gap · current · proposed (stage) · owner · safe-auto? · prevention**.

### P0 — Environment & tool wiring (the incident's class; highest leverage)

**P0-1 · Capability probes, not presence probes.**
*Gap:* browser/render `check` rows pass on `command -v` while the consumer can't launch (§2). *Current:*
presence-only; `verify-prereqs.sh` check D forbids downloading probes **but only scans `PREREQUISITES/*.md`,
not the tsv** — so the tsv is unguarded. *Proposed (DETECT→VERIFY):* strengthen the **probe command** (no
schema change — check B requires exactly 4 TAB fields) so the row exercises capability **without
downloading**, and the probe must **export the resolver first** or it false-negatives on a box that *has* a
browser (review CORRECTNESS H2). Add a `verify-prereqs.sh` invariant that capability rows stay no-download.
Keep capability probes on **`optional` tier or behind a `--deep` flag** — they spawn a render and slow
`/check`. *Owners (per-plugin — there is no canonical tsv):* `plugins/pressroom/.../requirements.tsv` (mmdc),
`plugins/atelier` + `plugins/foundry` (chromium). *Safe-auto:* yes (detection). *Prevention:* CI invariant.

```sh
# pressroom mmdc row — exports the resolver, then renders; strictly no-download:
mmdc	bash -c 'command -v mmdc || exit 1; export PUPPETEER_EXECUTABLE_PATH="${PUPPETEER_EXECUTABLE_PATH:-$(command -v chromium||command -v chromium-browser||command -v google-chrome)}"; mmdc -i <(printf "flowchart LR\n a-->b") -o "$(mktemp --suffix=.svg)" >/dev/null 2>&1'	optional	npm i -g @mermaid-js/mermaid-cli
```

**P0-2 · One browser resolver, not two (env single-source-of-truth).**
*Gap:* mmdc/puppeteer and the Playwright MCP discover browsers independently. *Current:* `.mcp.json` ships
`env: {}`; no shared resolution; paths are machine-specific so nothing can be hardcoded in a shipped file
(capability-not-path). *Proposed (DIAGNOSE→HEAL):* document one env set, resolved at setup time by
`ensure-browser.sh` (P0-3) into the user's shell/CI env — never baked into `.mcp.json`:

```sh
export PUPPETEER_EXECUTABLE_PATH="$(command -v chromium||command -v chromium-browser||command -v google-chrome)"
export PUPPETEER_SKIP_DOWNLOAD=1
export PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-$HOME/.cache/ms-playwright}"
```

*Owner:* `PREREQUISITES/40-mcp.md` + `scripts/ensure-browser.sh`. *Safe-auto:* yes (env only).

**P0-3 · `scripts/ensure-browser.sh` — idempotent HEAL that VERIFIES (corrected per review CRITICAL).**
*Gap:* an empty consumer slot is never repaired; agents reinstall. *Proposed (DETECT→HEAL→VERIFY):* find any
real browser → export env (P0-2) → **atomically replace an empty ms-playwright stop slot** (glob must include
`mcp-chromium-*`; replace the *slot dir*, with a self-loop guard) → **verify the healed slot launches**
(not just any browser). `--check` diagnoses; `--fix` repairs. **Not safe-auto until the healed path
verifies.** The first draft's sketch nested the symlink and missed the real slot — fixed here:

```sh
chrome="$(command -v chromium||command -v chromium-browser||command -v google-chrome||true)"
[ -n "$chrome" ] || { echo "no system browser; run: npx playwright install --with-deps chromium"; exit 3; }
export PUPPETEER_EXECUTABLE_PATH="$chrome" PUPPETEER_SKIP_DOWNLOAD=1
root="${PLAYWRIGHT_BROWSERS_PATH:-$HOME/.cache/ms-playwright}"
real="$(dirname "$(ls -d "$root"/*chromium*/chrome-linux/chrome 2>/dev/null | head -1)")"   # a POPULATED slot
for slot in "$root"/*chromium*/chrome-linux; do                 # *chromium* matches mcp-chromium-<hash> too
  [ -e "$slot/chrome" ] && continue                             # already good
  [ -n "$real" ] && [ -e "$real/chrome" ] || break
  case "$real" in "$slot"*) continue;; esac                     # self-loop guard
  rm -rf "$slot" && ln -sfn "$real" "$slot"                     # atomically replace the empty stub DIR
  "$slot/chrome" --headless=new --dump-dom about:blank >/dev/null 2>&1 \
    && echo "healed+verified: $slot" || echo "WARN: $slot still not launchable — manual install needed"
done
```

*Owner:* `scripts/`. *Safe-auto:* yes **only on verified slots**; otherwise report. *Prevention:* TC-BROWSER-1.
*(Vendor the detect logic here as canon; do not point at any external repo — review flagged a dead
`skillsentry/scripts/render-diagrams.sh` cross-repo reference, which violates capability-not-path.)*

**P0-4 · `/foundry:prerequisites --fix` — thin dispatcher (not a fat omni-repair).**
*Gap:* `prerequisites` is generate-and-stamp only. *Proposed (HEAL):* a `--fix` that **dispatches to each
plugin's own already-shipped safe heal** (ensure-browser, env export, canonical re-sync) and re-stamps
status — it must not become one switch coupling unrelated heals of differing risk (SOLID). *Owner:*
`plugins/foundry/skills/prerequisites`. *Safe-auto:* yes (only idempotent, verified sub-heals).

**P0-5 · Agent self-heal reflex + browser-tooling domain ledger (the behavioural fix).**
*Proposed (PREVENT):* new `plugins/foundry/knowledge/tooling/headless-browser.md` carrying TC-BROWSER-1 and
a `THE ONLY WAY` rule — *"on 'browser not installed', locate an existing browser and re-point the tool;
never install before diagnosing; a sibling render proves the browser exists."* **Referenced (not restated)**
by `atelier/ui-review`, `atelier/mockup`, `pressroom/rich-pdf-with-diagrams`, and foundry story phases.

**P0-6 · Document the (two marketplace) discovery mechanisms** in `PREREQUISITES/40-mcp.md` (which today
documents none) so the failure is recognisable. *(Docs only.)*

### P1-A — Integrity & data self-heal (extend `verify-prereqs.sh` from DETECT to guarded HEAL)

| # | Gap | Proposed (stage) | Owner | Safe-auto? |
|---|---|---|---|---|
| P1-1 | Canonical copies drift (check.sh/SOUL.md/inject-soul.sh) | `--fix` re-syncs from the **named canonical source** (root `SOUL.md`; the designated check.sh) — **refuse on a dirty tree, print a diff, never re-sync away an intentional divergence** (review SAFETY) | `verify-prereqs.sh` | yes, **guarded** |
| P1-2 | `marketplace.json` ↔ plugin-set/version drift; orphan dirs/entries | CI invariant: `ls plugins/` ↔ `marketplace.json[].name`, versions/keywords consistent across the four mirrors | `verify-prereqs.sh` | detect-auto |
| P1-3 | Broken refs — agent `tools:`, knowledge links, **and `/command` tokens in hooks/tips/README** | CI ref-resolver across all plugins incl. hook-embedded command strings (review M7) | `verify-prereqs.sh` | detect-auto |
| P1-4 | Plugin-cache staleness (installed cache lags repo) | SessionStart advisory: cache version vs marketplace.json → suggest `/plugin marketplace update` | a plugin hook | detect-auto |
| P1-5 | **Scorecard `jq -rs` slurp zeroes ALL metrics on one bad line; ignores `MARKETPLACE_SCORECARD.jsonl`** (review C2) | parse **line-wise** (`grep -v '^$' \| jq -c . 2>/dev/null \| tail -1`), skip corrupt lines with a warning, **across BOTH series** | `plugins/foundry/skills/scorecard/scripts/*.sh` | yes (skip+warn) |
| P1-6 | ROADMAP status ↔ sentinel-state divergence | phase-sensor cross-check: COMPLETE ↔ DELIVERY_COMPLETE; warn on mismatch | `plugins/foundry/skills/phase-sensor` | detect-auto |
| P1-7 | DEGRADED_CAPABILITIES signal is undefined but three items depend on it | **define-first**: shape + emit-point + consumer contract in `knowledge/protocols/` before P1-B-runtime items ship (review FEAS) | `plugins/foundry/knowledge/protocols/` | n/a (spec) |

### P1-B — Cross-plugin & instrument self-heal (the classes the first draft missed — review COMPLETENESS)

| # | Gap | Proposed (stage) | Owner | Safe-auto? |
|---|---|---|---|---|
| P1-8 | **Hook failures swallowed forever by `2>/dev/null \|\| true`** — a dead `inject-soul`/`check-phase`/`capture-cost` is undetectable (review C1, CRITICAL) | hooks write a heartbeat/last-error sentinel under `~/.claude/hook-state/`; a SessionStart (or `verify-prereqs.sh`) smoke-exec of each hook against a fixture flags non-zero exits | `plugins/*/hooks/` + verify | detect-auto |
| P1-9 | **Statusline canonical copy in `~/.claude/statusline-command.sh` drifts** from the shipped renderer — escapes the repo, no re-sync (review H3) | version-stamp the renderer; SessionStart compares installed vs shipped, offers `/concierge:statusline` refresh | `plugins/concierge/statusline` | yes (offer) |
| P1-10 | **Shipped MCP deps unpinned (`@playwright/mcp@latest`, unversioned `context7`/`fetch`/`semgrep`)** — supply-chain/reproducibility (review H4) | CI invariant: `.mcp.json` args carry a pinned version; run sentinel typosquat/abandoned over the MCP package set (dogfood) | `plugins/*/.mcp.json` + verify | detect-auto |
| P1-11 | **Marketplace runs no secret/PII self-audit of itself** (cobbler's children — review H5) | add a `sentinel:secret-scan` (+ pii) job to `verify.yml` over the tree/history | `.github/workflows/` | detect-auto |
| P1-12 | **Git-state hygiene** — merged-but-undeleted branches, orphaned worktrees (the exact class from this session — review H6) | delivery-phase advisory lists stale branches/worktrees and **proposes** cleanup (never auto-deletes) | `plugins/foundry` delivery | **no** (propose) |
| P1-13 | **HUD instruments narrow silently** — `count-adversarial-catches.sh` hard-codes review-artifact filenames; new reviewers never count (review M8) | derive the artifact-name set from a single shared list, or CI-assert it matches reviewers' declared outputs | `plugins/concierge/statusline` | detect-auto |
| P1-14 | **`concierge`/`i2p` have no `/check` or inspect-backed self-heal entry** — two whole plugins outside every integrity loop (review L13) | give the front-door/greeter a check surface (or fold into i2p-check) and an inspector pass | `plugins/{i2p,concierge}` | detect-auto |

### P1-C — Run-time resilience (depends on P1-7 signal)

| # | Gap | Proposed (stage) | Safe-auto? |
|---|---|---|---|
| P1-15 | Tool/MCP unavailable at point-of-use (not just session start) | agents emit `DEGRADED_CAPABILITIES`; downstream skips route around it and disclose | detect-auto |
| P1-16 | Headless/CI runs where MCPs can't spawn | `headless_capable` note in PREREQUISITES; phase-sensor routes to headless-safe phases | detect-auto |
| P1-17 | Scorecard can't tell "0 findings" from "lens didn't run" | read `DEGRADED_CAPABILITIES`; mark coverage **partial**, never a silent PASS | yes (label) |
| P1-18 | Transient failures (timeout/ECONNRESET) end a run | `--retries=N` with backoff on classified-transient errors only | yes (bounded) |
| P1-19 | Lint/format failure halts the gate for trivial style | auto-format **changed files only**, assert the post-format diff ⊆ touched files, separate commit, then re-run (review SAFETY) | yes (scoped) |
| P1-20 | Rate-limit/token-budget exhaustion mid-run just halts (data already on the HUD, unused) | when `rate_limits.*.used_percentage` crosses a threshold, orchestrator emits `CHECKPOINT_<phase>.md` and pauses rather than dying mid-write (review M10) | yes (checkpoint) |

### P2 — Quality & lifecycle self-heal (mostly detect-and-propose; risky heals stay human-gated)

| # | Gap | Proposed | Safe-auto? |
|---|---|---|---|
| P2-1 | Coverage regression vs history undetected | scorecard retains last-N baselines; flag a drop with no pragma justification | detect-auto |
| P2-2 | Catastrophic regression (coverage ⟂, tests fail) | **propose** revert with prior-good SHA — never auto-revert | **no** |
| P2-3 | Frozen spec (EARS/.feature) changed without a DISCUSS sentinel | commit-scan gate halts merge with guidance | detect-auto |
| P2-4 | Reviewer role / handler referenced but unregistered | builder-lead pre-flight cross-checks roster; degrade or warn | detect-auto |
| P2-5 | Sentinel-chain gap halts with no diagnostics | emit "missing X; recent steps …; to proceed run Y" + log to IN_PROGRESS.md | detect-auto |
| P2-6 | Same reviewer rejects same stage twice | on 2nd identical NEEDS_REVISION, emit root-cause diagnostic + escalate | detect-auto |
| P2-7 | Cyclic dependency in decomposition | builder-lead topological-sorts items; halt on cycle | detect-auto |
| P2-8 | No pause/resume checkpoint outside coverage-loop | each phase emits `CHECKPOINT_<phase>.md` | yes |
| P2-9 | IDEA_COST anomalies never investigated | builder-lead flags high-variance items → handler-architect | detect-auto |
| P2-10 | Unpinned/abandoned deps re-warned, never fixed | dependency-audit **proposes** a pinned-version PR — human merges | **no** |
| P2-11 | Stale mock vs live API contract drift | story phase asserts mock schema vs spec when present | detect-auto |
| P2-12 | New cleaved agent/skill missing docs/glossary entry | self-improve auto-stubs docs + glossary on cleave | yes (stub) |
| P2-13 | **Agents restate canon (the reverse-dependency self-architecture calls "the one thing to fix")** has no detector (review M9) | detector for canon prose (model-tier table, test contract) in agent files lacking a certainty-marker reference; surface as a scorecard trend | detect-auto |
| P2-14 | **LSP capability unverified** — same presence-vs-capability gap as the browser, generalised (review L12) | a capability-grade LSP probe row (does the server actually respond) | detect-auto |
| P2-15 | Deployed-artifact version ↔ DELIVERY_COMPLETE mismatch | VERIFY records deployed digest; flag mismatch | detect-auto |
| P2-16 | Stacked PRs stranded when a base merges | retarget-to-main guard wired into the delivery step | detect-auto |

> **Count:** 6 P0 + 7 P1-A + 7 P1-B + 6 P1-C + 16 P2 = **42 concrete items**, spanning the env/wiring,
> integrity/data, cross-plugin/instrument, runtime, and quality/lifecycle classes. The cross-plugin batch
> (P1-B) and the runtime-signal define-first item (P1-7) were added in revision after the completeness lens
> proved the first draft was foundry-centric.

---

## 6 · The prevention layer

- **Domain ledgers, not the pattern file.** `guardrails-ledger.md` is the *pattern* (symptom→cause→fix,
  stable IDs) and holds **no entries** by design — "domain ledgers live with the skill that owns the
  domain." Put TC-BROWSER-1 in `knowledge/tooling/headless-browser.md` (P0-5); put each future class in its
  owning skill's ledger. Reference the pattern file; don't append to it.
- **`scripts/verify-prereqs.sh` is the home for new invariants** (it already enforces canonical-copy parity
  and the no-download-probe rule). Every P1-A/P1-B integrity item adds a check, and a guarded `--fix` where
  the repair is safe and self-verifying.
- **PREVENT is the definition-of-done for each item:** not closed until the class can't silently return — a
  CI invariant, a ledger entry, or a referenced `THE ONLY WAY` rule.

---

## 7 · Sequencing & ownership

1. **P0 first** — fixes the incident class, near-entirely safe-auto, unblocks browser/render "out of the
   box." Order: P0-1 → P0-3 → P0-2 → P0-5 → P0-4 → P0-6.
2. **P1-A integrity** (cheap CI extensions) and **P1-B cross-plugin** (the missed classes; P1-8 hook-health
   and P1-5 scorecard-slurp are the two highest-severity — do them early).
3. **P1-7** (define `DEGRADED_CAPABILITIES`) **before** P1-C runtime items. Then **P1-C**, then **P2**.

Each item ships as its own `/<plugin>:self-improve <target>` → `/foundry:pr-review` → PR (pr-approval),
honouring the four-mirror guardrail + version bump on any skill change. Re-run the relevant
`/<plugin>:inspect` and `/foundry:scorecard` after each to record the closed-finding trend.

---

## 8 · Adversarial review log

A five-lens panel (COMPLETENESS, CORRECTNESS, ARCHITECTURE-FIT, FEASIBILITY, SAFETY), refute-not-rubber-stamp,
mirroring `/foundry:pr-review`, reviewed the first draft. **Verdict: NEEDS_REVISION** (1 CRITICAL + several
HIGH). All applied:

- **[CRITICAL · FEASIBILITY/SAFETY]** `ensure-browser.sh` stub-heal nested the symlink (`ln -sfn` into an
  existing dir), missed the real `mcp-chromium-*` slot, and reported a false-green heal. → **Rewrote P0-3**:
  glob `*chromium*`, atomic `rm -rf` + replace the slot dir, self-loop guard, verify the *healed* path
  launches; "safe-auto only on verified slots."
- **[CRITICAL · COMPLETENESS]** First draft was foundry-centric (foundry ×31; i2p/concierge/ideator/
  market-scanner ×0) and missed ~7 whole classes. → **Added P1-B** (hooks, statusline, MCP pinning,
  marketplace secret/PII CI, git-hygiene, HUD instruments, concierge/i2p coverage) + P2-13/P2-14.
- **[CRITICAL · COMPLETENESS]** scorecard `jq -rs` slurp zeroes *all* metrics on one bad line and ignored
  `MARKETPLACE_SCORECARD.jsonl`. → **Rewrote P1-5** (line-wise parse, both series).
- **[HIGH · CORRECTNESS/ARCH]** `chrome-devtools` MCP isn't marketplace-shipped; "three resolvers" overclaim.
  → **Fixed §2 table + scoped to two marketplace resolvers.**
- **[HIGH · CORRECTNESS]** P0-1 probe false-negatives without `PUPPETEER_EXECUTABLE_PATH`. → **export-first
  probe**; capability probes kept `optional`/`--deep`; noted check D doesn't cover the tsv.
- **[HIGH · CORRECTNESS]** `requirements.tsv` is **per-plugin**, not canonical. → **Corrected owners.**
- **[MEDIUM · CORRECTNESS/ARCH]** dead `skillsentry/scripts/render-diagrams.sh` cross-repo pointer (a
  capability-not-path violation). → **Removed; vendor the detect logic as canon in P0-3/P0-5.**
- **[MEDIUM · CORRECTNESS]** guardrails-ledger is a pattern with zero entries. → **§2/§6 corrected**: entry
  goes in the domain ledger, not the pattern file.
- **[MEDIUM/LOW · SAFETY]** canonical re-sync could discard an intentional divergence; auto-format could
  touch unrelated files. → **P1-1 guarded (refuse-on-dirty, diff, named source); P1-19 scoped to changed
  files.**
- **[LOW · FEASIBILITY]** `DEGRADED_CAPABILITIES` underspecified. → **Added define-first P1-7**, sequenced
  before P1-C.
- **[LOW · ARCH]** `--fix` risked becoming a fat omni-repair. → **P0-4 reframed as a thin dispatcher.**

Post-revision self-assessment against the same lenses: **PASS** — claims now match the repo, the flagship
heal is correct and self-verifying, the human-gated line is preserved, and the previously-omitted classes
are covered. Residual known-unknowns: items are scoped but not yet implemented; the maintainers' own
`/foundry:pr-review` on each implementing PR is the binding gate.

---

## 9 · Non-goals & honesty

- **No plugin code/config is changed by this PR** — this is a plan. Reference sketches are illustrative.
- **The human-gated stance is preserved.** Destructive heals (auto-revert P2-2, dep auto-pin P2-10, git
  cleanup P1-12, any merge) stay *detect-and-propose*. Only idempotent, **self-verifying** repairs are
  proposed safe-auto.
- **References, not restatements.** Where this names a pillar/protocol/convention, the canonical text lives
  in `plugins/foundry/knowledge/…` — follow the link, don't trust a paraphrase here.

*Light is green, trap is clean — hand this to the maintainers and we are go.* 🛸
