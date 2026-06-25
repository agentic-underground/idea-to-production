---
name: fail-open-guard-class
description: Recurring marketplace defect — guards that treat "no/empty result" or a swallowed error as the SAFE answer, failing open (spam/exec/exfil) instead of closed
metadata:
  type: project
---

Fail-open guards are a recurring defect class across mission-control/flow-server scripts.

**Pattern:** a guard runs a check, swallows the check's error (`2>/dev/null || true`,
`|| echo ""`), then treats an EMPTY/absent result as the permissive answer and proceeds.
A failed check (rate-limit, network, parse error) becomes indistinguishable from a genuine
"all clear", so the dangerous action runs.

**Confirmed occurrences:**
- gemba `raise-feedback.sh` (PR #112): dedup search `2>/dev/null || true` → empty → FILES
  anyway → duplicate-issue spam on the auto-filing same-repo path.
- See also the blocklist-not-allowlist sibling class: [[wiki-publisher-exfil]]
  (publish-wiki.sh) and [[flow-server-pin-parse]] (pin-parser fails-closed correctly —
  the counter-example to copy).

**Why:** "absence of evidence treated as evidence of safety." The safe direction for a
guard is fail-CLOSED — refuse the action when the check could not be proven to pass.

**How to apply:** when reviewing any new guard/dedup/sanitiser, ask "what happens when the
CHECK ITSELF errors?" Capture the checker's exit status separately from its output; only
treat empty as permissive when the check provably succeeded. Flag fail-open as ≥ MEDIUM.
This is now 3+ occurrences — candidate for a systematic KAIZEN sweep, not per-PR catches.
