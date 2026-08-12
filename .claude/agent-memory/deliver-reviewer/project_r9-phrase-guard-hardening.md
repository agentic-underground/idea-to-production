---
name: r9-phrase-guard-hardening
description: PR #275 R9 lexicon-phrase drift-guard — RESOLVED at 454c602; crash fix + empty-tsv `[ -z "$key" ] && continue` guard both verified (0 group(s)/0 phrase(s), zero stderr, no phantom strict warn)
metadata:
  type: project
---

`scripts/verify-routing.sh` R9 block (RFC C5 drift-guard, warn-then-flip) hardening across PR #275.

**Fixed (rev 61029d7):** the original abort — an indented/whitespace comment row crashed the WHOLE
gate ("R9_WANT[$key]: unbound variable", exit 1). Root cause was `for key in $(… | sort)` (unquoted
word-split) + a `${R9_WANT[$key]}` deref with no `:-` under `set -u`. Revision quoted the report loop
(`while IFS= read -r key … < <(printf '%s\n' "${!R9_SEEN[@]}" | sort)`), added `:-` on every
R9_HIT/R9_FILE/R9_WANT deref, and strips leading whitespace off `fam` before the `#` comment guard.
Verified: old code crashes on the injected row, new code exits 0. Missing-file note ("no
SKILL.md/agent/command on disk") is now distinct from the dropped-phrase note. Generalized resolver
(skills → agents → commands) confirmed working for a command-hosted member (discover:inspect).

**Residual — RESOLVED (rev @454c602):** the empty/all-comment tsv case (blank-line key from
`"${!R9_SEEN[@]}"`) is fixed by `[ -z "$key" ] && continue` as the report loop's first line
(verify-routing.sh:379). Re-gate verified: comment-only/whitespace-only tsv → R9 reports "0
family/member group(s), 0 phrase(s)" as a ✓ pass, ZERO stderr, no "bad array subscript", exit 0; under
`--strict` warn count is IDENTICAL to the populated run (10), so R9 adds no phantom warn — the strict
exit=1 is fully attributable to the pre-existing R3/R6 warns. Normal case regression-free (15/28, exit
0); indented-comment (tab+space prefix) + whitespace-only rows alongside real data still yield 15/28
with zero stderr. See [[project_fail-open-guard-class]] (degenerate-collection iteration).

**Why:** R9 is the C5 compression safety-net; a false warn/error here erodes trust in the whole
routing gate. **How to apply:** on re-gate, confirm the empty-R9_SEEN guard landed; the crash-of-record
and the two message-distinctness items are already proven good.
