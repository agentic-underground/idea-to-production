---
name: wiki-publisher-exfil
description: publish-wiki.sh asset-link guard blocklists http/abs/< but misses ../ — reads files outside doc/articles and pushes them to the public wiki
metadata:
  type: project
---

`plugins/mission-control/skills/wiki-publisher/scripts/publish-wiki.sh` (~line 83) copies
embedded image assets into the wiki page set. The guard is a BLOCKLIST
(`case "$asset" in http*|/*|*'<'*) continue`) — it omits `../`, so a relative `../../secret`
link in any `doc/articles/*.md` causes `cp "$srcdir/$asset"` to read outside the docs dir and
push the file to the (typically public) GitHub `.wiki.git`. `basename` only sanitises the
DEST name, never the SOURCE read. Confirmed exfil in /tmp test 2026-06-14.

**Why:** flagged HIGH in flow-tracking-ui SECURITY review (CWE-22 path traversal / CWE-200 exposure).
**How to apply:** recurring class — sanitisers in this marketplace lean on ENUMERATED BLOCKLISTS
(`http*|/*|<`) instead of allowlists/realpath-confinement. When reviewing any docs→publish or
path-mapping script, check `..` is fenced and the source is realpath-confined under its root, not
just that the dest basename is clean. Related: [[marketplace-supply-chain]] (same unpinned-trust theme).
Fix = `case "$asset" in *..*) continue` PLUS realpath-prefix check that resolved source is under $SRC.
