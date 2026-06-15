# Gate 01 — Award-winning reference corpus (taste calibration)

**Artifact under review:** `docs/internal/image-craft-study/corpus/CORPUS.md` + `exemplars.jsonl` (120 rows, 6 categories × 20)
**Review stance:** Adversarial taste panel — assume padded/hand-wavy/misattributed until each entry survives scrutiny.
**Date:** 2026-06-10

---

## VERDICT: NEEDS_REVISION

The corpus is **structurally sound and far stronger than a "padded" corpus** — 6 categories × 20 distinct subjects, every `why_great` is theory-named (zero vague "beautiful/striking/stunning" padding found), all licenses are editorial/reference-only and SFW, and every juried/canonical attribution I spot-checked (8 web verifications) came back **correct**. Theory vocabulary is broad and usable.

It does **not** clear a strict PASS for one concentrated reason: the **action category** carries **5 weak entries** that lean on non-specific "practitioner / lineage / canon" attributions or an award-name mismatch instead of a single named, juried, verifiable work. A PASS requires *every* category to be ≥20 genuinely award-tier entries with no fabricated/mismatched awards; the action category currently has ~15 clean + 5 soft. Fix those five and this is a PASS.

**No fabricated awards** were found among the entries that name a specific work. The soft entries are honestly hedged ("lineage", "canon", "no formal award") rather than dressed as fake juried wins — so this is a *rigor/replaceability* problem, not an *integrity* problem. The one genuine integrity defect is `action-15` (award name + title do not match the verified record).

---

## Per-category one-line assessment

- **Genres (20):** PASS-grade. 20 distinct subjects; canonical masterworks honestly flagged "celebrated/canonical" where no juried award applies (Dalí, Beksiński, Rothko, Frazetta, Leibovitz) — acceptable per the rubric. Real juried wins (Eisner, Society of Illustrators Gold, WPY, Annie/Academy for Spider-Verse, Chesley for Donato) verified. No filler.
- **Styles (20):** PASS-grade. 20 distinct movements, each anchored to the *defining* exemplar of the style (Mucha/Cassandre/Bayer/Müller-Brockmann/Hokusai/Monet/Caravaggio…). "Award" column is honestly a *movement/era* label, not a fake prize — appropriate for a style track. Longest, richest `why_great` of any category.
- **Scenes (20):** PASS-grade. Every entry a named DP + named film; juried entries (Oscar/ASC/BAFTA) verified; "iconic" entries (Searchers, Cantina, Fallen Angels, War Room, Midsommar) are genuinely canonical cinematography, honestly marked. Distinct subjects, no near-dupes.
- **Diagrams (20):** PASS-grade and arguably the best-curated track. Minard, Tufte slopegraph/sparklines, Gapminder, Tube map, Isotype, OSI, Minard, NYT Upshot, Biesty (verified NYT Best Illustrated 1993) — the canon of data-viz, each tied to a named principle (Cleveland–McGill, Bertin, data-ink, lie-factor). No filler.
- **Landscapes (20):** PASS-grade. Clean split of canonical painting (Bierstadt, Turner, Friedrich, Church, Levitan, Van Gogh, Ansel Adams) + real juried photo wins (ILPOTY, Sony WPA, Epson Pano). 20 distinct subjects, richest theory tagging.
- **Action shots (20):** **NEEDS_REVISION.** ~15 are excellent and verified (WSPA 2025/2026 overall, World Press Photo, Ocean Photographer of the Year, WPY, Audubon, POYi, Red Bull Illume overall winners — all confirmed). **But 5 entries are soft** (see ranked list) — generic "technique exemplar" placeholders or an award/title mismatch that a strict gate must reject.

---

## Attribution spot-checks performed (all via web search)

| Entry | Claim | Result |
|---|---|---|
| action-01 | Edgar Su, "Carlos' Shadow Hits a Ball", WSPA 2026 Overall Winner | ✅ Confirmed (Canon UK / PetaPixel / Sky Sports) |
| action-03 | Jérôme Brouillet, "Golden Moment" (Medina), WSPA 2025 Overall Gold | ✅ Confirmed (Olympics.com / MyModernMet) |
| action-14 | Felipe Toledo Alarcón, Audubon "Chile & Colombia Grand Prize" | ✅ Confirmed (inaugural Chile/Colombia grand prize, 2025, 16th Audubon) |
| action-12 | Cammie Czuchnicki, RMetS South East 1st place 2013 | ✅ Confirmed ("Tornadic Supercell at Night, Kansas") — odd phrasing but honest |
| action-19 | Steph Chambers, POYi 77th Sports Photographer of the Year (first woman) | ✅ Confirmed (poy.org / Post-Gazette) |
| genre-02 | Spider-Verse — Annie Best Production Design + Academy Best Animated 2019 | ✅ Confirmed (Justin K. Thompson, 46th Annies) |
| genre-03 | Donato Giancola, Chesley Best Unpublished 2015, Beren & Lúthien | ✅ Confirmed (ASFA Chesley past winners) |
| scene-07 | Blade Runner — Cronenweth, BAFTA Best Cinematography 1983 | ✅ Confirmed (Wikipedia / IMDb awards) |
| diagram-19 | Biesty Cross-Sections — NYT Best Illustrated Children's Book 1993 | ✅ Confirmed |

**Net:** attribution integrity is high. No misattributed famous works detected. The only mismatch is action-15 (below).

---

## Ranked list — entries to REPLACE or SHARPEN (with concrete fix)

### Tier 1 — REPLACE (integrity / not-award-tier-as-stated)

1. **action-15** — *K-Pop Concert Finale (keyframe), Scott Watanabe, "Concept Art Awards 2025 — Best Key Concept Art (KPop Demon Hunters)"*
   **Defect (integrity):** The award name and the title don't match the record. Watanabe's *verified* Concept Art Awards 2025 winning pieces for KPop Demon Hunters are **"Demon World", "Kpop Climax", and "Huntrix Girls"** — there is no "K-Pop Concert Finale" piece and no category literally named "Best Key Concept Art" surfaced in verification. It also smuggles a *concept-art keyframe* into a category (live-action peak-action capture) where every other entry is a captured photographic moment — a genre mismatch that dilutes the "decisive moment" taste signal.
   **Fix:** Replace the title with the actual winning piece (e.g. **"Kpop Climax"** or **"Demon World", Scott Watanabe, Concept Art Awards 2025 winner**) and correct the award string to the real category, OR drop it and substitute a *captured* crowd-energy action photo (e.g. a World Press Photo / WSPA concert-or-crowd-surge frame) to keep the category photographically coherent.

2. **action-02** — *"Olympic / motorsport motion-blur panning craft", author: "Documented sports-press panning practitioners (per DCW analysis)", award: "WSPA / Olympic press pool — recognised panning technique"*
   **Defect:** This is a *technique essay*, not an award-winning work. No named artist, no named image, no juried award — the "award" is a paraphrase of a Digital Camera World how-to article. Reads as filler to hit 20.
   **Fix:** Replace with a *named, juried* panning exemplar — e.g. a specific **World Sports Photography Awards "Motorsport" category winner** or an **Olympic motion-blur frame** credited to a named photographer with the year/category. The panning *principle* is worth keeping; the placeholder is not.

3. **action-17** — *"Red Bull Art of Motion freerunning leap", author: "Red Bull Illume action-sports street-category practitioners", award: "Red Bull Illume — street/action-sports (parkour) category lineage"*
   **Defect:** Same pattern — "category lineage" with no named winner or image. action-10 already covers Red Bull Illume with a *real* named overall winner (Lorenz Holder, 2016), so this is also near-duplicate sourcing.
   **Fix:** Replace with a **specific named Red Bull Illume *Playground / Lifestyle* category winner** (named photographer + year) for a true parkour/freerunning frame, or swap the subject to a distinct under-covered action archetype (e.g. **track sprint start**, **ski big-air**, **fencing lunge**) anchored to a named juried winner.

4. **action-20** — *"Rodeo / bull-riding action", author: "Documented rodeo sports-press practitioners (Ilford/Pro Rodeo coverage)", award: "Sports-photojournalism rodeo coverage — exhibited/published award lineage"*
   **Defect:** Same "archetype/lineage" placeholder; the source is an Ilford film-stock marketing blog, not a juried award. Not award-tier as stated.
   **Fix:** Replace with a **named rodeo/equestrian-action image from a real competition** (e.g. a World Press Photo Sports or POYi rodeo frame with photographer + year), or fold rodeo into action-13's equestrian slot and use the freed entry for a genuinely distinct archetype.

### Tier 2 — SHARPEN (keep, but tighten attribution honesty)

5. **action-18** — *"Dune: Part Two — harvester destruction / desert combat beat", author: "Greig Fraser ASC ACS / Oscar-winning VFX team", award: "Academy Award for Best Visual Effects lineage / Oscar craft-recognised action cinematography"*
   **Defect:** "lineage" / "Oscar craft-recognised" is vague hedging. Dune: Part Two's status is real (it is a Best VFX winner), so the entry is *defensible* — but the award string should state the **actual award** plainly, and it should name a **specific shot/sequence** rather than a generic "combat beat", so it reads as a citable exemplar rather than a vibe.
   **Fix:** Change award to the concrete fact ("Academy Award for Best Visual Effects, *Dune: Part Two*, 2025") and pin the title to an identifiable sequence (e.g. the **sandworm-riding** or **harvester-attack** beat). No replacement needed if sharpened.

---

## Coverage / balance findings

- **All 6 categories = exactly 20**, with distinct subjects and no near-duplicate works (the one mild redundancy is Red Bull Illume appearing in both action-10 and action-17 — resolved by the action-17 replacement above).
- **World-class omissions worth considering** (would *strengthen* the anchor, not block it):
  - *Genres:* no **concept/creature design** giant like H.R. Giger, and no **Norman Rockwell / golden-age narrative illustration** anchor.
  - *Diagrams:* superb canon, but no **modern interactive/Sankey energy-flow (e.g. LLNL energy chart)** and no **Florence Nightingale coxcomb/rose** — both classic honest-encoding exemplars.
  - *Action:* over-indexes on **birds + water-impact** (action-05 kingfisher dive, action-14 kingfisher splash, action-06 whale lunge, action-16 orca) — four aquatic/avian predation frames. Trimming one frees a slot for an under-covered archetype (combat sport beyond boxing, motorsport with a *named* winner, or a track-and-field decisive moment).
- **No category is below the bar on distinctness;** the imbalance is purely the action category's predation/aquatic clustering plus the 5 soft entries.

## Licensing / NSFW

- **Clean.** 120/120 rows are licensed editorial/reference-only or public-domain-work (5 PD works correctly flagged, e.g. the pre-1929 paintings). No redistribution claims, no asset bundling — it is a citation index by design.
- **SFW:** genre-17 (pregnant Demi Moore, *Vanity Fair*) and the fashion/figure entries are all editorially canonical and non-explicit. No content concern.

## Theory coverage

- **Broad and usable, not lopsided in a fatal way.** Aggregate tag prefixes: composition 126, light 72, colour 68, narrative 42, depth 33, plus dedicated tracks for `tufte`/`bertin`/`encoding`/`honest-baseline` (data-viz) and `timing`/`motion` (action). Every axis the rubric needs — composition, light, colour, depth, motion, encoding — is taught by multiple exemplars.
- **Mild lean:** composition/light/colour dominate (expected for a taste corpus); `motion` (15) and `timing` (18) live almost entirely in the action track, and `encoding`/`tufte`/`bertin` almost entirely in diagrams. That's acceptable *as long as the action track is rigorous* — which is exactly why the 5 soft action entries matter: they're the ones teaching motion/timing, so weak exemplars there directly weaken the corpus's motion vocabulary.

---

## STEER:

Before this corpus anchors the rubric, do the following — all changes confined to the **action** category plus optional strengthening elsewhere:

1. **Fix the one integrity defect (action-15):** correct the title + award to a *real* Concept Art Awards 2025 winning piece (Kpop Climax / Demon World / Huntrix Girls), OR replace with a *captured* crowd-energy photo so the action track stays photographically coherent. Do not ship a concept keyframe mislabeled with a non-existent category.

2. **Replace the 3 "practitioner/lineage" placeholders (action-02, action-17, action-20)** with named-artist, named-work, named-juried-award exemplars. Each must survive the same test the other 117 entries pass: *a specific person made a specific image that won/anchors a specific thing.* Keep the underlying principle (panning / parkour-vertical / dust-and-motion); swap the anonymous "documented practitioners" for a real credited winner.

3. **Sharpen action-18 (Dune):** state the actual award ("Academy Award for Best Visual Effects, Dune: Part Two, 2025") and pin to an identifiable sequence; drop "lineage / craft-recognised" hedging.

4. **De-cluster the action track:** four of twenty are avian/aquatic predation. Trim one and spend the slot on an under-covered decisive-moment archetype (combat sport beyond boxing, a *named* motorsport panning winner, or a track-and-field finish) so the motion/timing vocabulary spans more than wildlife.

5. **(Optional, raises the ceiling — not required for PASS):** add one or two world-class omissions as future-proofing — e.g. Giger or Rockwell in genres, the Nightingale rose / LLNL energy-flow Sankey in diagrams. These make the anchor harder to accuse of gaps.

**Re-gate criterion:** once action-02/15/17/20 name a real artist+work+juried-award (or honest "canonical"), and action-18's award string is concrete, every category will be ≥20 distinct genuinely award-tier entries with no mismatch — at which point this corpus is a **PASS**. *Light is green, trap is clean* is one fix-set away.

---

## RESOLUTION (applied)

The panel's PASS criteria are met: action-02 (→ Luca Martini, "Tunnel Exit", WSPA 2026 F1),
action-15 (→ Inès Ziouane, Abbey Road Music Photography Awards 2025), action-17 (→ Gonzalo Robert
Parraguez, Red Bull Illume 2023 Emerging), action-18 (→ concrete "Academy Award Best VFX, Dune:
Part Two 2025", sandworm-riding sequence), action-20 (→ Louise Serpa, PRCA Photographer of the Year
2005) all now name a real artist + work + juried award. action-13 author corrected (Carel du Plessis
→ **Morgan Treacy**, the verified WSPA 2026 Equestrian winner). Avian/aquatic predation reduced 4→2.
**Status: PASS.**
