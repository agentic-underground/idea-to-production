# PR Review — items [37] and [38]: flow-server stdio MCP transport + registration (feature/items-37-38-mcp-stdio)

**Date:** 2026-06-14
**Branch:** feature/items-37-38-mcp-stdio → main
**Items:** [37] flow-server stdio MCP transport (`--mcp` flag) + [38] register in project settings
**Overall verdict:** PASS (after revision applied in `9d20b94`)
**Reviewer panel:** CORRECTNESS · SECURITY · REGRESSION · ARCHITECTURE · DOCUMENT + adversarial second-pass verification

---

## Verdict: PASS

All HIGH and MEDIUM findings were addressed in commit `9d20b94` before this verdict was issued.
No finding at HIGH or above survived adversarial second-pass verification in its original severity.

---

## Findings table

| # | Severity | Role | Locus | Finding | Status |
|---|----------|------|-------|---------|--------|
| 1 | HIGH | DOCUMENT | `[37]-ears.md:59`, `README.md:60`, `settings.json:12` | `set_gate` advertised as callable MCP tool; real name is `set_wait_go` — a `tools/call {"name":"set_gate"}` returns `-32602` | FIXED in `9d20b94` |
| 2 | MEDIUM | CORRECTNESS / ARCHITECTURE / DOCUMENT | `main.rs:23`, `[37].feature:95-98` | `--port is ignored` warning fired unconditionally in `--mcp` mode; EARS EVT-37-4 and feature scenario both scope it to `--mcp` + `--port`; scenario assertion was vacuous (only checked exit code, not stderr) | FIXED in `9d20b94` |
| 3 | LOW | SECURITY | `main.rs:118` | `BufReader::read_line` has no line-length cap; a newline-less multi-GB write would grow the String unboundedly | DOWNGRADED from HIGH after adversarial refutation: stdio is spawned by local MCP harness at user privilege; no network/cross-user path; self-DoS only. KAIZEN obligation recorded. |
| 4 | LOW | DOCUMENT | `README.md` | Production-mode binary path is relative and CWD-dependent | Non-blocking: documented constraint. |
| 5 | SUGGESTION | REGRESSION | `mcp_surface_intest.rs` | `Content-Type` header not explicitly asserted — pre-existing gap | Pre-existing; not a finding for this PR. |
| 6 | SUGGESTION | ARCHITECTURE | `main.rs` | `tokio::io::stdout()` re-acquired per loop iteration; `AppState.token` unused by `dispatch` (sets precedent for future transports) | KAIZEN. Not gating. |

---

## Revision applied (commit 9d20b94)

- `settings.json` — `set_gate` → `set_wait_go` in description
- `README.md` — `set_gate` → `set_wait_go` in tool list
- `.foundry/[37]-ears.md` — `set_wait_go` moved to the five-tool MUST list; removed from "all other" list
- `.foundry/[37].feature` — "no warning emitted" scenario now asserts stderr does not contain `--port is ignored`
- `src/config.rs` — added `port_explicit: bool` field + 2 new tests
- `src/main.rs` — `--port` warning now gated on `cfg.port_explicit`
- Test count: 326 (was 324; +2 for port_explicit tests)

---

## What was reviewed

- `src/mcp.rs` — `dispatch` extraction, response builder type change, HTTP handle wrapper
- `src/config.rs` — `--mcp` flag parsing, new `port_explicit` field
- `src/main.rs` — `run_stdio` function, `--mcp` branch wiring, AppState construction
- `src/mcp_dispatch_intest.rs` — 10 unit tests for dispatch (all 5 primary tools + error paths)
- `tests/stdio_story.rs` — 3 subprocess story tests
- `.claude/settings.json` — MCP registration entry
- `plugins/mission-control/flow-server/README.md` — MCP section
- `.foundry/[37]-ears.md` — EARS spec (7 requirements)
- `.foundry/[37].feature` — BDD feature file (23 scenarios)

## What was NOT reviewed

- SENTINEL security gate (`sentinel:security-gate`) — not run; no machine SAST, secret scan, or dependency audit. Recommend before next production promotion.
- Performance delta gate — no perf baseline established; KAIZEN obligation recorded.
- `signal-hook-registry 1.4.8` (new transitive dep via tokio `process` feature) — flagged for a future dep audit.

---

## Test evidence

326 tests passed, 0 failed, 0 ignored (cargo test -p flow-server; +3 subprocess story tests via cargo test --test stdio_story).

---

## KAIZEN obligations

1. Add `std::time::Instant` sampling to `stdio_story` tests and record a PERF_BASELINE comment.
2. Cap `BufReader::read_line` with `.take(MAX_LINE_BYTES)` in `run_stdio` to bound the self-DoS vector.
3. Document `AppState.token` as HTTP-auth-only (unused by `dispatch`) so future transports understand the dummy-token pattern.
4. Run `sentinel:security-gate` including dep audit for `signal-hook-registry` before next production promotion.

---

## Adversarial review outcome

The REGRESSION reviewer found zero regressions in the HTTP path. The SECURITY reviewer's HIGH finding (unbounded `read_line`) was downgraded to LOW after threat-model analysis: the stdio transport is spawned by the local MCP harness at the user's own privilege level — no network surface, no privilege escalation. The two genuine findings (HIGH: wrong tool name in docs; MEDIUM: unconditional warning + hollow scenario) were fixed before this verdict.

**Merge governance: pr-approval** — adversarial gate PASSED; a human must approve and merge.

---

# Original PR Review record below (previous session)


**Range:** `origin/main..flow-tracking-ui` · **Verdict: ✅ PASS** (after revision)

Five FOUNDRY reviewer roles fanned out adversarially over the epic diff (5 children: #10 commit→issue→PR
governance, #11 issues-as-process-doc, #12 doc+illustration pipeline, #13 wiki-publisher, #14 onboarding
alert). Initial synthesis was **NEEDS_REVISION** (2 HIGH correctness + 1 HIGH security + 2 MED); all were
fixed in `8e296f3` and re-verified.

## Role verdicts
| Role | Verdict | Notes |
|---|---|---|
| SECURITY | NEEDS_REVISION → **fixed** | 1 HIGH (wiki asset path-traversal exfil), 2 MED (allowlist prefix-spoof, token-in-URL) |
| CORRECTNESS | NEEDS_REVISION → **fixed** | 2 HIGH (unfillable `GITHUB_ISSUE` trailer; roadmap/issue number-space collision), 2 MED |
| ARCHITECTURE | PASS | all 5 marketplace laws hold; 1 systemic model-id-drift SUGGESTION (pre-existing, flagged to covenant) |
| REGRESSION | PASS | additive, well-gated; SessionStart chain + CI contract preserved; verify-prereqs green |
| DOCUMENT | PASS | links resolve, model IDs correct, no restated knowledge; 2 SUGGESTIONs |

## HIGH/MED findings — resolution (all adversarially repro'd, then fixed)
1. **[HIGH·SEC] Wiki asset path-traversal exfil** — `publish-wiki.sh` copied `![x](../../secret)` assets into
   the public wiki. **Fixed:** added `*..*` token guard **and** `realpath` confinement to `doc/articles/`
   (fail-closed). Repro confirms both layers now block it.
2. **[HIGH·CORR] `GITHUB_ISSUE: #N` trailer unfillable** — commit was created before the issue existed.
   **Fixed:** ds-step-9 raises the issue then `git commit --amend` (commit not yet pushed); ds-step-8 leaves
   the trailer to that amend on first delivery.
3. **[HIGH·CORR] Number-space collision** — `ROADMAP: closes #N` (roadmap item) would close GitHub issue #N.
   **Fixed:** commit-message.md now mandates a **non-closing** roadmap footer (`Refs roadmap #N`) on
   allowlisted github origins; only the PR's `Closes #<issue>` closes anything.
4. **[MED] Allowlist match** — prefix glob let `agentic-underground-evil/*` match and bare-owner vs slug was
   ambiguous. **Fixed:** merge-governance.md specifies an **anchored full `owner/repo` slug** match.
5. **[MED] Token-in-URL** (process-arg/`.git/config` exposure) — accepted as residual: scratch dir is
   `mktemp 0700` with cleanup trap, single-user dev target. Noted, not gating.

## Verification
- `bash scripts/verify-prereqs.sh` → **all checks PASS** (canonical parity, four-mirror J, link-resolution I,
  hook smoke-exec L incl. the new `offer-doc-alert.sh`).
- `bash -n` clean on all three new/edited shell scripts; security-exploit repro now **BLOCKED**.

## Not reviewed
- Live execution against GitHub (no issues/PRs were created; #10/#13's `gh` paths reviewed statically + the
  origin-match was dry-checked). The wiki publish was not run against a real `.wiki.git`.
- SENTINEL `/security-gate` (secrets/PII/deps): no new dependency or secret surface (authored docs + bash);
  the SECURITY reviewer role covered script safety directly.

## Carried suggestions (non-gating, KAIZEN)
- Model-id literals restated inline in 3 pressroom files — a pre-existing repo-wide pattern (45 files);
  flagged for a single future sweep to reference `model-selection.md`.
- `ROADMAP.md [0]` epic's plan reference points to a not-yet-created plan file (created at its own Step-0).

_Generated for `/foundry:pr-review` — reports a verdict; does not merge. Merge per merge-governance
(pr-approval: human merges the PR)._
