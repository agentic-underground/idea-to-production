# PROCESS-DOCUMENTATION & GIT GOVERNANCE — Master Epic Plan

> Roadmap: **[9]** (EPIC) — `plugins/mission-control/ROADMAP.md`
> Date: 2026-06-13 · Branch: `flow-tracking-ui` · Merge governance: `pr-approval`
> Status: IN PROGRESS (epic active; children built one at a time)

This is the **Step-0 master plan** for epic #9. An epic is not built directly — it sequences its children,
each of which runs the full DEV_SYSTEM (Steps 0–9) under its own GO authorization and its own `tf` token
stamp. This document fixes the build order, the per-child budget, and the token strategy.

---

## 1. Token stamp (token-fairness)

```
💰 ~700k tokens · p95 ±60% · SEEDING (0 samples)
🕒 Schedule: RUN NOW (off-peak)   tf plan --class epic
```

Epic-class, seeding tier (no samples yet — estimate will sharpen as children close). **This is a hard
ceiling, not advisory.** The expensive child (#12) is a fan-out and MUST carry its own `+Xk` consent and gate
every wave; the cheap children (#10/#11/#14) are near-free. Each child is re-stamped at its own GO with
`tf plan-open <class> <est>` / `tf plan-close` so the estimate:actual sampling converges.

## 2. Epic EARS (summary)

Commits are emoji Conventional Commits (existing FOUNDRY standard). On origins in the org allowlist (default
`agentic-underground/*`) the orchestrator raises a GitHub issue per completed item, annotates it per handler,
and the parcel PR closes the issues on merge. Each completed item is documented by a PRESSROOM pipeline
(sonnet draft → opus review → opus final + a bounded illustration loop), reused in the issues and an opt-in
wiki. Every newly onboarded project is alerted to this behaviour. The cheap layer is always-on; the opus
pipeline runs per completed item, off-peak, under the gate — never per commit.

## 3. Build order & per-child budget

| Order | Child | Plugin(s) | Depends on | Class | Est. | Rationale |
|-------|-------|-----------|------------|-------|------|-----------|
| 1 | **#10** Commit→Issue→PR governance | FOUNDRY | gh, merge-governance | small | ~80k | Foundational; cheap always-on; unblocks #11 & #13. Delivers "every commit passes through this process" first. |
| 2 | **#11** Issues-as-process annotation | FOUNDRY / MC | #10 | small | ~50k | Per-handler value-add log; reuses #10's issue + the carriage telemetry event. |
| 3 | **#14** Onboarding alert | CONCIERGE | — | small | ~40k | Independent, cheap; can run in parallel with 1–2. One-shot hook + `~/.claude/hook-state`. |
| 4 | **#12** Doc + illustration pipeline | PRESSROOM | (#8 model mechanism) | large | ~400k | Opus-heavy; durable off-peak `tf` job, per-item +Xk ceiling, bounded N=4 illustration loop. |
| 5 | **#13** GitHub wiki (opt-in) | FOUNDRY / PRESSROOM | #10, #12 | medium | ~80k | Publishes #12 output to the wiki for any github origin (opt-in). |

Sum ≈ 650k, within the ~700k epic stamp.

## 4. Per-child execution model

Each child, at its GO:
1. `tf plan --class <class>` → stamp; flip child STATUS → IN PROGRESS.
2. DEV_SYSTEM Steps 0–9 on `flow-tracking-ui` (its own `doc/<TITLE>_PLAN.md`, EARS, .feature, RED tests,
   implementation, green at 100% coverage floor, 3× flake check).
3. Implementation edits the named plugin(s) — these children modify the marketplace itself (agents, skills,
   knowledge, hooks), so each change is also subject to `/foundry:pr-review` before merge.
4. On green: child STATUS → AWAITING MERGE (pr-approval); it flips to COMPLETE when its PR merges.

The parcel PR for the whole epic is raised from `flow-tracking-ui` once the children are AWAITING MERGE,
referencing and closing their issues (this is #10's own behaviour, dogfooded).

## 5. Risks & mitigations

- **Token runaway on #12** — mitigated by the per-item +Xk ceiling, durable off-peak job, wave gating, and
  the bounded N=4 illustration loop with best-so-far fallback.
- **Origin mismatch** — this repo's `origin` is `whatbirdisthat/*` (mirrors to `agentic-underground/*`);
  #10's allowlist is configurable, so confirm the match value during #10's Step-0.
- **Marketplace self-modification** — children edit FOUNDRY/PRESSROOM/CONCIERGE; canonical-copy assets
  (SOUL/KAIZEN) must stay byte-identical (CI: `scripts/verify-prereqs.sh`).
- **`gh` unauth/unavailable** — #10/#11/#13 degrade gracefully (report the gap, continue; local docs still produced).

## 6. Checklist

- [x] Epic Step-0 master plan written + token-stamped
- [x] #9 STATUS → IN PROGRESS
- [ ] #10 built → AWAITING MERGE
- [ ] #11 built → AWAITING MERGE
- [ ] #14 built → AWAITING MERGE
- [ ] #12 built → AWAITING MERGE (off-peak)
- [ ] #13 built → AWAITING MERGE
- [ ] Epic parcel PR raised from `flow-tracking-ui`, closing issues on merge → #9 COMPLETE

## 7. Resumption

A cold-start agent: read this file + `plugins/mission-control/ROADMAP.md` entries [9]–[14]. Find the first
child not yet AWAITING MERGE/COMPLETE in the §3 order; that child's own `doc/<TITLE>_PLAN.md` (if present)
holds its mid-flight state. Re-stamp with `tf` before resuming any fan-out. Never run #12 inline past the
token gate.
