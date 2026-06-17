---
name: rename-wordmark-alttext
description: Plugin renames repeatedly leave README line-3 banner alt-text naming the OLD wordmark; verify-prereqs has no check for it
metadata:
  type: project
---

On every plugin rename, `plugins/<p>/README.md:3` banner alt-text (`the "<name>" wordmark ...`) must be updated to the new plugin name — it is the only README line that names the plugin's identity in prose, and it slips because no check resolves it.

Rename wave observed: #94 sentinel→security, #95 mission-control→operate, #96 pressroom→publish. In PR #118 (#96) the heading/prose were converted to PUBLISH but line 3 still said `"pressroom" wordmark` — caught as MEDIUM → NEEDS_REVISION. Siblings #94/#95 DID update theirs (`"security"`, `"operate"` wordmark), which is the canonical correct pattern.

**Why:** alt-text is prose, not a path/command, so `scripts/verify-prereqs.sh` Checks H/I/J never test it; it is the accessibility/text layer of the masthead so a stale value mis-names the plugin to screen-reader users.
**How to apply:** on ANY plugin-rename PR, grep `plugins/*/README.md:3` for the old wordmark token; flag a surviving old name as MEDIUM (real user-facing identity defect, but not a broken ref/composition). Distinct from acceptable kept raster/runtime contracts (banner.png raster regen can defer; `pressroom-press.gif`, `filename_prefix`, env vars stay). KAIZEN: a verify-prereqs check asserting line-3 wordmark==plugin-name would kill this class. Related: [[project-plugin-count-drift]] (another doc-token-drift class CI doesn't catch).

**Plugin-RETIREMENT variant (PR #121 / roadmap #98, concierge→i2p):** when a plugin is folded into another, the hero-GIF alt-text in the survivor's README (i2p/README.md:8 — the spoke list) still NAMES the retired plugin ("eight ringed specialist plugins — …, operate, concierge"); it was stale on main and the merge PR didn't touch README. Same root cause: alt-text prose, no Check covers it. ALSO in this class: the folded-in user-facing commands (`/i2p:statusline`, `/i2p:statusline-widgets`, `/i2p:define-welcome`) were NOT added to the survivor README's Commands table or Onboarding section → undiscoverable from the front door, even though the card AC2 + §C named them. Check J passes regardless because it only requires *a* /command per skill-shipping plugin, not the specific three. Flag both MEDIUM. `docs/SLASH_COMMANDS.md` concierge entries are OUT OF SCOPE here — that's the user's separate v2-identity feedback surface (owned by #93/#113/#99/#114, references nonexistent sentinel/pressroom/mission-control plugin names), untouched by #98. Opt-out markers correctly KEEP the `concierge-*` filename prefix (byte-identical to main) — that is preservation, not drift.
