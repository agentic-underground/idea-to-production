---
name: archive-move-redirect-class
description: Archive/move PRs strip a ref but redirect the pointer to a destination that never received the content, or leave a claim the move falsified — and CI link-check ships it green
metadata:
  type: project
---

When an archival / path-move PR removes a reference (e.g. retiring the `PREREQUISITES/`
folder to an archive), the recurring defect is NOT the deleted ref — it's the **redirect**:
the pointer is re-aimed at a destination that never received the migrated content, or a
factual claim/`.gitignore` rule the move falsified is left standing.

**Why:** the archival is mechanical (strip the token), so it misses (a) whether the *target*
actually holds the moved content, (b) section-anchor validity, (c) dependent claims, (d)
`.gitignore` rules that must follow a path change, (e) live consumers (scripts, error strings).

**Why CI doesn't catch it:** `verify-prereqs.sh` check I validates **file existence, not
section anchors or semantic content**. A redirect like `headless-browser.md (§ headless_capable)`
passes because the *file* exists, even though the *section* is fictional. Pairs with the known
link-checker blind spots in [[checkI-fence-blinding]] and the `${CLAUDE_PLUGIN_ROOT}`-ref skip.

**How to apply:** on any archive/move/strip-refs PR, before PASS:
- grep the removed token tree-wide (`PREREQUISITES/`, old path, old name) incl. scripts + error strings, not just the named doc files.
- for every redirected pointer, confirm the **target actually contains** the referenced section/table, not just that the file resolves.
- check no doc still asserts a property the move removed (e.g. "X is gitignored" after the ignore rule was deleted; output-dir path change without a matching ignore rule).
- confirm `.gitignore` rules moved with any relocated output dir.

Concrete instance: PR #250 (exile ARCHIVE/). phase-sensor+live-feedback redirected to a
non-existent `headless_capable` table in headless-browser.md; model-survey SKILL claimed
images/thumbs/contact-sheets gitignored after the same PR deleted every comfyui ignore rule
AND moved the dir docs/internal/comfyui-experiment/ → root comfyui-experiment/; build-pdf.sh +
verify-prereqs.sh still read the deleted PREREQUISITES/ tree.
