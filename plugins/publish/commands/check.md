---
description: Verify PUBLISH's typesetting/rendering tools (typst/pdflatex, dot, mmdc, pandoc, gs) are installed — a ✓/✗ table by tier that reports which PDF engine(s) are available (advisory; --strict to fail on a missing required tool).
---

Run the PUBLISH dependency check. Execute the script and present its ✓/✗ table, then state which
PDF engine(s) are available (Typst, LaTeX, or both) and which renderers/DTP tools are present. Point
at the per-row install hints.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/check/scripts/check.sh $ARGUMENTS
```

Advisory by default; `--strict` exits non-zero on a missing **required** tool. PUBLISH is
dual-engine — only one typesetter is needed. See the [`check` skill](../skills/check/SKILL.md).
