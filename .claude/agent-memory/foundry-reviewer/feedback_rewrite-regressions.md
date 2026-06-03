---
name: rewrite-regressions
description: Regression-review checklist for changesets that rewrite a script/interface while callers stay the same
metadata:
  type: feedback
---

When a script or interface is rewritten but its callers are unchanged, check these regression vectors first:

1. **Argument-precedence shifts.** A new flag-parsing loop that resolves a mode (e.g. `--engine=auto`) BEFORE honouring a positional arg can change behaviour for an explicitly-named target. Trace the no-arg AND explicit-arg caller paths separately. (build-pdf.sh: auto-engine picks typst when any *.typ exists, even if caller named a .tex.)
2. **Silent-skip vs hard-fail on missing dependency.** Old `set -e` scripts often failed loudly when a tool was absent; a rewrite that adds `have() && ...` guards can silently skip a step and still exit 0, producing a broken-but-"successful" artefact (e.g. PDF compiled without its diagrams).
3. **`set -u` + conditionally-assigned vars.** A var assigned only inside an `if have X` block must be read as `${var:-default}` downstream or it trips unbound-variable. Verify the guard exists.
4. **Stale prose describing the old behaviour.** Caller docs/SKILL steps that narrate "(three pdflatex passes)" beside a now-dual-engine invocation are misleading but non-breaking — flag LOW.
5. **Output-format/filename coupling.** If the rewrite changes intermediate artefact format per-mode (LaTeX→.pdf diagrams, Typst→.svg), confirm the consuming template still references the format the chosen mode produces.

**Why:** rewrite changesets pass surface review because the happy path works; regressions hide in the mode/dependency/precedence edges.
**How to apply:** simulate the arg-parsing in isolation with a temp dir matrix (single source, both sources, no source, explicit-name-with-other-mode-present, missing tool) before issuing a verdict. See [[provenance-archive]].
