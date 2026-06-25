---
name: flow-server-pin-parse
description: flow-server-mcp launcher pin-parser matches asset names on COMMENT lines & takes $1 verbatim with no hex-digest check — loose-match sanitiser class, not an exec bypass
metadata:
  type: project
---

`plugins/mission-control/flow-server/bin/flow-server-mcp` `pinned_sum_for()` (~line 58) parses the
committed `bin/SHA256SUMS` with `awk '$2==a || $2=="*"a {print $1}'`. It does NOT skip comment lines
and does NOT assert `$1` is a 64-hex digest. The as-committed (comment-only) SHA256SUMS has lines
`#   flow-server-<triple>` which awk collapses to `$1="#"`, `$2="<asset>"` — so `expected="#"` for
EVERY platform (proven in /tmp 2026-06-16). A crafted line `deadbeef  *flow-server-<triple>` yields
`expected=deadbeef` (binary-mode `*` marker matches; `$1` taken verbatim).

**NOT a CRITICAL / not an exec bypass.** The download+exec gate fails closed on every axis: checksum
compared before exec, mismatch → `rm tmp; return 1` (no path → never exec'd), empty pin → return 1
before download, missing hash tool → `got=""` ≠ pin, cached binary re-hashed against pin every launch,
`chmod +x` only after the gate, URL host fixed to github.com with TLS on. `expected="#"` can never
equal a real SHA, so today it just forces the cargo build fallback (headline "no Rust on destination"
goal silently unmet until SHA256SUMS is populated — PR documents this as dormant).

**Why:** flagged MEDIUM in PR #85 SECURITY review (CWE-345 insufficient verification / defense-in-depth).
The security-critical pin parser should reject malformed pins LOUDLY, not coincidentally.
**How to apply:** SAME loose-match/blocklist sanitiser class as [[wiki-publisher-exfil]] — marketplace
sanitisers match by name/enumeration instead of anchoring to well-formed input. When reviewing any
checksum/pin/signature parser here: confirm it skips comments/blanks AND validates the digest format
(`$1 =~ ^[0-9a-fA-F]{64}$`) before treating a pin as present. Fix = `awk '/^[[:space:]]*#/{next}
($2==a||$2=="*"a) && $1~/^[0-9a-fA-F]{64}$/{print $1;exit}'`. Also PR #85: release.yml `permissions:
contents: write` is workflow-scoped (build job over-privileged) — want job-level write on release only.
Related: [[flow-server-stdio-transport]], [[flow-server-tool-naming-drift]], [[marketplace-supply-chain]].
