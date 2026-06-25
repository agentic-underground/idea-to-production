---
description: Generate a project-local PREREQUISITES.md — the software the installed marketplace plugins need, why, how to install it, and what's currently missing on this machine.
---

Generate `PREREQUISITES.md` for this project. Follow the [`prerequisites` skill](../skills/prerequisites/SKILL.md):

1. Detect which plugins are installed (deliver always; secure/publish if present).
2. Run each installed plugin's `-check` **command** to capture live ✓/✗ status — `/deliver:check`,
   and `/secure:check` / `/publish:check` if those companions are installed (by capability, never
   a cross-plugin filesystem path).
3. Assemble `PREREQUISITES.md` in the current project root, scoped to the installed plugins,
   embedding the live status snapshot.

Then tell the user where it was written and summarise the top missing tools (if any).

## `--fix` — dispatch the safe self-heals, then re-stamp

`/deliver:prerequisites --fix` is the same flow with one extra verb run **first**: it is a **thin
dispatcher** over each plugin's already-shipped, idempotent, **self-verifying** sub-heals (it owns
no repair logic — SOLID). See the [`prerequisites` skill](../skills/prerequisites/SKILL.md)
`--fix` section for the sub-heal register and rules. In short:

1. **Dispatch the safe sub-heals** (only when their owning script is reachable in the marketplace
   source tree — degrade gracefully when deliver was installed standalone):
   - Browser / env wiring: `bash ${repo}/scripts/ensure-browser.sh --fix` (idempotent; heals only an
     empty browser stub slot and verifies the healed path launches).
2. **Detect-and-report (never auto-run)** canonical-copy drift via `bash ${repo}/scripts/verify-prereqs.sh`
   — report drift, do not re-sync (the guarded re-sync is the future `verify-prereqs.sh --fix`).
3. **Re-stamp**: re-run the per-plugin `/check`s (step 2 above) and re-assemble `PREREQUISITES.md`
   so it reflects the **post-heal** machine state.

Only idempotent, self-verifying heals run automatically; anything destructive or ambiguous is
reported, never auto-run (the human-gated stance). Without `--fix`, behaviour is unchanged.
