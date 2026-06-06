# Naming report — the canonical contract

Every name-search emits this report. It is also the quality bar for any marketing naming doc: a report that
doesn't fill every section hasn't earned a recommendation. Write to `docs/marketing/naming-report.md` in the
product repo (or stdout). Publishable via pressroom `/publish`.

The cardinal rule: **availability and challenge are two different verdicts in two different columns.** A name
removed because it is *taken* (availability) is never described with the same word as a name *demoted in the
adversarial challenge*. Conflating them is the single most common defect in naming docs.

## Required sections

### 1. Charter
The ranked values, tone, structural constraints (incl. the syllable target), and banned stems the search
ran under. 2–3 sentences + the ranked value list.

### 2. Where it searched
Which registries/APIs were probed (npm exact+hyphenated, PyPI, crates.io, GitHub user/org), whether the
adoption pass ran, whether a `GITHUB_TOKEN` lifted the rate limit, and any registry skipped or any list
truncation (`--max-names`). Honesty about coverage.

### 3. Attrition funnel
A small table the numbers of which must reconcile:

| Phase | Count |
|---|---|
| Generated (deduped) | N |
| Passed availability (recommendable) | n1 |
| Survived adversarial challenge | n2 |
| Ranked shortlist | n3 |

If the challenge killed everything, say so explicitly and rank the availability-survivors (state that the
shortlist is "cleanest of a challenged field", as actually happened).

### 4. Per-name disposition
Every generated name with **two distinct verdict columns** and the evidence:

| Name | Syll. | `availabilityVerdict` | `challengeVerdict` | Evidence (codes / stars / collision) |
|---|---|---|---|---|
| … | … | CLEAR / LOW_ADOPTION / ABANDONED / TAKEN / UNKNOWN | survived / killed:<axis> / n-a | npm:404 pypi:404 … or "Clarvio LLC live entity" |

Taken-but-recommendable names (LOW_ADOPTION/ABANDONED) carry their caveat here.

### 5. Ranked shortlist
The survivors, best first, each with: syllables, the scores (philosophy-fit / distinctiveness / sayability,
1–5), the availability evidence, and a rich 2–3 sentence justification of WHAT it encodes and WHY it fits
the charter's ranked values.

### 6. Top recommendation + runner-up
The richest reasoning for the top pick, an explicit **confidence** statement, and **residual risks** stated
honestly: trademark and domain were assessed by web search only (or RDAP for domains if checked) and are
**not** a legal clearance — recommend formal USPTO/EUIPO search before commercial commitment. Name a clean
runner-up.

### 7. Methodology & caveats
The provenance of each check (404=free authoritative for exact strings; adoption tier from GitHub
stars+last-push and npm staleness/deprecation; syllable count is an advisory heuristic), the date, and a
"re-verify within 30 days — the namespace moves fast" note.
