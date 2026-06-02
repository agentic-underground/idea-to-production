---
description: Audit a codebase for PII and secrets across data, git history, source, and frontend — produces PII-REPORT.md.
---

Run a PII / secrets audit using the **pii-audit** skill.

Scope from `$ARGUMENTS` (default: `full`): `full` (all systems), `data`, `git`, `code`, `spa`,
or a project-root path. Run the parallel audits per the skill, classify findings by risk
(CRITICAL → MINIMAL), and write `PII-REPORT.md` with findings, risk assessment, and
remediation. Recommended before open-sourcing or any major release — catching an exposure here
is far cheaper than after it ships.

For a complete pre-release check that also covers credentials and dependencies in one report
with a PASS/REVIEW/BLOCK verdict, run `/security-gate` instead (it includes this PII audit).
