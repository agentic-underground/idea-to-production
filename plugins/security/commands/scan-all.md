---
description: Run the full pre-release security gate — PII + secrets + dependency audits → SECURITY-REPORT.md with a PASS/REVIEW/BLOCK verdict.
---

Run the consolidated **scan-all** skill.

Scope from `$ARGUMENTS` (default: `full`): `full` (PII + secrets + dependencies, working tree +
git history + artefacts), `quick` (working-tree PII + secrets only — fast pre-commit), or a
project path.

Fan out the three SECURITY audits in parallel — **scan-for-pii** (personal data), **scan-for-secrets**
(credentials), **scan-dependencies** (supply chain) — consolidate and deduplicate their findings,
then write `SECURITY-REPORT.md` with an overall verdict:

- **BLOCK** — any CRITICAL finding; do not ship.
- **REVIEW** — a HIGH or unresolved MEDIUM; human decision required.
- **PASS** — only documented LOW/MINIMAL findings.

The verdict is the maximum severity across all three lenses. If a lens cannot fully run (e.g. an
advisory tool is missing), report partial coverage — never return PASS for an un-run lens.

This is the SECURITY value-station the `foundry` plugin invokes before DELIVERY when SECURITY is
installed; it is equally useful standalone before any release or open-sourcing.
