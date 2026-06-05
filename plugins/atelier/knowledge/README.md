# ATELIER Knowledge — the design canon (define-once)

This directory is the **define-once** home for the facts ATELIER obeys. Skills and the reviewer agent
reference these via `${CLAUDE_PLUGIN_ROOT}/knowledge/...`; they never restate them. One fact, one copy.

| You need… | Read |
|---|---|
| The governing covenant + the three pillars (this plugin's anchor) | [`covenant.md`](covenant.md) |
| **The screen design canon** — the named theory the reviewer cites | [`canon/README.md`](canon/README.md) |
| **The convergent designer↔reviewer loop** + the design-fitness rubric | [`protocols/design-critique-loop.md`](protocols/design-critique-loop.md) |

## Layout
```
knowledge/
├── covenant.md                 # three pillars + SOLID self-improvement covenant (this plugin's anchor)
├── canon/                      # the screen design canon — what makes the reviewer an EXPERT, not generic
│   ├── README.md               #   the canon index + how to wield it (cite the principle, not "looks off")
│   ├── visual-foundations.md   #   Gestalt · visual hierarchy · colour · type · spacing/grid
│   ├── interaction-laws.md     #   the UX laws · Nielsen's heuristics · Norman's emotional design (delight)
│   └── accessibility.md        #   WCAG 2.2 AA + the method (automated catches a fraction; judge the rest)
└── protocols/
    └── design-critique-loop.md # the design-fitness rubric + the bounded, measurable, anti-ping-pong loop
```

> **Compose, don't duplicate.** Where the `foundry` plugin is installed, its `frontend` design-system
> owns the *source-level* contract (`@front-end` INTENT markers, `definition-of-good`, the build-time
> `design-critic`). ATELIER reviews the **rendered experience** of any app and carries the **deeper SOTA
> canon**; it reads those markers by capability when present and extends them — it never restates them.
