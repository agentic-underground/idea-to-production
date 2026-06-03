# Deprecated / Sunset

> **Provenance archive.** Part of the FOUNDRY provenance archive (allowlisted by the inspector).
> References to the historical `~/.claude` origin environment are history, not runtime coupling.

This records FORGE-CODE artefacts retired during the FOUNDRY consolidation, and where any
philosophy worth keeping was harvested to. Sunsetting is itself waste elimination — dead
machinery left running is inventory waste.

## FORGE_HELLO.md — the inter-agent communication bus (SUNSET)
- **What it was:** a git-file-based registry + inbox/outbox messaging space (`§1 Registry`,
  `§2 Inbox`, `§3 Resolved`) by which FORGE elements registered, discovered specialists, and
  routed messages across machines.
- **Why sunset:** Claude Code now has its own native subagent communication bus (Agent /
  SendMessage / task notifications). A hand-rolled git-file messaging protocol is redundant
  machinery and a synchronisation hazard.
- **Philosophy harvested (not lost):**
  - *Discovery before spawning a specialist* → preserved as the value-handler staffing model
    (a station with no handler is a defect FOUNDER reports) in `VALUE_FLOW.md §4–5`.
  - *Questions route to the right specialist; escalate when unanswered* → preserved as
    "questions flow up" in `knowledge/pillars/knowledge-parity.md`.
  - *Escalate a recurring learning into a durable doc* → preserved as the SOLID
    self-improvement covenant (`knowledge/architecture/solid-covenant.md`) and the `inspector`.
- **Disposition:** kept at repo root with a deprecation banner; no longer part of the workflow.

## forge-sync.sh + the Stop hook (SUNSET)
- **What it was:** a Stop-hook script that auto-synced FORGE state across machines.
- **Why sunset:** superseded; the SessionStart `git pull --rebase` hook (kept in
  `settings.json`) plus the post-commit auto-push on `main` cover ordinary sync. The Stop-hook
  invocation was removed from `settings.json`.
- **Disposition:** script kept at repo root with a deprecation banner; no longer wired in.

## code-quality/DEPLOYMENT.md (LEGACY)
- A standalone guide for deploying `code_quality` as an *independent* skill. Now that
  code-quality is a station inside the FOUNDRY plugin, install = enabling the plugin. The guide
  is retained for reference behind a legacy banner.

## hello-world-skill (REMOVED)
- A scaffolding/template skill; not part of the value-flow system. Removed.
