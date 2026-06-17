---
description: Inspect the FLOW plugin itself — audit its commands, skills, the flow-mcp binary, and hooks for drift, gaps, and duplication; produce a severity-ranked report.
---

Inspect FLOW.

Invoke the **inspector** agent to run an independent, critical audit of the plugin
(`${CLAUDE_PLUGIN_ROOT}`) per `knowledge/inspection-core.md`, plus the FLOW-specific checks
(command↔skill parity, the `/flow:pull` compose-not-reimplement contract, flow-mcp pinned-release
integrity, hook wiring by capability, tooling-by-capability). Produce a severity-ranked report; apply
unambiguous CRITICAL fixes; capture the rest for `/flow:self-improve`.
