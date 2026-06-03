# SENTINEL — Security & Privacy Gate

> Never ship a leaked key, a real person's data, or a vulnerable dependency.

SENTINEL is the pre-release security gate for any repository. It runs three parallel audit lenses
and consolidates them into a single severity-ranked report with one verdict — **PASS / REVIEW /
BLOCK**.

It works on **any** project, standalone. It also serves as the **SECURITY value-station** for the
[`foundry`](../foundry/) plugin: when both are installed, foundry runs `/security-gate` before
delivery and halts on a BLOCK. When SENTINEL is absent, foundry simply ships markdown and notes
that the gate was skipped (*graceful enhancement* — no hard dependency either way).

## What's inside

| Component | Lens | Command |
|---|---|---|
| **security-gate** | orchestrator → one report, one verdict | `/security-gate [full\|quick\|path]` |
| **pii-audit** | personal data (names, emails, IDs, financial, health) | `/pii-audit [full\|data\|git\|code\|spa\|path]` |
| **secret-scan** | credentials (API keys, tokens, private keys, connection strings) | `/secret-scan [full\|tree\|history\|path]` |
| **dependency-audit** | supply chain (vulns, unpinned, abandoned, typosquats) | `/dependency-audit [path]` |

`/security-gate` is the front door — it fans out the other three in parallel and merges them.
Run the individual commands when you want one lens fast (e.g. `/secret-scan tree` pre-commit).

## The verdict

| Verdict | When | Action |
|---|---|---|
| **BLOCK** | any CRITICAL (live credential, special-category PII, critical/high vuln, private key) | do not ship |
| **REVIEW** | a HIGH or unresolved MEDIUM | human decision required |
| **PASS** | only documented LOW/MINIMAL | clear to ship; keep the report as evidence |

The verdict is the **max severity across all lenses** — a clean PII scan never offsets a leaked
key. A lens that can't fully run (missing advisory tool) reports *partial coverage* and never
returns a false PASS.

## Install

```
/plugin marketplace add whatbirdisthat/idea-to-production
/plugin install sentinel@idea-to-production
```

## Design principles

- **Three distinct lenses, kept separate** — personal data, credentials, and supply chain are
  different questions; mixing them dilutes each.
- **No silent passes** — every gap (skipped tree, missing tool, applied exclusion) is disclosed
  in the report's Coverage & Gaps section.
- **Never re-leak** — matched secrets are redacted to ≤4 leading characters; the report is itself
  committed.
- **Self-improving** — every missed pattern becomes a rule; every false positive becomes a
  narrow allowlist entry. The next scan starts stricter than the last.

See [ROADMAP.md](ROADMAP.md) for planned capabilities (license compliance, SBOM, CI recipes, IaC
scanning).

## ♻️ Self-improvement covenant — halve the distance to perfection

Every component of SENTINEL carries the SOLID self-improvement covenant: each iteration must **at
least halve the remaining distance to perfection** — every missed pattern becomes a rule, every
false positive a narrow exclusion, every new failure mode a guardrail — so the next scan starts
stricter than the last and recurring gaps are fixed *upstream, once*. This is the shared discipline
of the idea-to-production marketplace.

## License

Dual-licensed under **MIT OR Apache-2.0**.
