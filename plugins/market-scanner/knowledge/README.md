# MARKET-SCANNER Knowledge — the discovery canon (define-once)

This directory is the **define-once** home for the facts the scanner obeys. Skills reference these via
`${CLAUDE_PLUGIN_ROOT}/knowledge/...`; they never restate them. One fact, one copy.

| You need… | Read |
|---|---|
| The governing covenant + the three pillars (this plugin's anchor) | [`covenant.md`](covenant.md) |
| **What a market scan evaluates** — the full parameter taxonomy | [`discovery/parameters.md`](discovery/parameters.md) |
| How a scan reaches a **keep / park / kill** verdict + the kill ledger | [`discovery/scoring.md`](discovery/scoring.md) |
| The **goal → scan → narrow** loop protocol | [`discovery/goal-loop.md`](discovery/goal-loop.md) |

## Layout
```
knowledge/
├── covenant.md            # three pillars + SOLID self-improvement covenant (this plugin's anchor)
└── discovery/
    ├── parameters.md      # the canonical market-scan parameter taxonomy
    ├── scoring.md         # keep/park/kill rubric + the kill ledger
    └── goal-loop.md       # /goal → /market-scan → narrow loop
```
