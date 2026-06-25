# Naming report — the canonical contract

Every name-search emits this report. It is also the quality bar for any marketing naming doc: a report that
doesn't fill every section hasn't earned a recommendation. Write to `docs/marketing/naming-report.md` in the
product repo (or stdout). Publishable via publish `/publish`.

The cardinal rule: **availability and challenge are two different verdicts in two different columns.** A name
removed because it is *taken* (availability) is never described with the same word as a name *demoted in the
adversarial challenge*. Conflating them is the single most common defect in naming docs.

## Required sections

### 1. Brief & charter
The discovery brief outcome — **audience**, **brand archetype(s)**, **name-type strategy** (which veins
ran + why), risk/power-adjacency/humour appetite — plus the ranked values, tone, structural constraints
(incl. syllable target), and banned stems. 3–4 sentences + the ranked value list.

### 2. Where it searched
Which registries/APIs were probed (npm exact+hyphenated, PyPI, crates.io, GitHub user/org), whether the
**adoption**, **neighbour** (`--neighbors`), **domain** (`--domains` via RDAP), and **connotation**
(`--connotation`) passes ran, whether a `GITHUB_TOKEN` lifted the rate limit (and whether the neighbour
pass was throttled to `unknown` without one), and any registry skipped or list truncation (`--max-names`).
Honesty about coverage.

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
Every generated name with **two distinct verdict columns** plus the new check columns and the vein that
produced it:

| Name | Vein | Syll. | `availabilityVerdict` | Neighbours | Domains | `challengeVerdict` | Evidence |
|---|---|---|---|---|---|---|---|
| … | suggestive/coined/… | … | CLEAR / LOW_ADOPTION / ABANDONED / TAKEN / UNKNOWN | 0 (clean) / N (samples) / unknown | com✓ dev✗ … | survived / killed:<axis> / n-a | npm:404 … or "Clarvio LLC live entity" |

Taken-but-recommendable names (LOW_ADOPTION/ABANDONED) carry their caveat here. A name with neighbours or a
connotation flag is **demoted in the challenge**, not in availability — keep the columns honest.

### 5. Ranked shortlist
The survivors, best first, each with: vein, syllables, the headline scores (philosophy-fit /
distinctiveness / sayability, 1–5) **plus the rubric detail** (weak Neumeier criteria, SMILE present,
SCRATCH flags, archetype-fit), the availability + neighbour + domain evidence, and a rich 2–3 sentence
justification of WHAT it encodes and WHY it fits the charter's ranked values **and archetype**.

### 6. Top recommendation + runner-up
The richest reasoning for the top pick, an explicit **confidence** statement, and **residual risks** stated
honestly: trademark was assessed by web search only and domains by RDAP availability — **neither is a legal
clearance** — recommend formal USPTO/EUIPO search before commercial commitment. Name a clean runner-up.

### 7. Methodology & caveats
The provenance of each check (404=free authoritative for exact strings; adoption tier from GitHub
stars+last-push and npm staleness/deprecation; **neighbours** from GitHub login-search `total_count`, rate-
limited and `unknown` without a token; **domains** from RDAP 404=available/200=registered; **connotation**
from the bundled wordlist, advisory; syllable count is an advisory heuristic), the date, and a "re-verify
within 30 days — the namespace moves fast" note.
