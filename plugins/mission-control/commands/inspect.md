---
description: Inspect the MISSION-CONTROL plugin itself — audit skills, agents, and knowledge for drift, gaps, and duplication; produce a severity-ranked report.
---

Inspect MISSION-CONTROL.

Invoke the **inspector** agent to run an independent, critical audit of the plugin
(`${CLAUDE_PLUGIN_ROOT}`) per `knowledge/inspection-core.md`, plus the MISSION-CONTROL-specific checks
(command↔skill parity, gate composition, canon-reference integrity, lifecycle wiring by capability,
tooling-by-capability). Produce a severity-ranked report; apply unambiguous CRITICAL fixes; capture the
rest for `/mission-control:self-improve`.
