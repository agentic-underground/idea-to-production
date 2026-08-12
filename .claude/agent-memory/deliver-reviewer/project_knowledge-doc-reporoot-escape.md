---
name: knowledge-doc-reporoot-escape
description: Whether a knowledge doc's ../../../../ links to repo-root (CLAUDE.md/.github) violate the self-contained-plugin rule — accepted pattern, not a gate
metadata:
  type: project
---
A `plugins/*/knowledge/**.md` doc that links repo-root files via `../../../../CLAUDE.md`,
`../../../../.github/...` is NOT a self-contained-plugin violation on its own.

**Why:** CLAUDE.md's self-contained rule scopes to **live surfaces** (hooks/scripts that
resolve paths at runtime via `${CLAUDE_PLUGIN_ROOT}`) — markdown nav links in a knowledge
doc are not live surfaces. In-repo the 4-level escape resolves (protocols/ → repo root),
so CI link-check (verify-prereqs Check I) passes and the doc's actual audience (maintainers)
can follow them. Standalone-install dangling is a pre-existing, accepted pattern:
`plugins/deliver/knowledge/tooling/headless-browser.md:57` already links
`../../../../scripts/ensure-browser.sh`.

**How to apply:** Treat repo-root escapes in a knowledge doc as LOW / KAIZEN-systemic
(portability class), not a gating MEDIUM — unless the doc is in the canonical-copy set.
Canonical-copy set is ONLY check.sh (A), KAIZEN.md (N), inject-kaizen.sh (O) per
verify-prereqs.sh — **protocols/*.md are NOT canonical-copied**, so a single-instance
knowledge doc raises no parity/portability breakage. Related: [[fail-open-guard-class]],
[[knowledge-phase-resolver]] (nested `metadata.phase: [x]` parses fine — resolver regex is
`re.M`-anchored, nesting-agnostic).
