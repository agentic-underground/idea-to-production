# REVIEW_ACTION_PLAN — companion-plugin inspection findings

> **⚠️ This is a transient coordination document, not part of the marketplace.**
> **When every item below is done (or consciously dismissed), delete it:** `git rm REVIEW_ACTION_PLAN.md`.

## What this is

On **2026-06-07** the marketplace gained per-plugin inspection (`/<plugin>:inspect`) and a scorekeeping
skill (`/foundry:scorecard`). Running `/ideator:inspect` then the four companion inspectors surfaced drift
across the suite. **IDEATOR's findings are already fixed (PR #21); the scorecard's own bugs are fixed
(PR #22).** This plan captures the **remaining findings for atelier, market-scanner, sentinel, pressroom**
(the inspection reports themselves were transient and not committed, so everything needed is embedded here).

Baseline from the sweep: **CRITICAL 2 · WARNING 15 · SUGGESTION 19** across the four plugins.

## Process (read before starting)

- **Governance: `pr-approval`, never self-merge.** Each batch on a branch → `/foundry:pr-review` → PR for a
  human to merge.
- **When you change a skill, update all four mirrors** in the same branch: `plugin.json` (keywords +
  `metadata.note`), the `marketplace.json` entry (description + keywords + version), the `README.md`, and
  `skills/check/requirements.tsv` — **and bump the plugin version** (patch for docs/fixes, minor for new
  capability) so `/plugin marketplace update` re-syncs installed caches. This four-mirror guardrail is the
  root-cause fix for most of Batch 2; it already lives in `ideator/skills/self-improve/SKILL.md` (#21) —
  copy it into the other plugins' `self-improve` skills as you go.
- **After each fix:** re-run the relevant `/<plugin>:inspect` to confirm the finding is closed, and run
  `/foundry:scorecard` (marketplace) so the findings-closed trend is recorded.

---

## Batch 1 — CRITICALs

### 1. PRESSROOM — Rule 6 margin divergence (REAL)
`plugins/pressroom/skills/rich-pdf-with-diagrams/SKILL.md` §3 (~line 155) restates Rule 6 as
`margin="0.20,0.13"`, but the canonical `references/charting-matrix.md` Rule 6 (~line 90) — and the *same
SKILL.md*'s anti-pattern table (~line 267) and Lesson 0019 — mandate `0.22,0.14`. A producer reading §3
under-pads boxes below the legibility floor.
**Fix:** correct the value to `0.22,0.14`. **Better:** replace §3's full 13-row restatement of the matrix
with a one-line-per-rule index + a pointer to `charting-matrix.md` — that removes the single-source drift at
its root (and closes the paired WARNING "§3 wholesale-restates the single-source matrix").

### 2. SENTINEL — "self-improve uninvocable" is a FALSE POSITIVE → fix the inspector, not the plugin
`/sentinel:self-improve` **is** invocable. The marketplace intentionally ships `self-improve` as a
**command-less skill** (ideator, atelier, market-scanner all do; only foundry has a
`commands/self-improve.md`). The inspector's **command↔skill-parity** check over-fired and mislabelled this
CRITICAL.
**Fix (in the inspector, not sentinel):** exempt `self-improve` from the command↔skill-parity assertion.
The assertion lives in the generic Phase-3 of the byte-identical `plugins/*/knowledge/inspection-core.md`
(and/or each plugin's `agents/inspector.md` Phase-3 #1). Change the **canonical** copy once, then re-sync all
copies so the md5-integrity check still passes (`md5sum plugins/*/knowledge/inspection-core.md | sort -u`
→ 1 line).
**Optional alternative (consistency, not correctness):** add `commands/self-improve.md` to all five
command-less plugins so foundry isn't the odd one out. **Pick one approach, not both.**

---

## Batch 2 — Mirror-drift (same class as IDEATOR #21; low-risk; do all four together)

The uplift added `inspect` + `self-improve` to each plugin but left their advertising behind. For
**atelier, market-scanner, sentinel, pressroom**:

- **README "What's inside" omits the new surface.** Add rows for `/<plugin>:inspect`, the `self-improve`
  skill, and (sentinel) the `check` skill. The newest features are currently undiscoverable at the front
  door.
- **`plugin.json` ↔ `marketplace.json` drift.** Reconcile each pair to one wording + keyword set and mirror
  it into both:
  - *pressroom*: `marketplace.json` keywords omit `data-visualization`, `typography`, `design-review`.
  - *atelier*: `plugin.json` description ends "…design feedback sharpens the canon and the rubric via a PR";
    the marketplace entry dropped that self-improvement clause and rephrased the Playwright clause.
  - *sentinel*: `plugin.json` description predates the uplift (no mention of the self-improve loop /
    on-demand inspector); align both.
- **pressroom `ROADMAP.md` version lag** — says "v1.2"; plugin is 1.3.x. Add a v1.3 line (self-improve +
  inspector + covenant) and re-baseline.
- **Fold the four-mirror guardrail into each plugin's `self-improve` SKILL** (copy the paragraph from
  `ideator/skills/self-improve/SKILL.md` step 3) so this drift class cannot recur.

### Market-scanner inspector-spec drift (the inspector audits the wrong thing)
- `plugins/market-scanner/agents/inspector.md` Phase-3 item 2 (~line 30) points the kill ledger at
  `.market-scanner/goal.md` — wrong; every other surface puts the ledger in
  `knowledge/discovery/scoring.md`. Repoint item 2; leave `goal.md` to item 3 (the goal contract).
- Same file item 1 (~line 27) lists **8** scoring parameters; `knowledge/discovery/parameters.md` defines
  **~16** (groups A–E). Reword to audit against `parameters.md`'s full content, treating the named subset as
  illustrative (dependency-inversion — depend on the canonical file, not an inline summary).

---

## Batch 3 — Architectural follow-ups (bigger; one PR each; prioritize as noted)

### A. SENTINEL `pii-audit` auto-commits and pushes — **highest priority**
`plugins/sentinel/skills/pii-audit/SKILL.md` Phase 5 (~lines 165–172) runs `git add`/`commit`/`push origin`
automatically. A security skill silently mutating and pushing git state violates the covenant's "branch →
review → PR, never self-merge" and the report-don't-act posture of its sibling audits (secret-scan,
dependency-audit don't do this).
**Fix:** remove the auto-push; at most "stage the report for the user to commit", matching the siblings.

### B. SENTINEL `pii-audit` missing `model:` frontmatter (quick)
Frontmatter ends without `model:`; the haiku intent appears only as prose (~line 250), so it runs on the
inherited model against its own docs and the token-efficiency pillar. **Fix:** add
`model: claude-haiku-4-5` to the frontmatter.

### C. ATELIER `ui-review` doesn't delegate to its opus-pinned reviewer
`skills/ui-review/SKILL.md` inlines its own canon-walk + scoring instead of spawning `agents/ui-design-reviewer.md`
(which `mockup` *does* spawn, and whose description claims "spawned by the ui-review and mockup skills").
Consequences: the five lenses (HIERARCHY/INTERACTION/ACCESSIBILITY/AESTHETICS/CONSISTENCY) are unreachable
from `/ui-review`, and the opus pin isn't in force on that path.
**Fix:** have `ui-review` delegate to the agent like `mockup` does (pass an optional lens; default full
panel) — single-sources the critique, restores the lenses, restores the pin. (Or, minimally, correct the
agent description — but delegation is the right fix.)

### D. MARKET-SCANNER kill ledger has no writable home
`skills/market-scan/SKILL.md` step 6 + Output tell a scan to "record the reason in the kill ledger
(scoring.md)" — but `scoring.md` is read-only in the installed plugin, so a `/loop /market-scan` cannot
write it; killed candidates can be re-litigated.
**Fix:** define a project-local ledger (e.g. `.market-scanner/kills.md`, sibling to `goal.md`) that
market-scan appends/reads each pass; reserve `scoring.md` for durable ANTI-PATTERNs promoted via
`self-improve`. Update market-scan SKILL step 6 + Output, `scoring.md`, `goal-loop.md`.

### E. MARKET-SCANNER standalone-handoff path inconsistent
The fallback brief path is stated three different ways: `doc/opportunities/<slug>.md` (SKILL line ~79,
`commands/market-scan.md` line ~14), "refine by hand / no path" (`README.md` line ~33), and "markdown
brief / no path" (inspector item 4). **Fix:** pin the path once in `scoring.md`'s "Output of a scan" and
reference it from the other surfaces.

### F. Cross-cutting — standing portability assertion + sweep
Promote **"cross-plugin `../<plugin>/` or `../../PREREQUISITES/…` links in a README dangle for a
standalone-installed plugin"** to a standing generic Phase-3 assertion in `inspection-core.md`, then sweep
all plugin READMEs and de-load-bear those links (reference companions by capability / repo URL). Flagged in
ideator #21 (PREREQUISITES link fixed there) and market-scanner; likely present in others.

### G. Cross-cutting — `concierge` (new 7th plugin) was NOT in this sweep
`concierge` was added after the sweep (marketplace v1.6.0). Run `/concierge:inspect` if it exists; otherwise
apply the same checks. Ensure it carries the **byte-identical `knowledge/inspection-core.md`**, a
`knowledge/covenant.md`, and — if it has user-facing skills — an `inspect` command/agent and a `self-improve`
skill, and that it's included in the canonical-copy md5 integrity set.

---

## Lower-priority SUGGESTIONS (non-blocking; address opportunistically)

- **atelier:** surface Norman/emotional-design as a `mockup` composition default; fix the
  `design-critique-loop.md` "interaction-laws §2.4" citation (§2 is a flat list — cite "§2 heuristic 4 +
  Jakob's Law §1"); document `crawl.mjs` anchor-only route discovery in `crawl-config.md`; soften
  `accessibility.md` "EAA in force June 2025" → "since June 2025"; clarify the Accessibility weight-vs-gate
  redundancy so a future self-improve doesn't "fix" a non-bug.
- **market-scanner:** name the `/loop` provider + degraded path in `goal-loop.md`/commands; have
  `self-improve` lead with the *capability* ("adversarial PR-review gate") not the literal
  `/foundry:pr-review`; add a 3-row ✅/⚠️/❌ → KEEP/PARK/KILL legend to `scoring.md`.
- **sentinel:** give the `self-improve` cleave criterion a concrete threshold ("two distinct detection
  lenses or two output reports → split"); add a forward-ref to the planned unified `.securityignore` in the
  per-skill ignore sections; have `security-gate quick` record skipped lenses as "intentionally skipped —
  partial coverage" so a quick PASS isn't mistaken for a full PASS.
- **pressroom:** pillar-tag the covenant's token-efficiency line; mirror the design-reviewer's "if installed
  → else degrade" phrasing in `self-improve`'s adversarial-gate clause; cross-link `publish.md` step 4 to
  `/pressroom:self-improve`; update README/ROADMAP self-improvement prose to name the new skill;
  clarify the inspector report lands at the marketplace root (not the invoking cwd) when auditing source.

---

## Suggested sequencing

1. **Batch 1** (2 items) — one PR; closes both real-vs-false CRITICALs.
2. **Batch 2** (4-plugin mirror-drift + market-scanner inspector spec) — one PR; mostly mechanical, highest
   ratio of findings-closed to risk; lands the four-mirror guardrail everywhere.
3. **Batch 3** — one PR per item (A first). F and G are good standing-improvement work.
4. Re-run each `/<plugin>:inspect` + `/foundry:scorecard` after each batch; the marketplace scorecard should
   show CRITICAL/WARNING trending to 0.

When all of the above is done or dismissed: **`git rm REVIEW_ACTION_PLAN.md`** and commit.
