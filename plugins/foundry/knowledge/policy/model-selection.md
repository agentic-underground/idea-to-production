# Model-Selection Policy (canonical)

Every FOUNDRY agent runs on the model that maximises **value-per-token** for its work class.
This is the single source of truth: agents reference this table instead of pinning model IDs
in their own frontmatter, so the whole fleet can be re-tiered in one edit (and pinned IDs
cannot silently age out).

## The policy

| Work class | Model tier | Why | Roles |
|---|---|---|---|
| **Spec & narrative** — EARS, Gherkin feature docs, story tests, ADRs | **opus** | high-judgement synthesis; an error here propagates downstream | `ds-step-1-ears`, `ds-step-2-feature-docs`, `ds-step-story-tests`, `handler-architect` |
| **Review** — every reviewer role + the inspector | **opus** | a false PASS costs more in rework than the opus tokens saved | `reviewer`, `inspector` |
| **Test code authoring** — failing tests, coverage chasing | **haiku** | high-volume, low-judgement, repetitive | `ds-step-3-tests`, `coverage-loop-agent` |
| **Everything else** — planning, implementation, sync, commit, orchestration | **sonnet** | the capable default | orchestrators, `ds-step-{0,4,5,6,7,8,9}`, `flaky-test-fixer` |

**Value handlers** (`handler-{python,js,react,fastapi,css,playwright,vanilla-js}`) carry `model: inherit`
and are spawned with the tier appropriate to the **phase** they are staffing:
- TEST phase → **haiku** (test code is high-volume)
- IMPLEMENT phase → **sonnet** (implementation)
- STORY phase → **opus** (narrative proof)

## Resolving a tier to a concrete model ID

Tiers map to the latest model in each family. Resolve at spawn time, do not hardcode:

| Tier | Current model ID |
|---|---|
| opus | `claude-opus-4-8` |
| sonnet | `claude-sonnet-4-6` |
| haiku | `claude-haiku-4-5` |

> When a new model family ships, update **only this table** and the whole fleet re-tiers.
> Agents that legitimately must pin a model state the *tier* here and let this doc carry the ID.

## Rule
- Never downgrade a tier to save tokens — the policy already encodes the value/token tradeoff.
- An agent whose `model:` disagrees with this table is a drift defect the `inspector` reports.
