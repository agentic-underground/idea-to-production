# server/ — the MCP server (FOUNDRY builds this)

This directory is intentionally a **spec + scaffold**, not a finished implementation. The server is built by
**dogfooding the marketplace's own pipeline** — it is the headline demonstration that idea-to-production can
build its own infrastructure:

1. **foundry** consumes [`../EARS.md`](../EARS.md) and builds this server **test-first** to the 100% line+branch
   coverage floor. Every EARS requirement (U/E/X/S/O/N) becomes a failing test first, then the minimum code to
   green it. The X-requirements (reject arbitrary graphs, path traversal, out-of-bounds params, cross-token
   results) are non-negotiable coordinates.
2. **sentinel** runs the security gate on the result — `/security-gate`, `/secret-scan`, `/dependency-audit`,
   semgrep — and must pass before ship.
3. **pressroom** documents it and switches [`handler-comfyui`](../../plugins/pressroom/agents/handler-comfyui.md)
   from raw `curl` to `mcp__comfyui__*` tools.

## What foundry will build here

- `comfyui_mcp/server.py` — the MCP entrypoint exposing the five tools (`list_models`, `set_model`,
  `list_templates`, `submit_prompt`, `get_result`). No tool accepts a raw node graph.
- `comfyui_mcp/allowlist.py` — load checkpoints from `MODEL_ALLOWLIST_DIR`; load templates from
  [`../workflows/`](../workflows/); reject anything outside both.
- `comfyui_mcp/validate.py` — param schema (bounded steps/seed, length-capped prompts, model ∈ allowlist);
  the template-fill that touches ONLY the template's declared `fillable` paths.
- `comfyui_mcp/comfyui_client.py` — the private-network client (`COMFYUI_INTERNAL_URL`): submit, poll, and a
  **path-confined** `/view` proxy (canonicalise filename/subfolder under the output dir).
- `comfyui_mcp/auth.py` — token check on every request (`MCP_AUTH_TOKEN`); job ownership by token.
- `tests/` — one test per EARS requirement; coverage floor enforced in CI.

Until foundry builds it, PRESSROOM's `handler-comfyui` runs the **Phase-0 raw-HTTP MVP** against
`$PRESSROOM_COMFYUI_URL` directly (see [`../ROADMAP.md`](../ROADMAP.md)).
