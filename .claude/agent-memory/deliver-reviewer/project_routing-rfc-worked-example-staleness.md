---
name: routing-rfc-worked-example-staleness
description: context-routing.md RFC carries worked-example notes ("/frontend does not exist today — ship a dead trigger") that the slice fulfilling them falsifies; the completion PR must retire them
metadata:
  type: project
---

The context-routing RFC guide (`docs/guide/context-routing.md`) uses **worked-example
prose** that anticipates future slices — e.g. §6 line ~304: *"The 'After' trigger
`/frontend` does not exist today — `frontend` ships no command file … copy it as-is and you
ship a dead trigger. This is exactly the class of dead route R3 catches."*

**Why:** when the slice that *creates* `/frontend` lands (PR #281, slice 5), that present-tense
note becomes actively false — R3 now RESOLVES `/frontend` (verified: 35 namespaced refs, gate
green). The PR body even declared "This completes the context-routing initiative", so the
contradiction ships in a live guide (CLAUDE.md links it as the companion RFC).

**How to apply:** when reviewing a routing slice, grep `docs/guide/context-routing.md` (and
`docs/MARKETPLACE_AUDIT_REPORT.md`) for the exact command/skill the slice touches — the RFC's
"does not exist today / dead trigger / §8 creates it" notes are forward-refs the fulfilling PR
must retire, or the doc self-contradicts. verify-routing.sh (R3/R6) is blind to this prose.
Same class as [[fleet-cd-migration-pr-chain]] and [[archive-move-redirect-class]].
