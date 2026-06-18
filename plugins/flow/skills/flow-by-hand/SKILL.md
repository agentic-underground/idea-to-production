---
name: flow-by-hand
description: >
  The markdown fallback for FLOW's roadmap MCP. Use this when the flow-mcp server is NOT available —
  no Ruby >= 3.3.8 on the host, or the MCP is not connected — and you still need to read or advance the
  roadmap. It is the agent-driven equivalent of the flow-mcp verbs: you perform each verb BY HAND
  over the same on-disk files (.flow/ + the .i2p/roadmap/ tree), with the same semantics the server
  guarantees (../../flow-mcp/spec/EARS.md), just slower and with no dedicated process. Trigger with
  /flow:flow-by-hand, or when the onboard hook reports no compliant Ruby. Prefer the real MCP whenever
  it is connected (mcp__…__flow-mcp__* tools present) — this is the fallback path only.
metadata:
  type: fallback
---

# flow-by-hand — operate the roadmap without the server

You are the engine. The flow-mcp server is unavailable, so you perform its work by editing the same
files it would. **The authoritative contract is [`../../flow-mcp/spec/EARS.md`](../../flow-mcp/spec/EARS.md)** —
when in doubt, do exactly what the EARS statement for that verb requires. Behave identically to the
server; you are only slower.

## When to use this
- The onboard hook reported **no Ruby ≥ 3.3.8** on the host, **or**
- `mcp__…__flow-mcp__*` tools are absent (the MCP isn't connected).

If the MCP *is* connected, **stop** — call the real verbs instead; they are ~0-token and exact.

## The files (the server's state lives here)
Resolve the **project root** by walking up from the cwd to the directory that contains `.i2p/roadmap/`.
All paths below are relative to that root.

- **`.i2p/roadmap/{backlog,do,doing,done}/*.md`** — the roadmap tree. The **folder is the status**
  (`backlog`/`do` → DO, `doing` → DOING, `done` → DONE). Each file has YAML front-matter:
  `id` (a number N → item id `item-N`), `title`, `status` (`PENDING`/`IN PROGRESS`/`COMPLETE`),
  `depends_on` (`"#1, #2"` or `—`). **This tree is the source of truth for item existence/title/status.**
- **`.flow/events.jsonl`** — append-only event log, one `kind`-tagged JSON object per line. The
  record of mutations. Kinds: `item_created, item_deleted, gate_set, status_posted, spend_appended,
  model_set, connection_added, connection_removed, annotated, rewrite_requested, sys_msg`
  (`item_upserted` also appears in legacy logs).
- **`.flow/gates.json`** — `{ "item-1": "wait"|"go", … }`, sorted by key. The WAIT/GO gate per item.
- **`.flow/ROADMAP.flow.md`** — a rendered board (derived; you may regenerate it but readers should
  not rely on it being fresh in fallback mode).
- **`.flow/telemetry.jsonl`** — token-spend records (derived).

> Gate, token, draft, and model state that is NOT in the tree lives only in `events.jsonl` + `gates.json`.
> Reconstruct an item's current state by reading the tree (existence/title/status) and folding the
> events (gate, tokens, draft, model) — newest event wins per field.

## The verbs, by hand

**Reads (no mutation):**
- **render_roadmap / list_items** — read the tree (and fold gates/tokens from the files). Group by
  status; for pending items split WAIT vs GO using `gates.json`. Report `id, title, status, gate,
  tokens, model, draft` per item.
- **get_item `<id>`** — find the item's tree file + fold its events; report its fields, its `deps`
  (the `depends_on`), and its `annotations` (the `text` of its `annotated` events, in log order).
- **list_events `[kind]`** — read `events.jsonl` oldest-first; if a `kind` is given, keep only that kind.
- **ping** — report that you are in fallback mode, the item count (tree files), and the source path.

**Mutations — for each, (a) update the file(s), then (b) append the matching event line to
`events.jsonl`:**
- **set_wait_go `<id> <wait|go>`** — set the id's value in `gates.json` (create it / keep it sorted);
  append `{"kind":"gate_set","id":"<id>","gate":"<wait|go>"}`. Allowed even if currently WAIT.
- **post_status `<id> <do|doing|done>`** — **refuse if the item's gate is `wait`** (that is the WAIT
  guard). Otherwise **move the item's tree file** into the destination folder (`do`/`doing`/`done`)
  and rewrite its `status:` front-matter to `PENDING`/`IN PROGRESS`/`COMPLETE`; append
  `{"kind":"status_posted","id":"<id>","status":"<…>"}`.
- **append_spend `<id> <delta>`** — **refuse if the gate is `wait`**. Add `delta` to the item's own
  token tally, **and to every transitive ancestor** (each item it `depends_on`, recursively — the
  roll-up still applies even to a WAIT ancestor). Append
  `{"kind":"spend_appended","id":"<id>","delta":<delta>,"total":<new total>}` and a telemetry line.
- **set_item_model `<id> <model>`** — append `{"kind":"model_set","id":"<id>","model":"<model>"}`.
- **validate_connection `<from> <to>`** — check both ids exist, `from != to`, and adding `from→to`
  would not create a cycle (is `from` already reachable from `to`?). Report ok / cycle / unknown;
  mutate nothing.
- **mutate_connection add|remove `<from> <to>`** — validate (as above for add; for remove the edge
  must already exist), edit the dependent's `depends_on`, append `connection_added`/`connection_removed`.
- **annotate `<id> <text>`** — append the block
  `"\n<!-- annotation: <id> -->\n### Annotation on \`<id>\`\n\n<text>\n"` to the item's
  `doc/<TITLE>_PLAN.md` if it exists, else to `.flow/annotations/<id>.md`; append `annotated`.
- **request_rewrite `<id> <comment>`** — increment the item's draft counter (fold from prior
  `rewrite_requested` events), append `{"kind":"rewrite_requested","id":"<id>","comment":"<…>","draft":<n>}`.
  Allowed even while WAIT.
- **append_sysmsg `<text>`** — append `{"kind":"sys_msg","text":"<text>"}`.
- **create_item `<title> [status] [deps]`** — pick the next free number N (max existing id + 1); write
  `.i2p/roadmap/<status-folder>/<N>.md` with `id`/`title`/`status`/`depends_on` front-matter; append
  `{"kind":"item_created","id":"item-N","title":"<title>"}` (+ a `connection_added` per dep). The tree
  owns identity, so the file is the durable record.
- **delete_item `<id>`** — delete the item's tree file; prune the id from other items' `depends_on`;
  append `{"kind":"item_deleted","id":"<id>"}`.

## Discipline
- **WAIT gates `post_status` and `append_spend` only** — never `set_wait_go`, `request_rewrite`,
  `create_item`/`delete_item`, or the ancestor roll-up.
- **Append, never rewrite** `events.jsonl` (except pruning a deleted item's id from a `depends_on`
  front-matter line in the tree). It is the authoritative runtime history.
- Keep `gates.json` valid JSON, sorted by key.
- **Ownership:** the `.i2p/roadmap/` tree owns identity (existence/title/status/deps); `events.jsonl`
  owns runtime (gate/tokens/model/draft/annotations). When the real MCP returns it **ingests the tree
  then replays `events.jsonl`** (ingest → replay), so both your tree edits and your event appends are
  picked up — **stay faithful to the formats above** so the hand-off is clean.
- This is the slow path: as soon as a Ruby ≥ 3.3.8 is installed and `flow-mcp` is approved in `/mcp`,
  go back to the real verbs.
