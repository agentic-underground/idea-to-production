---
name: flow-server-item-contract
description: The item JSON shape GET /api/items returns, and the deps[] extension the flow-canvas relies on for connectors
metadata:
  type: reference
---

The flow-server's `GET /api/items` (auth: `Authorization: Bearer <token>`) returns an
array of items shaped by `flow-server/src/api.rs::item_json`:
`{ id, title, status, gate, tokens, model }` where
`status ∈ {"do","doing","done"}` and `gate ∈ {"go","wait"}` (serde lowercased enums
in `src/domain/model.rs`).

The REST `/api/items` does NOT currently expose dependency edges. The flow-canvas
therefore treats each item as optionally carrying `deps: string[]` (ids it depends
on) — present in the test fixture and forward-compatible if the server later adds it;
the canvas degrades gracefully (no connectors) when `deps` is absent.

Per-job model (roadmap #8): items may also carry `defaultModel`. The canvas treats
the DEFAULT as `defaultModel ?? model`, so isOverride ⇔ a defaultModel is present AND
differs from model. If the Rust side does NOT yet emit `defaultModel`, the item shows
as "default" and the canvas pins the resolved default onto its OWN working copy when
an override is applied (so override-vs-default stays decidable client-side). Graceful
degrade — do NOT edit Rust to add defaultModel without a roadmap item.

Verbs the canvas uses:
- `POST /api/items/:id/gate` `{gate:"wait"|"go"}` → `{ok:true}` / typed error
- `POST /api/items/:id/model` `{model: "<allowlisted id>" | null}` → `{ok:true}` /
  typed error (null clears the override → revert to default; off-allowlist ⇒ server refuses)
- `POST /api/connection/validate` `{from,to}` → 200 `{ok:true}`, or 4xx
  `{error:"cycle"|"broken_dep"|"unknown", message}` (409 cycle/broken_dep, 404 unknown)
- `POST /api/items/:id/annotate` `{text}` → `{ok:true}` (appends comment to plan markdown; #4)
- `POST /api/items/:id/rewrite` `{comment}` → `{draft}` (new draft number from the agent; #4)
- `GET /api/events` → array of `{kind, text, ...}`; the masthead feed (#6) filters to
  `kind==="sys_msg"` and renders newest-first. Degrade gracefully if it errors (empty feed).

**How to apply:** when extending the canvas to draw the dependency tree against the
LIVE server, confirm whether the Rust side has started returning edges/deps; if not,
the connector data still has to come from a deps-bearing source. Do NOT edit Rust to
add it without an explicit roadmap item — roadmap #2 is frontend-only.
