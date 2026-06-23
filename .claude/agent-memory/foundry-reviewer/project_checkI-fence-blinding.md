---
name: checkI-fence-blinding
description: verify-prereqs.sh check I fenced-code skip toggles on ANY ```-prefixed line incl quad-backtick inline spans → unbalanced fence silently blinds rest of file from link-checking
metadata:
  type: project
---

`scripts/verify-prereqs.sh` check I (internal doc links) gained a fenced-code skip
(PR #146): `/^[[:space:]]*```/ { infence = !infence; next }`.

**Defect class — naive fence toggle:** the regex flips `infence` on ANY line starting
with ``` ``` ```, including quad-backtick inline spans like `` ```` ```mermaid ```` ``
(used to *display* literal triple-backticks). Such a line is not a real fence delimiter,
so it leaves `infence` stuck true → the entire tail of that file is silently excluded
from link-checking.

**Why:** Confirmed live in `plugins/publish/skills/diagram-studio/SKILL.md` — line 55's
quad-backtick line blinds lines 56-146; 3 real (currently-resolving) links drop out of
coverage. Skipping only WEAKENS (never false-FAILs), so it slips through green, but the
safety net is off for those lines — a future broken link there passes CI undetected.

**How to apply:** When reviewing markdown-fence-aware awk/sed, test against quad-backtick
spans and unbalanced fences. A robust fix matches the OPENING fence length and only an
EQUAL-OR-LONGER run closes it (CommonMark rule), or restricts the toggle to fences at
column 0 that are exactly ``` ```lang ```. Flag MEDIUM: silent coverage loss, not a
hard failure. Related: [[fail-open-guard-class]] (guard weakens silently).
