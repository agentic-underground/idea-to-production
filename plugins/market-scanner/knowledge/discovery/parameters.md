# Market-scan parameters — the canonical taxonomy

> The one-copy home for **what a market scan evaluates**. The `market-scan` skill is a thin router that
> *references* this; it never restates it (token-efficiency). Each parameter carries: **what** it is,
> **how to probe** it (the question to ask, infer-first with a recommended answer), the **recommended
> default**, and the **kill-threshold** (the value at which the candidate should be rejected, not pushed
> forward). The scan walks the whole tree; the [`scoring.md`](scoring.md) rubric turns the answers into a
> keep/kill verdict.

> **Stance — adversarial, not confirmatory.** A scan's job is to *kill weak ideas early and cheaply*.
> Pressure-test every parameter; assume the opportunity is bad until each axis fails to sink it. A
> finding-free keep must be *earned*. (Same covenant as FOUNDRY's reviewer, applied to ideas.)

---

## A. Demand & problem — *is the pain real, severe, and recurring?*

| Parameter | What / how to probe | Recommended default | Kill-threshold |
|---|---|---|---|
| **Problem severity** (painkiller vs vitamin) | Is this a *painkiller* (must-solve, costs money/time now) or a *vitamin* (nice-to-have)? Probe: "what does the target do today when this bites, and what does that cost them?" | Painkiller only | Vitamin with no acute cost → **kill** |
| **Recurrence / frequency** | How often does the pain occur? Weekly/monthly recurring pain justifies a subscription; once-a-year does not. | Recurs ≥ monthly | One-off / rare → kill subscription thesis |
| **Quantified pain cost** | Put a number on it: hours wasted × hourly rate, or revenue lost. This sets the **price ceiling** (if a manual process wastes 10 h/wk at $50/h, ~$200/mo of value exists). | A computed $/period | Cost ≈ $0 or unquantifiable → kill |
| **Demand evidence** | Is anyone *already* trying to solve this? Probe for: search volume, forum/Reddit complaints, manual workarounds, people *hiring* for it, existing duct-tape tooling. | ≥ 2 independent evidence signals | No evidence anywhere → kill (you're inventing demand) |

## B. Market — *how big and how reachable?*

| Parameter | What / how to probe | Recommended default | Kill-threshold |
|---|---|---|---|
| **Market size** | TAM/SAM/SOM, or for a micro-SaaS a **reachable-customer count** (≈ **500–5,000** paying customers is often enough for a solo/small build). | A defensible SOM / reachable count | Too small to sustain *or* too broad to reach → kill |
| **Underserved vs untapped** | **Underserved** = solutions exist but are too expensive / too complex / poorly designed / missing key features. **Untapped** = no dedicated solution despite demand. Name which, and the *specific gap*. | Underserved with a named gap (lower risk than untapped) | "Crowded and well-served" → kill; "untapped because there's no demand" → kill |
| **Niche specificity** | Can you name the audience precisely (a role, an industry, a workflow), not "everyone"? | A single named segment | "All small businesses" / unsegmentable → kill (can't reach or message it) |

## C. Willingness & ability to pay — *will they actually pay, and who signs?*

| Parameter | What / how to probe | Recommended default | Kill-threshold |
|---|---|---|---|
| **Willingness to pay (WTP)** | The strongest signal is **pre-sale**: would 10–20 people pay (even $10–20) *before* it exists? Or a *fake-door* test (landing page → "pay / join waitlist"). Probe: "would you put money down today?" | A plan to get ≥ a few pre-commitments | "They'd use it if free but won't pay" → kill |
| **Budget authority** | Does the target *control budget*, or must they ask a gatekeeper? B2B sells faster to budget-holders. | The buyer ≈ the user, or a clear budget-holder | Long approval chain / no budget owner → high-friction, often kill for a small build |
| **Target price range** | The user's intended price band (from `/goal`), reconciled with the value ceiling (A: quantified pain cost) and competitor pricing (D). | A band inside the value ceiling | Price the market won't bear, or below sustainable unit economics → kill |
| **Pricing model** | Subscription (recurring pain), usage-based (variable value), or one-time (one-off value). Must match recurrence (A). | Subscription if recurring | Model contradicts the value rhythm → revise or kill |

## D. Competition & moat — *can you win, and keep winning?*

| Parameter | What / how to probe | Recommended default | Kill-threshold |
|---|---|---|---|
| **Competition density** | How many credible incumbents? Some competition *validates* demand; a vacuum can mean no demand. | A few incumbents (validated demand, room to differentiate) | Dominant entrenched incumbent with no seam → kill |
| **Pricing power** | Are incumbents **over-priced** / over-built for this niche? Over-priced incumbents are an opening (undercut or right-size). | A pricing/right-sizing wedge exists | No pricing wedge and no feature wedge → kill |
| **Switching cost / differentiation** | What makes a user switch *to* you and *stay*? A concrete missing feature, a 10× simpler UX, a price cut, lock-in/data gravity. | A named, defensible wedge | "Same as incumbents but new" → kill |

## E. Reachability & fit — *can you reach them, build it, and is it yours to build?*

| Parameter | What / how to probe | Recommended default | Kill-threshold |
|---|---|---|---|
| **Acquisition channel** | A *specific, affordable* way to reach the audience (a subreddit, a directory, SEO intent, a community, a partnership). "We'll do marketing" is not a channel. | One concrete channel named | No reachable channel → kill (great product, no door) |
| **Time-to-MVP** | How fast can a thin, shippable first slice exist? Sooner = cheaper to validate. | A first slice in days/small weeks | Months before any user can try it → kill for a lean build |
| **Stack-fit** | Does it fit the builder's stack — i.e. FOUNDRY's value-handlers (Rust, Python, FastAPI, JS/TS, React, vanilla-JS, CSS, the Rust-webapp one-shot)? A buildable opportunity is one the conveyor can carry. | Maps cleanly to ≥ 1 handler | Needs a capability FOUNDRY can't staff → kill or descope |
| **Founder / builder-market fit** | Does the *builder* have the interest, domain insight, or unfair advantage to stick with this? Discovery without commitment dies. | Genuine interest + some edge | Zero interest / no edge → kill (you won't finish it) |

---

## How the parameters compose

A strong opportunity is a **conjunction**: real, severe, recurring pain (**A**) in a reachable,
right-sized, underserved market (**B**) where the buyer will and can pay (**C**), with a defensible
wedge against incumbents (**D**), that the builder can actually reach, build, and wants to build (**E**).
A single hard kill-threshold sinks the candidate — surface it early and **re-rank**, do not push a holed
boat downstream. Borderline parameters become **open questions** carried into the opportunity brief and,
later, the IDEA package. See [`scoring.md`](scoring.md) for the verdict rubric.
