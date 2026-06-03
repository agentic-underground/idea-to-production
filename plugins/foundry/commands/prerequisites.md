---
description: Generate a project-local PREREQUISITES.md — the software the installed marketplace plugins need, why, how to install it, and what's currently missing on this machine.
---

Generate `PREREQUISITES.md` for this project. Follow the [`prerequisites` skill](../skills/prerequisites/SKILL.md):

1. Detect which plugins are installed (foundry always; sentinel/pressroom if present).
2. Run each installed plugin's `-check` **command** to capture live ✓/✗ status — `/foundry:check`,
   and `/sentinel:check` / `/pressroom:check` if those companions are installed (by capability, never
   a cross-plugin filesystem path).
3. Assemble `PREREQUISITES.md` in the current project root from the marketplace `PREREQUISITES/`
   folder, scoped to the installed plugins, embedding the live status snapshot.

Then tell the user where it was written and summarise the top missing tools (if any).
