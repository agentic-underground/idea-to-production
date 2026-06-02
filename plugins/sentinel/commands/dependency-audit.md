---
description: Audit third-party dependencies for known vulnerabilities, unpinned versions, missing lockfiles, abandoned packages, and typosquats.
---

Run the **dependency-audit** skill.

Target from `$ARGUMENTS` (default: current repo): a project path or subproject.

Detect the ecosystem(s) from manifests/lockfiles (npm/pnpm/yarn, pip/Poetry/uv, Go, Cargo,
RubyGems, Maven/Gradle). Prefer the ecosystem's native advisory tool (`npm audit`, `pip-audit`,
`govulncheck`, `cargo audit`, `bundle audit`) when available; otherwise run static checks
(pinning, lockfile presence, package age, typosquat shape) and mark vulnerability coverage as
"static only". Write `DEPENDENCY-FINDINGS.md`, or return the findings section when called by
`/security-gate`. Never trigger a network install as a side effect of the audit.
