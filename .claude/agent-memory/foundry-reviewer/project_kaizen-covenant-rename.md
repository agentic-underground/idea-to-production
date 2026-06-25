---
name: kaizen-covenant-rename
description: The SOLID covenant was renamed to the KAIZEN covenant (full content reframe); what is intentionally preserved vs. what must not be over-renamed
metadata:
  type: project
---

The marketplace "SOLID self-improvement covenant" was renamed to the **KAIZEN covenant** with a
full content reframe (PDCA, gemba, standardize-then-improve, small steps, muda·mura·muri,
everyone-improves; prime law "halve the distance to perfection" and self-cleaving kept). Added an
always-on KAIZEN.md banner (10 copies: root + 9 plugins) + inject-kaizen.sh SessionStart hook (9
copies), enforced by new CI checks N (KAIZEN.md parity) and O (inject-kaizen.sh parity) in
`scripts/verify-prereqs.sh`. `solid-covenant.md` was deleted; `kaizen-covenant.md` replaces it.

**Why:** reframe the document/marketplace self-improvement discipline around lean/kaizen instead of
SOLID-applied-to-documents.

**How to apply (the load-bearing distinction for future reviews):**
- **MUST be preserved as code-SOLID, never renamed to KAIZEN:** `architecture/solid.md` (the
  code-design principles reference), the `/code-quality` skill's SOLID expertise, the
  DESIGN-REVIEWER role's "deep expertise in SOLID principles", reviewer.md's SOLID checklist
  (Open/Closed, Liskov, etc.), and ds-step-5's "SOLID principle violations". These are about CODE
  structure, not the document covenant. This PR correctly left them alone.
- **Over-rename risk to flag:** inserting a "kaizen:" label in front of a list of SOLID-of-documents
  principles (single-responsibility, extend-don't-mutate=Open/Closed, substitutable=Liskov) is a
  semantic mismatch — the kaizen reframe RETIRED that S/O/L/I/D framing. Seen at
  `skills/ideate/references/self-improvement-review-prompt.md:20`.
- Many docs legitimately use SOLID-derived vocabulary ("single-responsibility per section",
  "substitutable") to describe document structure WITHOUT the covenant label (self-improve/SKILL.md,
  every inspection-core.md, roadmapper/SKILL.md) — those are fine, do not flag.
- Provenance-archive files (`plugins/foundry/docs/DEPRECATED.md`, `MIGRATION.md`) still mention the
  deleted `solid-covenant.md` as inline-code (not markdown links), so CI Check I does not break. See
  [[project-provenance-archive]] — archive is rename-exempt, but a "preserved as → path" pointer to a
  now-deleted path is mildly stale.
