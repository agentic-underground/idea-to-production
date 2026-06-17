---
name: flow-plugin-standup
description: PR #126 / item #105 stood up plugins/flow/ by relocating flow+flow-mcp out of operate; rename-drift left stale refs the step-6 grep scope missed
metadata:
  type: project
---

Item #105 (PR #126, epic #93 stream 3) created `plugins/flow/` and `git mv`-relocated the
`flow`+`flow-setup` commands, the flow skill, and the whole `flow-mcp` Rust tree (incl.
bin/RELEASE, bin/SHA256SUMS, binary, smokes) out of `plugins/operate/`. Clean rename diff
(0-content moves), faithful to "relocate, do not re-author". verify-prereqs all green
(H=9 plugins, N=10 KAIZEN, O=9 inject, P=pin finalized flow-mcp-v0.2.3 under new path);
both smokes pass; CI workflows (flow-mcp-release.yml:72, verify.yml:73/76/91) repointed to
plugins/flow/flow-mcp.

**Why this matters for review:** the named step-6 stale-grep scope was
`plugins/ .claude-plugin/ scripts/ .github/ README.md CLAUDE.md PREREQUISITES/` — it
EXCLUDES `.i2p/`. A live stale `/operate:flow` ref (a now-dead command) survived in
`.i2p/roadmap/README.md:25` ("Carrying an item ... is the job of /operate:flow"). Same file
line ~23 also still says "flow-server" (pre-#97 binary name) — separate older drift.

**How to apply:** for any plugin/command rename or relocation, grep `.i2p/` too (roadmap
READMEs are navigational, agents read them). Stale refs to a DELETED command namespace =
MEDIUM (points users at a non-existent command); cosmetic stale comments inside moved
scripts (e.g. `# plugins/operate`, `emitter="operate:..."` audit label) where the live
logic resolves via $CLAUDE_PLUGIN_ROOT/$SCRIPT_DIR = LOW, non-load-bearing (the moved
hooks exec exit-0 under CLAUDE_PLUGIN_ROOT=flow). Ties to [[i2p-command-stutter-rename]]
and [[rename-wordmark-alttext]] — the recurring "rename leaves stale string drift" class.
