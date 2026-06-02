# Tier Assignment Reference

> For FOUNDRY §4. Defines how PRIORITY_STATUS maps to production tiers and
> how token budget caps are calculated and adjusted.

---

## PRIORITY_STATUS Values

Each roadmap item carries a `PRIORITY_STATUS` field. Recognised values:

| Value | Meaning |
|---|---|
| `CRITICAL` | Must ship; blocks everything else |
| `HIGH` | High business value; target current cycle |
| `MEDIUM` | Significant value; target within 2 cycles |
| `LOW` | Nice to have; defer when budget is tight |
| `BACKLOG` | Captured but not yet scheduled |

Items without an explicit PRIORITY_STATUS default to `BACKLOG`.

---

## Default Tier Assignment

| PRIORITY_STATUS | Default tier |
|---|---|
| `CRITICAL` | PRIMARY |
| `HIGH` | PRIMARY |
| `MEDIUM` | SECONDARY |
| `LOW` | TERTIARY |
| `BACKLOG` | TERTIARY+ (last) |

---

## Promotion Rules

LEAD ENGINEER may promote an item to an earlier tier when:

1. **Infrastructure dependency**: A MEDIUM item provides a shared component
   (data model, API layer, auth service) that one or more PRIMARY items depend
   on. Promote it ahead of its dependents.

2. **Blocking chain**: A LOW item that blocks three or more SECONDARY items is
   promoted to SECONDARY to unblock the chain.

3. **Token efficiency**: Two small MEDIUM items together cost fewer tokens than
   one large HIGH item. Promote them to PRIMARY when the budget has headroom.

Promotions are recorded in `doc/FOUNDRY_PLAN.md` with rationale.

---

## Token Budget Caps (Default)

| Tier | Default budget share |
|---|---|
| PRIMARY | 40% of total estimated session budget |
| SECONDARY | 35% of total estimated session budget |
| TERTIARY | 20% of total estimated session budget |
| TERTIARY+ | Remainder; processed in subsequent sessions |

LEAD ENGINEER adjusts these caps based on actual item complexity after the
deep dive (§5). Adjustments are documented in `doc/FOUNDRY_PLAN.md`.

---

## Between-Tier Budget Reconciliation

After each tier completes, compare actual vs estimated token cost:

```
delta = actual_tokens - estimated_tokens
adjustment_factor = actual_tokens / estimated_tokens
```

Apply `adjustment_factor` to remaining tier estimates. If a tier is running
significantly over budget (adjustment_factor > 1.3), surface to user before
proceeding:

> "Tier PRIMARY ran 40% over estimate (Nk actual vs Nk estimated).
> Adjusted estimates for SECONDARY: ~Nk (was ~Nk).
> Proceed, or reduce scope for SECONDARY?"

---

## Staggered Flow Diagram

```
SESSION START
     │
     ▼
┌─────────────┐
│   PRIMARY   │  ← CRITICAL + HIGH items (parallel where safe)
│  Tier runs  │
└──────┬──────┘
       │ reconcile budget
       ▼
┌─────────────┐
│  SECONDARY  │  ← MEDIUM items (parallel where safe)
│  Tier runs  │
└──────┬──────┘
       │ reconcile budget
       ▼
┌─────────────┐
│   TERTIARY  │  ← LOW items
│  Tier runs  │
└──────┬──────┘
       │ if budget remains
       ▼
┌─────────────┐
│  TERTIARY+  │  ← BACKLOG items (next session if budget exhausted)
└─────────────┘
```

---

## IDEA_COST.jsonl Integration

After 3+ completed cycles, LEAD ENGINEER should query IDEA_COST.jsonl to
replace heuristic estimates with actuals:

```python
# Pseudocode: estimate from history
similar_items = [r for r in cost_records
                 if r['ears_count'] in range(target_ears - 1, target_ears + 2)
                 and target_stack in r['stack']]
avg_tokens = mean([r['tokens_in'] + r['tokens_out'] for r in similar_items])
```

This replaces the complexity-bracket table in FOUNDRY §4.3 with data-driven
estimates, the key long-term value of IDEA_COST tracking.
