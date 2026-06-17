---
description: Inspect the OPERATE plugin itself — audit skills, agents, and knowledge for drift, gaps, and duplication; produce a severity-ranked report.
---

Inspect OPERATE.

Invoke the **inspector** agent to run an independent, critical audit of the plugin
(`${CLAUDE_PLUGIN_ROOT}`) per `knowledge/inspection-core.md`, plus the OPERATE-specific checks
(command↔skill parity, gate composition, canon-reference integrity, lifecycle wiring by capability,
tooling-by-capability). Produce a severity-ranked report; apply unambiguous CRITICAL fixes; capture the
rest for `/operate:self-improve`.
