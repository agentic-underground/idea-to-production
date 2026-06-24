# PR_REVIEW.md — PR #247

**Title:** ✨ feat(ci): bind the SLASH_COMMANDS MCP table to the real .mcp.json inventory (#246)
**Range:** `main...feat/slash-commands-mcp-parity`
**Verdict:** ✅ **PASS** (one LOW found and hardened in-pass)

## What this PR does
Adds **check Q** to `scripts/verify-prereqs.sh` — sibling of check C — binding the
`docs/SLASH_COMMANDS.md` "## Appendix — MCP servers" table to the real `plugins/*/.mcp.json` inventory
on three axes (server-set, shipped-by per server, count line). Closes #246's drift class.

## Adversarial review — roles fanned out
| Role | Verdict | Notes |
|---|---|---|
| CORRECTNESS | PASS | Attacked 6 false-negative axes with empirical drift fixtures. Check is directionally fail-closed (non-empty inventory can never match an empty/unfound table); python crash → rc=1 → `fail` (no rubber-stamp). All true-positive drifts fire. One LOW (see below). |
| DOCUMENT + portability | PASS | Conventions match (section/pass/fail/python3-guard mirror check C); header comment accurate; heredoc-via-stdin + PEP 540 UTF-8 mode make unicode (⟺/∅) safe under CI's C locale (verified `LC_ALL=C`); python3 reliably present on ubuntu-latest and already required by check C; no external checks-roster doc owes a Q entry. |

## Findings & disposition
| # | Sev | Finding | Disposition |
|---|---|---|---|
| 1 | LOW | Count-line parse used **last-match** semantics — a 2nd "ships N" sentence could mask a wrong headline. Not reachable today (one sentence), contrived shape. | **FIXED** — switched to first parseable match (`🩹 fix` commit). Masking fixture now FAILs; clean tree still GREEN. |

## Verification (re-run post-fix)
- `bash -n` clean; full contract GREEN; Q: `2 shipped server(s) match … context7, fetch`.
- Drift fixtures all FAIL: stale shipped-by, unshipped `playwright` row + wrong count (the #246 scenario), count-only error, and the new last-wins masking case. Tree restored clean.
- CI wiring confirmed: `.github/workflows/verify.yml` `verify` job runs `bash scripts/verify-prereqs.sh`.

## Not reviewed
- SECURITY/REGRESSION/PERFORMANCE — a CI-only shell/python check, no product code/deps/behaviour touched.
