# First-order instrumentation — the HUD's always-on instruments

> The marketplace measures itself. Two instruments are **first-order**: always on, low-overhead, surfaced
> on the status-line HUD, and fed by deterministic hooks (not model self-report). This doc is their
> canonical contract — the renderer, the hooks, and the i2p lifecycle tools all honour it.

## 1. ⚔ Adversarial-catch counter

Counts the **times an adversarial reviewer caught something** — a first-class measure of the quality gate
doing its job.

- **Fed by:** `concierge` PostToolUse(Write|Edit) hook `statusline/count-adversarial-catches.sh`. When an
  adversarial-review artifact (`PR_REVIEW.md`, `I2P_REVIEW.md`, `SECURITY-REPORT.md`, `PII-REPORT.md`,
  `*_INSPECTION_REPORT.md`) is written with a non-PASS verdict or a CRITICAL/HIGH/MEDIUM finding, the
  counter increments — deduped by content hash so a re-write never double-counts.
- **State:** `~/.claude/state/adversarial-catches.{total,seen}`.
- **HUD:** `⚔ caught N` (gold when N>0, dim at 0).

## 2. Token-cost tracker (measure → attribute per-phase → calibrate)

Brings **token cost into first-order operations** alongside the catch counter: it measures actual spend,
attributes it to the active product-lifecycle phase, and **compares estimates to actuals so estimates
self-correct over time**.

### Measure (the engine)
- **Fed by:** `concierge` **Stop** hook `statusline/capture-cost.sh`. Each turn it incrementally sums the
  session transcript's `.message.usage` (input + output + cache-creation + cache-read) across assistant
  messages, checkpointing per session so it only counts the **delta** since last turn. USD is derived per
  model from `concierge/statusline/model-prices.tsv` (input / output / cache-write-5m / cache-read).
- **State:** `~/.claude/state/i2p-cost/session.json` (current session totals — the always-on `◇` widget),
  `<session>.ckpt` (incremental checkpoint), and — when a lifecycle is active in the project — the
  per-phase actuals in `<project>/.i2p/cost.json`.

### Attribute (per phase)
- If the project (cwd) has `.i2p/lifecycle.json`, the turn's delta is added to `.i2p/cost.json` under the
  **current phase** (`phases[PHASE].actual_tokens` / `actual_usd`; `totals` recomputed).

### Estimate + calibrate (the loop) — `i2p/skills/lifecycle/scripts/cost.sh`
- **`estimate`** (run on `/i2p-lifecycle init`): per-phase `estimate_tokens = BASE[phase] × ratio_ewma[phase]`.
  BASE is a rough seed table; the multiplier is **learned**.
- **`close <PHASE>`** (run on `/i2p-lifecycle done <PHASE>`): computes `ratio = actual/estimate` for the
  phase and folds it into the **global** calibration ledger `~/.claude/state/i2p-cost/calibration.json`
  (`ratio_ewma`, EWMA α=0.4, cross-project). Every closed phase makes future estimates of that phase sharper.
- **`record <PHASE> N`**: folds an authoritative external actual into a phase — FOUNDRY calls this with
  `IDEA_COST.jsonl` `token_accounting.tokens_total` at DELIVERY, so the BUILD phase's actual is the true
  all-agent number rather than just the main thread.

### `.i2p/cost.json` schema (canonical)
```json
{ "phases": { "DISCOVER": {"estimate_tokens": 30000, "actual_tokens": 0, "actual_usd": 0.0}, "…": {} },
  "totals": { "estimate_tokens": 0, "actual_tokens": 0, "actual_usd": 0.0 } }
```

#### Cycle-indexed cost (additive — P2-20)
A product loops **OPERATE ↻ DISCOVER**; each new cycle must accrue its own cost without **clobbering**
the prior cycle's. Cost is therefore **cycle-indexed**, keyed by the lifecycle's `.cycle` field
(`.i2p/lifecycle.json`). The schema is **additive — no destructive migration**:

- The flat shape above **is cycle 1.** A reader with no cycle index — an old flat file, or no
  running lifecycle — **defaults to cycle 1** and reads it unchanged. The concierge Stop-hook
  writer (`capture-cost.sh`) keeps writing the flat shape; that is cycle 1 and stays correct.
- Only when a **cycle > 1 first accrues** does the file grow a top-level `cycles` map: the
  pre-existing flat `phases`/`totals` fold **losslessly** down into `cycles["1"]`, and the new
  cycle lands at `cycles["<n>"]`. Prior cycles are never overwritten.

```json
{ "cycles": {
    "1": { "phases": { "DISCOVER": {"estimate_tokens": 30000, "actual_tokens": 50000, "actual_usd": 0.0}, "…": {} },
           "totals": { "estimate_tokens": 375000, "actual_tokens": 50000, "actual_usd": 0.0 } },
    "2": { "phases": { "DISCOVER": {"estimate_tokens": 0, "actual_tokens": 70000, "actual_usd": 0.0} },
           "totals": { "estimate_tokens": 0, "actual_tokens": 70000, "actual_usd": 0.0 } } } }
```

`cost.sh` reads the active cycle from `lifecycle.json` (`.cycle`, default 1) and reports/accrues
against that cycle's node; `report` labels the cycle so prior cycles are visibly preserved.

### HUD widgets (built-in, first-order)
- `◇ <tokens> · $<usd> session` — always on. Tokens from `session.json`; **$ from the harness's
  authoritative `cost.total_cost_usd`** (the price-map figure is the fallback).
- `◈ life <actual>/~<estimate> (Δ%) · $<usd>` — only when `.i2p/cost.json` exists; Δ% coloured green
  (under), yellow (near), red (over).

## Honest caveats
- **Session $ is authoritative** (harness `cost.total_cost_usd`, includes everything). **Lifecycle/phase $
  is price-map-derived** (approximate, attributable) — update `model-prices.tsv` when pricing changes.
- **Lifecycle tokens** are measured from the main session transcript; subagent-heavy work is best captured
  via FOUNDRY's `IDEA_COST.jsonl` folded into BUILD (`cost.sh record`). Ad-hoc `Task` subagent tokens
  outside FOUNDRY are a known minor undercount.
- Both instruments **degrade silently** — a missing file, missing jq, or absent lifecycle never breaks the
  HUD or blocks a turn.

> Self-improvement covenant: when an estimate is consistently wrong in a way calibration can't fix (e.g. a
> phase's BASE seed is an order of magnitude off, or a model price changed), fix the BASE table / price map
> **once** here — every future lifecycle inherits it.
