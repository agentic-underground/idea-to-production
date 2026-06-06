---
description: Inspect the i2p plugin itself — audit commands, skills, hooks, and knowledge for drift, gaps, and duplication; produce a severity-ranked report.
---

Inspect i2p.

Invoke the **inspector** agent to run an independent, critical audit of the plugin
(`${CLAUDE_PLUGIN_ROOT}`) per `knowledge/inspection-core.md`, plus the i2p-specific checks
(command↔skill parity, delegation-not-duplication, capability-by-detection, onboarding-hook integrity).
Produce a severity-ranked report; apply unambiguous CRITICAL fixes; capture the rest for
`/i2p:self-improve`.
