---
description: Keep the lights on — dependency upkeep, CVE patching, cert/secret rotation, restore drills, capacity & tech-debt cadence.
---

Run the **maintain** skill.

Target from `$ARGUMENTS` (default: current repo): a project path or subproject.

Review the maintenance **cadence** and mark each item current / due / overdue: dependency upkeep &
CVE patching, certificate & secret rotation, backup-restore drills, capacity review against saturation
trends, and budgeted tech-debt paydown.

For dependencies/CVEs, **compose `secure`'s `/scan-dependencies`** by capability when SECURE is
installed (vulnerable/unpinned/abandoned/typosquat packages); when absent, fall back to a static manifest
read and **note the reduced coverage** — never declare deps clean on no audit. Changes to the live system
stay deliberate (known blast radius, rollback plan, risky change gated by remaining error budget). Write
`MAINTENANCE-FINDINGS.md`, or return the findings section when called by `/operate-gate`.
