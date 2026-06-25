---
name: flow-server-release-window
description: flow-server pinned-release model — bootstrap window mechanics, where main's live pin actually sits, and the cargo-less destination outage a bump opens
metadata:
  type: project
---

The flow-server MCP binary is a PINNED RELEASE, not committed. Three files must stay in
lockstep (verify-prereqs §P enforces): `bin/RELEASE` (tag `flow-server-vX.Y.Z`),
`Cargo.toml version` (== tag version), `bin/SHA256SUMS` (one 64-hex line per asset).

**Two-phase release model (established, sanctioned):** bump RELEASE+Cargo and merge with an
EMPTY SHA256SUMS (only `#` comment lines) = the **bootstrap window**; then push the tag →
`flow-server-release.yml` (trigger `push: tags:['flow-server-v*']` + workflow_dispatch) builds
the matrix, packages assets+checksums, publishes the GitHub Release; then a SEPARATE commit
pastes the checksum lines into SHA256SUMS to re-arm. Prior bumps did exactly this (#86 cut
v0.1.0 then `0470d97` pinned its sums).

**Both gates are engineered to PASS the window (verified locally on PR #103 / item [39]):**
- verify-prereqs §P: `ncs==0` non-comment lines → `pass "pin bootstrap window"` (exit 0). The
  pin-parser bug from [[flow-server-pin-parse]] is now FIXED here (awk skips `#`/blank AND
  requires `$1 ~ /^[0-9a-fA-F]{64}$/`) — same fix mirrored in smoke-pinned.sh and the launcher's
  `pinned_sum_for()`.
- `flow-server-mcp-pinned` CI job runs smoke-pinned.sh, which SKIPs (exit 0) when no committed
  line matches this platform's asset. No Rust toolchain on that job → it can ONLY pass via the
  SKIP in the window. `flow-server-mcp-smoke` builds from source (smoke-mcp.sh) — window-immune.

**THE RESIDUAL RISK a bump opens (MEDIUM, not BLOCK):** while the window is open, a destination
machine WITHOUT cargo cannot start the server — launcher ladder is CACHED(miss)→RETRIEVE(fails:
no pinned checksum)→BUILD(fails: no cargo)→ERROR exit 1. main was at a FINALIZED pin
(v0.2.1, 5 checksum lines — NOT 0.2.3 despite #100's "bump to 0.2.3" message), so a bump PR
strictly OPENS a window that didn't exist on main. This is the same "stranded on a stale/absent
release" class as defect [92]. So: the post-merge tag-push+publish must be a TRACKED, OWNED
follow-up, not just a prose note — that's the gate finding to raise on any flow-server version bump.

**How to apply:** on any flow-server bump PR, (1) confirm §P + smoke-pinned both PASS via the
bootstrap branch (they should), (2) confirm Cargo==RELEASE-tag version, (3) raise MEDIUM if the
release publish isn't an owned/tracked follow-up. Related: [[flow-server-pin-parse]],
[[flow-server-roadmap-tree]] (#92 staleness), [[flow-server-staleness-two-axes]].
