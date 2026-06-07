# I2P_SELF_HEALING_PLAN — making the marketplace heal itself

> **⚠️ Transient coordination document, not part of the marketplace.** Like `REVIEW_ACTION_PLAN.md`,
> this is a backlog for maintainers to schedule. When every item is shipped or consciously dismissed,
> delete it: `git rm I2P_SELF_HEALING_PLAN.md`.
>
> **Governance — two distinct things, do not conflate (see §7):** (1) the *product invariant* — the
> marketplace's **shipped** self-improve **never self-merges** (`/<plugin>:self-improve` → `/foundry:pr-review`
> → a human merges; `plugins/foundry/knowledge/protocols/merge-governance.md` governs the *product*). (2) the
> *maintainer workflow* — this repo ships **direct-to-main in batches**, each batch honouring, in the same
> commit, the **four-mirror guardrail** (`REVIEW_ACTION_PLAN.md`: a skill change ⇒ update `plugin.json` + the
> `marketplace.json` entry + `README.md` + `skills/check/requirements.tsv` + bump the version — now
> CI-enforced by **P1-21**), and a **`/foundry:pr-review base..head` PASS over the local diff** (no GitHub PR
> required). The human-gated stance survives; the per-item-PR ceremony does not.
>
> **Authored 2026-06-07; revised twice (§8).** First a five-lens panel refuted the foundry-centric first
> draft. Then (this revision) re-triaged against the current tree — the marketplace grew to **nine** plugins
> (`mission-control`) since authoring — with **10 new items folded in and re-reviewed to PASS**.
>
> **▶ Implementation progress (the loop).** Each batch ships direct-to-main, demonstrably verified, then is
> marked ✅ here; the file is `git rm`'d when all 52 are ✅.
> - **P0 — DONE (`eb7783f`, `276c1e2`):** ✅ P0-1..P0-7 (browser/env self-heal: `ensure-browser.sh`
>   heals+verifies the real ms-playwright stub; no-download rule covers tsv probes; `mmdc` capability probe;
>   `headless-browser.md` ledger; `/foundry:prerequisites --fix` dispatcher).
> - **P1-A — DONE:** ✅ P1-1 (verify-prereqs `--fix`, guarded) ✅ P1-2 (check H marketplace drift) ✅ P1-3
>   (check I broken-refs) ✅ P1-4 (cache-staleness advisory) ✅ P1-5 (scorecard line-wise parse) ✅ P1-6
>   (phase-sensor roadmap↔sentinel) ✅ P1-7 (`DEGRADED_CAPABILITIES` contract) ✅ P1-23 (lifecycle.json
>   corrupt-state validation).
> - **Remaining:** P1-B (9) · P1-C (8) · P2 (20) = **37 items** (15/52 shipped).

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

**Scope note:** the marketplace is **nine** plugins — `i2p` (front door), `concierge` (greeter/HUD),
`foundry`, `sentinel`, `pressroom`, `atelier`, `ideator`, `market-scanner`, and **`mission-control`** (the
OPERATE-phase owner: observability/incident/maintain/iterate/operate-gate, with its own check + inspector).
The first draft addressed almost only `foundry`; the cross-plugin batch (§5 P1-B) covers the front-door, the
statusline instruments, the hook substrate, the marketplace's own supply-chain/security, and now the OPERATE
runtime surface mission-control owns.

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
| `scripts/verify-prereqs.sh` (CI `verify.yml`) — checks **A** check.sh parity · **B** tsv 4-TAB-field well-formed · **C** `.mcp.json`↔`PREREQUISITES/40-mcp.md` parity · **D** no-download probe rule (`npx -y`/`uvx`…) over `PREREQUISITES/*.md` · **E** SOUL.md parity (root+9, counted dynamically via `find`) · **F** inject-soul.sh parity | repo root | **D** (CI gate) |
| flaky-test-fixer (edits + commits within the gate) | `plugins/foundry/agents/flaky-test-fixer.md` | **D+H** |
| coverage-loop + `IN_PROGRESS.md` disaster-recovery | `plugins/foundry/agents/coverage-loop-agent.md` | **R** |
| self-improve (per plugin) — reflect → cleave/reference → branch → pr-review → PR | `plugins/*/skills/self-improve` | **D+H** (human-gated merge) |
| inspector (per plugin) — drift/portability/canonical-copy/manifest audit | `plugins/*/agents/inspector.md` | **D** |
| scorecard — disk-measured product + marketplace health series | `plugins/foundry/skills/scorecard` | **D** |
| SOUL injection dedup (idempotent, once per session across 9 plugins) | `plugins/*/hooks/inject-soul.sh` | **R** |
| phase-sensor — detect phase, auto-install next skill (idempotent) | `plugins/foundry/skills/phase-sensor` | **R** |
| lifecycle-orchestrator loop-state + NEEDS_REVISION≤3 escalation | `plugins/foundry/agents/lifecycle-orchestrator.md` | **R** |
| graceful enhancement — companions by **capability**, degrade when absent | `plugins/foundry/VALUE_FLOW.md` §4 | **R/D** |
| dependency-audit — vulns/unpinned/abandoned/typosquat (static fallback) | `plugins/sentinel/skills/dependency-audit` | **D** |
| merge-governance + pr-review — always-on adversarial gate | `plugins/foundry/...` | gating |
| context-sentinel / handoff-schema — resumable phase state | `plugins/foundry/knowledge/protocols/` | **R** |
| guardrails-ledger (pattern; domain ledgers live with their skill) | `plugins/foundry/knowledge/protocols/guardrails-ledger.md` | **PREVENT** |
| managed-welcome refresh — detect a stale phase-stamp → regenerate → re-stamp (recent work) | `plugins/concierge/hooks/offer-welcome.sh` + `skills/define-welcome` | **D+H** |
| mission-control OPERATE skills — observability/incident/maintain detect runtime degradation (no auto-heal yet) | `plugins/mission-control/skills/` | **D** |
| OPERATE↻DISCOVER cyclic re-entry — operate learnings re-open discovery (a feedback loop) | `plugins/i2p/skills/lifecycle/scripts/lifecycle.sh` | **R** |
| reviewer evidence + mandatory self-refutation (kills false-positive findings before they ship) | `plugins/foundry/agents/reviewer.md` | gating |

**Takeaway:** detection + CI integrity are strong (`verify-prereqs.sh` is the spine), and recent work added a
detect-and-heal island (the managed welcome) plus the OPERATE runtime surface (mission-control). Gaps remain:
(a) **capability** vs presence, (b) **HEAL/VERIFY** where safe, (c) **runtime** resilience — now co-ownable
by mission-control — and (d) **non-foundry** surfaces (hooks, HUD, front-door, the marketplace's own supply
chain).

---

## 5 · The opportunity register

Per item: **gap · current · proposed (stage) · owner · safe-auto? · prevention**.

### P0 — Environment & tool wiring (the incident's class; highest leverage)

**P0-1 · Capability probes, not presence probes — the CI invariant.**
*Gap:* a `/check` row can pass on mere presence while the consumer can't launch (§2). *Current (corrected on
re-triage):* the **chromium** rows in `atelier` + `foundry` already use a no-download capability-*ish* probe
(`npx --no-install playwright install --dry-run chromium 2>/dev/null || command -v chromium …`) — they are
**not** pure-presence (they could be strengthened to an actual headless render, but they are not the open
gap). The one **pure-`command -v`** row is `pressroom`'s **mmdc** — split out as **P0-7**. Separately,
`verify-prereqs.sh` **check D forbids downloading probes but only scans `PREREQUISITES/*.md`, not the tsv** —
so capability rows in the tsv are unguarded. *Proposed (DETECT→VERIFY):* add a `verify-prereqs.sh` invariant
that capability rows stay **no-download** (extend check D over the tsv, not just the markdown); the probe must
**export the resolver first** or it false-negatives on a box that *has* a browser; keep capability probes on
**`optional` tier / behind `--deep`** (they spawn a render and slow `/check`). *Owner:* `scripts/verify-prereqs.sh`
(the invariant); the per-plugin tsvs own their own rows. *Safe-auto:* yes (detection). *Prevention:* CI invariant.

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

**P0-7 · mmdc capability probe (split from P0-1 — the one real pure-presence row).**
*Gap:* `plugins/pressroom/skills/check/requirements.tsv`'s `mmdc` row is `command -v mmdc` — it passes when
the binary exists even if mmdc can't find a browser to render with. *Proposed (DETECT→VERIFY):* replace it
with a no-download capability probe that exports the resolver, then renders a trivial diagram to a temp file:
*Owner:* pressroom. *Safe-auto:* yes (detection); keep `optional`/`--deep`. *Prevention:* the P0-1 CI invariant.

```sh
# pressroom mmdc row — exports the resolver, then renders; strictly no-download:
mmdc	bash -c 'command -v mmdc || exit 1; export PUPPETEER_EXECUTABLE_PATH="${PUPPETEER_EXECUTABLE_PATH:-$(command -v chromium||command -v chromium-browser||command -v google-chrome)}"; mmdc -i <(printf "flowchart LR\n a-->b") -o "$(mktemp --suffix=.svg)" >/dev/null 2>&1'	optional	npm i -g @mermaid-js/mermaid-cli
```

### P1-A — Integrity & data self-heal (extend `verify-prereqs.sh` from DETECT to guarded HEAL)

| # | Gap | Proposed (stage) | Owner | Safe-auto? |
|---|---|---|---|---|
| P1-1 | Canonical copies drift (check.sh/SOUL.md/inject-soul.sh) | `--fix` re-syncs from the **named canonical source** (root `SOUL.md`; the designated check.sh) — **refuse on a dirty tree, print a diff, never re-sync away an intentional divergence** (review SAFETY) | `verify-prereqs.sh` | yes, **guarded** |
| P1-2 | `marketplace.json` ↔ plugin-set/version drift; orphan dirs/entries | CI invariant: `ls plugins/` ↔ `marketplace.json[].name`, versions/keywords consistent across the four mirrors | `verify-prereqs.sh` | detect-auto |
| P1-3 | Broken refs — agent `tools:`, knowledge links, **and `/command` tokens in hooks/tips/README** | CI ref-resolver across all plugins incl. hook-embedded command strings (review M7) | `verify-prereqs.sh` | detect-auto |
| P1-4 | Plugin-cache staleness (installed cache lags repo) | SessionStart advisory: cache version vs marketplace.json → suggest `/plugin marketplace update` | a plugin hook | detect-auto |
| P1-5 | **Scorecard `jq -rs` slurp on `IDEA_COST.jsonl` zeroes ALL metrics on one bad line** (`scorecard.sh:55,66-69`). *Re-triage split:* the "ignores `MARKETPLACE_SCORECARD.jsonl`" half is **STALE** — `marketplace-score.sh` uses `jq -nc` (no slurp) and the ledger is now tracked + appended | parse the IDEA_COST reads **line-wise** (`grep -v '^$' \| jq -c . 2>/dev/null \| tail -1`), skip corrupt lines with a warning — **`scorecard.sh` only** | `plugins/foundry/skills/scorecard/scripts/scorecard.sh` | yes (skip+warn) |
| P1-6 | ROADMAP status ↔ sentinel-state divergence | phase-sensor cross-check: COMPLETE ↔ DELIVERY_COMPLETE; warn on mismatch | `plugins/foundry/skills/phase-sensor` | detect-auto |
| P1-7 | DEGRADED_CAPABILITIES signal is undefined but three items depend on it | **define-first**: shape + emit-point + consumer contract in `knowledge/protocols/` before P1-B/P1-C runtime items ship (review FEAS) — **co-authored with mission-control** (it emits the signal) | `plugins/foundry/knowledge/protocols/` + mission-control | n/a (spec) |
| **P1-23** | **`.i2p/lifecycle.json` corrupt-state silently read as "no phases"** — `lifecycle.sh`'s `jq -r '.current_phase // empty' … 2>/dev/null` swallows a parse error, so a truncated state file = silent data loss (new, re-triage) | validate JSON on read; distinguish **corrupt** from **absent**; emit a repair hint, never treat corrupt as no-phases | `plugins/i2p/skills/lifecycle` + `verify-prereqs.sh` | detect-auto |

### P1-B — Cross-plugin & instrument self-heal (the classes the first draft missed — review COMPLETENESS)

| # | Gap | Proposed (stage) | Owner | Safe-auto? |
|---|---|---|---|---|
| P1-8 | **Hook failures swallowed forever by `2>/dev/null \|\| true`** — a dead `inject-soul`/`check-phase`/`capture-cost` is undetectable (review C1, CRITICAL) | hooks write a heartbeat/last-error sentinel under `~/.claude/hook-state/`; a SessionStart (or `verify-prereqs.sh`) smoke-exec of each hook against a fixture flags non-zero exits | `plugins/*/hooks/` + verify | detect-auto |
| P1-9 | **Statusline canonical copy in `~/.claude/statusline-command.sh` drifts** from the shipped renderer — **CONFIRMED LIVE this re-triage**: installed md5 ≠ shipped (the recent cycle-indicator edit never propagated). One of the two highest-severity P1-B items | version-stamp the renderer; SessionStart compares installed vs shipped, offers `/concierge:statusline` refresh | `plugins/concierge/statusline` | yes (offer) |
| P1-10 | **Shipped MCP deps unpinned (`@playwright/mcp@latest`, unversioned `context7`/`fetch`/`semgrep`)** — supply-chain/reproducibility (review H4) | CI invariant: `.mcp.json` args carry a pinned version; run sentinel typosquat/abandoned over the MCP package set (dogfood) | `plugins/*/.mcp.json` + verify | detect-auto |
| P1-11 | **Marketplace runs no secret/PII self-audit of itself** (cobbler's children — review H5) | add a `sentinel:secret-scan` (+ pii) job to `verify.yml` over the tree/history | `.github/workflows/` | detect-auto |
| P1-12 | **Git-state hygiene** — merged-but-undeleted branches, orphaned worktrees (the exact class from this session — review H6) | delivery-phase advisory lists stale branches/worktrees and **proposes** cleanup (never auto-deletes) | `plugins/foundry` delivery | **no** (propose) |
| P1-13 | **HUD instruments narrow silently** — `count-adversarial-catches.sh` hard-codes review-artifact filenames; new reviewers never count (review M8) | derive the artifact-name set from a single shared list, or CI-assert it matches reviewers' declared outputs | `plugins/concierge/statusline` | detect-auto |
| P1-14 | **`concierge` has no `/check` or inspector** — the one plugin outside every integrity loop (re-triage: i2p AND mission-control now have both; concierge is the lone outlier) | give the greeter/HUD a check surface (or fold into `i2p-check`) and an inspector pass | `plugins/concierge` | detect-auto |
| **P1-21** | **Four-mirror guardrail is relied on but never CI-enforced** — a skill can ship without its `plugin.json` / `marketplace.json` entry / `README` / `requirements.tsv` mirror updated; checks A–F don't assert it (new) | `verify-prereqs.sh` **check G**: for each `plugins/*/skills/*`, assert the *applicable* mirrors are present (per-artifact requirement + an exemption table, the pattern check D already uses) | `scripts/verify-prereqs.sh` | detect-auto |
| **P1-22** | **Concierge managed-welcome refresh has no write-verification** — `offer-welcome.sh` instructs a silent regenerate but nothing confirms the file was rewritten / re-stamped, so a stale stamp can persist (new — a gap in recent work) | after a managed refresh, **verify** the welcome carries a fresh `concierge:welcome for_phase=…cycle=…` stamp matching the lifecycle; on mismatch surface DEGRADED — **verify-and-disclose only, never auto-rewrite** | `plugins/concierge` | yes (verify) |

### P1-C — Run-time resilience (depends on P1-7 signal)

| # | Gap | Proposed (stage) | Safe-auto? |
|---|---|---|---|
| P1-15 | Tool/MCP unavailable at point-of-use (not just session start) | agents emit `DEGRADED_CAPABILITIES`; downstream skips route around it and disclose | detect-auto |
| P1-16 | Headless/CI runs where MCPs can't spawn | `headless_capable` note in PREREQUISITES; phase-sensor routes to headless-safe phases | detect-auto |
| P1-17 | Scorecard can't tell "0 findings" from "lens didn't run" | read `DEGRADED_CAPABILITIES`; mark coverage **partial**, never a silent PASS | yes (label) |
| P1-18 | Transient failures (timeout/ECONNRESET) end a run | `--retries=N` with backoff on classified-transient errors only | yes (bounded) |
| P1-19 | Lint/format failure halts the gate for trivial style | auto-format **changed files only**, assert the post-format diff ⊆ touched files, separate commit, then re-run (review SAFETY) | yes (scoped) |
| P1-20 | Rate-limit/token-budget exhaustion mid-run just halts (data already on the HUD, unused) | when `rate_limits.*.used_percentage` crosses a threshold, orchestrator emits `CHECKPOINT_<phase>.md` and pauses rather than dying mid-write (review M10) | yes (checkpoint) |
| **P1-24** | Mid-session **MCP crash undetected** — `check` only runs at invocation; a server that dies mid-session stays dead | SessionStart **liveness ping** of each declared MCP → emit `DEGRADED_CAPABILITIES` on no-response (detect-only, **never restart**). Lives in the **hook substrate** (survives a skill/MCP crash) | detect-auto |
| **P1-25** | **Stuck-phase / time-in-phase** undetected — a phase running far past budget is invisible | from `lifecycle.json.history[]` timestamps, flag a phase exceeding a budget; **propose**, never auto-advance | **no** (propose) |

> **Re-ownership (re-triage).** mission-control now owns the OPERATE phase, so P1-C runtime (P1-15…P1-20,
> P1-24/25) is **co-owned mission-control↔foundry** — mission-control owns the runtime/observability surface,
> foundry owns the scorecard/cost substrate it reads. **Critical safety fix (review):** to avoid mission-control
> *healing itself* (a crash would blind its own detector), the **detectors live in the SessionStart hook
> substrate** (the same layer as P1-8's heartbeat), not inside mission-control skills — mission-control owns the
> canon and the consumer; the detector survives the crash. Items **reference**
> `mission-control/knowledge/operate-canon.md`, never restate OPERATE semantics.

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
| **P2-17** | **Self-improve has no closed-loop regression measure** — "halve the distance to flawless" is eyeballed at PR time; the scorecard doesn't trend per-element finding counts (new) | scorecard retains per-inspector/per-reviewer finding counts across runs; self-improve **asserts the count dropped** (or warns it didn't) — closes the open verify step | foundry scorecard + mission-control | detect-auto |
| **P2-18** | **Cobbler's children** — the marketplace doesn't dogfood mission-control on ITSELF (no SLOs/golden-signals on its own runtime) (new) | run mission-control observability over the repo's own runtime as an **external CI job** (the P1-11 substrate — cross-references it as the security slice); surface marketplace health on the HUD | mission-control (external CI) | detect-auto |
| **P2-19** | **Incident postmortem action-items not tracked to completion** — `incident` writes them, nothing follows up (new) | record action-items to a tracked ledger; a detector flags un-closed/overdue ones as a re-entry signal | mission-control `incident`/`iterate` | detect-auto |
| **P2-20** | **`cost.json` is per-phase-flat, not cycle-aware** — across OPERATE↻DISCOVER a new cycle overwrites prior-cycle cost (new) | make cost accounting **cycle-indexed** (additive schema; readers default to cycle 1 when absent — no destructive migration) | mission-control + foundry scorecard | detect-auto (schema) |

> **Count:** 7 P0 + 8 P1-A + 9 P1-B + 8 P1-C + 20 P2 = **52 concrete items**, spanning the env/wiring,
> integrity/data, cross-plugin/instrument, runtime, and quality/lifecycle classes. The first revision grew
> the cross-plugin P1-B batch (foundry-centric → marketplace-wide); **this revision** (re-triage against the
> nine-plugin tree) added **P0-7, P1-21/22/23, P1-24/25, P2-17/18/19/20** — the four-mirror CI invariant, the
> OPERATE runtime surface, and the closed-loop / self-observability gaps recent work created.

---

## 6 · The prevention layer

- **Domain ledgers, not the pattern file.** `guardrails-ledger.md` is the *pattern* (symptom→cause→fix,
  stable IDs) and holds **no entries** by design — "domain ledgers live with the skill that owns the
  domain." Put TC-BROWSER-1 in `knowledge/tooling/headless-browser.md` (P0-5); put each future class in its
  owning skill's ledger. Reference the pattern file; don't append to it.
- **`scripts/verify-prereqs.sh` is the home for new invariants** (it already enforces canonical-copy parity
  and the no-download-probe rule). Every P1-A/P1-B integrity item adds a check — including **check G**, the
  four-mirror consistency invariant (P1-21) — and a guarded `--fix` where the repair is safe and self-verifying.
- **Runtime detectors live in the hook substrate, not in the surface they watch.** A detector that runs
  inside the thing it monitors (mission-control watching its own MCP; a skill verifying its own output) goes
  blind exactly when that surface fails. SessionStart hooks + `verify-prereqs.sh` + external CI are the
  crash-surviving substrate for P1-8 / P1-24 / P2-18.
- **PREVENT is the definition-of-done for each item:** not closed until the class can't silently return — a
  CI invariant, a ledger entry, or a referenced `THE ONLY WAY` rule.

---

## 7 · Sequencing & ownership

1. **P0 first** — fixes the incident class, near-entirely safe-auto, unblocks browser/render "out of the
   box." Order: P0-1 (+ **P0-7** mmdc) → P0-3 → P0-2 → P0-5 → P0-4 → P0-6.
2. **P1-A integrity** (cheap CI extensions — **P1-21** four-mirror check G and **P1-23** lifecycle-validate are
   cheap wins) and **P1-B cross-plugin** — **P1-8** hook-health, **P1-9** the live statusline drift, and
   **P1-5** scorecard-slurp are the highest-severity; do them early.
3. **P1-7** (define `DEGRADED_CAPABILITIES`, co-authored with mission-control) **before** the P1-C runtime
   items (**P1-24** liveness, **P1-25** stuck-phase). Then **P1-C**, then **P2** (P2-17/18/19/20 ride on the
   scorecard/observability substrate).

**Governance (reconciled — product invariant ≠ maintainer workflow):**
- **Product invariant (keep):** the marketplace's *shipped* self-improve **never self-merges** —
  `/<plugin>:self-improve` → `/foundry:pr-review` → a human merges (`merge-governance.md` governs the *product*).
- **Maintainer workflow (relaxed to match this repo):** ship **direct-to-main in batches**, no GitHub PR
  required. Each batch must still, in the same commit: (a) honour the **four-mirror guardrail** (now
  CI-enforced by P1-21), (b) **version-bump** any plugin whose skill changed, and (c) carry a
  **`/foundry:pr-review base..head` PASS** over the local diff (it reviews a diff without opening a PR; a
  failing review blocks the batch exactly as a PR review would). Per-item branches are optional — group
  related items. Re-run the relevant `/<plugin>:inspect` and `/foundry:scorecard` after each batch to record
  the closed-finding trend.

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
`/foundry:pr-review` on each implementing batch is the binding gate.

### Second pass — re-triage against the nine-plugin tree + the 10 new items (this revision)

A second five-lens panel reviewed the re-triage corrections and the extensions (refute-not-rubber-stamp).
**Verdict: NEEDS_REVISION → PASS** after folding four fixes:

- **[CRITICAL · ARCHITECTURE-FIT]** Re-owning runtime self-heal to mission-control risks it **healing
  itself** — a crashed mission-control can't detect its own crash. → **Detectors moved to the SessionStart
  hook substrate** (P1-8/P1-24); the self-observability dogfood (P2-18) runs as **external CI**. mission-control
  owns the canon + consumer; the detector survives the crash.
- **[HIGH · FEASIBILITY]** Check G (four-mirror, P1-21) vs auto-discovery — a blanket "all four mirrors"
  over-fires (not every skill has a tsv row). → **Scoped to *applicable* mirrors per artifact with an
  exemption table** (the pattern check D already uses); feasible because all mirrors are on-disk enumerable.
- **[MEDIUM · SAFETY]** P1-22's "verify" must not itself rewrite the welcome (an auto-rewrite could corrupt).
  → **Verify-and-disclose only**; the refresh stays the existing human-in-loop agent action.
- **[MEDIUM · SAFETY]** P2-20 (cycle-aware cost) risked a destructive schema migration. → **Additive schema**
  (readers default to cycle 1 when absent).

Re-triage corrections folded (claims now match the nine-plugin tree): "eight plugins" → **nine**; **P0-1**
narrowed (chromium rows already use a no-download `--dry-run` probe; **mmdc** is the real pure-presence gap →
**P0-7**); **P1-5** split (the `MARKETPLACE_SCORECARD.jsonl` half is **stale** — now tracked + `jq -nc`
appended; the `IDEA_COST.jsonl` `jq -rs` slurp is **real**); **P1-9** confirmed **LIVE** (installed-vs-shipped
md5 drift reproduced); **P1-14** narrowed to **concierge** (i2p and mission-control now carry check+inspector).
Second-pass self-assessment: **PASS** — claims verified against the tree, the human-gated line preserved, the
heal-itself circularity broken.

---

## 9 · Non-goals & honesty

- **No plugin code/config is changed by this document** — it is a plan / backlog (revised in place on `main`).
  Reference sketches are illustrative.
- **The human-gated stance is preserved.** Destructive heals (auto-revert P2-2, dep auto-pin P2-10, git
  cleanup P1-12, any merge) stay *detect-and-propose*. Only idempotent, **self-verifying** repairs are
  proposed safe-auto.
- **References, not restatements.** Where this names a pillar/protocol/convention, the canonical text lives
  in `plugins/foundry/knowledge/…` — follow the link, don't trust a paraphrase here.

*Light is green, trap is clean — hand this to the maintainers and we are go.* 🛸
