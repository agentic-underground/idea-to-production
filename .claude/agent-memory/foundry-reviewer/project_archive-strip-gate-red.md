---
name: archive-strip-gate-red
description: Archive-and-strip PRs leave verify-prereqs.sh CI gate red on main; consumers (hardcoded paths, link refs, .gitignore) updated piecemeal
metadata:
  type: project
---

The **archive-and-strip class** of PR (move assets to ARCHIVE/, strip refs from live docs)
recurs and keeps leaving the CI gate `scripts/verify-prereqs.sh` red.

**Fact:** `verify-prereqs.sh` has been **red on `main` since commit `96dab5a`** (which removed
`PREREQUISITES/`). The script still hardcodes `PREREQUISITES/*.md` paths:
- **Check C** (.mcp.json ⟺ `PREREQUISITES/40-mcp.md` Shipped table) → empty doc-side table → mismatch.
- **Check D** (Probe cells don't fetch remote code) → `awk: cannot open PREREQUISITES/*.md` → crashes, "did not run".
- **Check I** (internal doc links resolve) → goes red whenever an archival commit deletes a
  link target without updating the referencing doc.
The gate is wired into `.github/workflows/verify.yml:28` and runs on every `pull_request` + push to main.

**Why:** archival PRs update *some* consumers but not all — the script's hardcoded paths,
`first-principles.md` diagram image links, `.gitignore` runtime rules, phase-sensor redirect targets.
Nobody treats the already-red gate as a blocker, so each archival PR piles on.

**How to apply:** When reviewing an archive/strip PR —
1. Run `bash scripts/verify-prereqs.sh; echo $?` FIRST. Attribute each failure: is it pre-existing
   on main (run it in a `git worktree add … main` clean tree) or NEW from this branch?
2. A NEW broken link (target existed on main, deleted on branch, referencing doc not updated) =
   MEDIUM regression owned by this PR. The classic miss: deleted `diagrams/*.png` but
   `first-principles.md` still links them.
3. `.gitignore` edits in these PRs are dangerous: removing `/.i2p/*` un-ignores LIVE runtime
   state (cost.sh `mkdir -p .i2p`, lifecycle.sh, gemba identity/learnings) → accidental commits.
   See [[fail-open-guard-class]] cousin: "is anything still WRITING the path you just un-ignored?"
4. The systemic fix (gemba): make the gate green on main first by fixing `verify-prereqs.sh`
   checks C/D to fail loud-and-early on a missing `PREREQUISITES/` instead of crashing awk;
   then never merge an archival PR that leaves the gate redder than it found it.

Related: [[plugin-count-drift]], [[checkI-fence-blinding]] (other verify-prereqs.sh check-I fragilities).
