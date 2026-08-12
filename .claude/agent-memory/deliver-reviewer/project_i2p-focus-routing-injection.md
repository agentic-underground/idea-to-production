---
name: i2p-focus-routing-injection
description: RESOLVED (PR #273 re-review) — i2p focus-routing.sh now takes only awk $1 first-token after phase: + re-validates vs closed 9-phase allowlist; fail-closed. History of the class below
metadata:
  type: project
---

`plugins/i2p/hooks/scripts/focus-routing.sh` (PR #273, feat/routing-slice3-phase-gate) reads
repo-tracked `.i2p/focus`, extracts `phase:` via awk, and injects it verbatim (×3) into every
session's `additionalContext`, framed "the user has declared this the active phase".

**Why it's the reviewable class:** `focus.sh` validates phase ∈ 9 phases *on WRITE*, but the hook
*trusts the file on READ* — a hand-edited/committed/tarball'd `.i2p/focus` bypasses focus.sh
entirely. The hook has NO whitelist. Two bypasses proven:
- `tr -d '[:space:]'` strips only ASCII whitespace; **U+00A0 (and other unicode spaces) survive and
  render as spaces** → readable multi-word injection lands in context.
- No `is_phase` check → arbitrary strings pass.

**Also:** the no-jq fallback (`esc//\\` then `esc//\"`) escapes backslash+quote correctly (no
JSON-string breakout — verified) but NOT raw control bytes <0x20 (ESC survives `tr`, breaks JSON →
fail-safe drop, but latent). The idiom is copied from sibling `roadmap-routing.sh`, where `ROUTING`
is a STATIC string (nothing untrusted) — safe there, unsafe once fed attacker input here.

**How to apply:** for any i2p SessionStart hook that injects a file value into context, require the
hook to re-validate against a closed allowlist matching `^[A-Z]+$` (defense in depth) — never rely
on the writer's validation. One `^[A-Z]+$`+9-phase-set check kills both the unicode-space injection
and the control-char JSON defect. Related: [[fail-open-guard-class]] (trust-the-input class).
Path/write side of focus.sh is clean: `$*` is printed not eval'd, write target is fixed.

**RESOLUTION (re-review, both HIGH+MEDIUM resolved):** fix takes ONLY the first whitespace-delimited
token `awk '/^phase:/{sub(/^phase:[ \t]*/,""); print $1; exit}'` → `tr -d '[:space:]'` →
uppercase → `case " DISCOVER…OPERATE " in *" $phase "*)` closed allowlist, else `exit 0` no
injection. Re-tested empirically: ASCII/U+00A0/control-byte/superstring(DELIVERX,BUILDD)/two-word-smuggle
(DISCOVER OPERATE→only DISCOVER)/second-phase-line/indented-key/empty all fail-closed — the ONLY text
ever injected is `Active FOCUS: <one of 9 A-Z phases>.`. Empty phase safe because empty→`*"  "*`
(two-space) pattern can't match the single-spaced haystack. Legit path (BUILD/discover/padded) clean;
exit 0, read-only, valid JSON, both jq and no-jq branches. Control-byte MEDIUM moot: no-jq printf branch
only reached with an already-allowlisted A-Z word.
