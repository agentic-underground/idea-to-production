# comfyui-mcp — Roadmap

Two phases: the MVP that already works, and the secured build that earns the name.

## Phase 0 — MVP (shipped, with an honest gap)

`handler-comfyui` talks **raw HTTP** to a live ComfyUI server via `$PRESSROOM_COMFYUI_URL` (default
`http://10.10.10.163:8188`, the i9 workstation — ComfyUI 0.3.71 on an RTX 3090). It lists checkpoints (`GET /object_info/CheckpointLoaderSimple`),
sets the model into an inline `txt2img` template, submits (`POST /prompt`), polls (`GET /history/{id}`), and
downloads (`GET /view`). It degrades gracefully — a 3s `/system_stats` probe; if unreachable it declines so the
illustrator fills the A/B slot with a vector option.

**Known, time-boxed risk:** the only trust boundary is the LAN. ComfyUI's API would accept an arbitrary node
graph; the handler mitigates by only ever filling a fixed template, but nothing *enforces* that server-side.
Phase 1 enforces it.

## Phase 1 — The secured MCP server (the build)

Built by dogfooding the marketplace's own pipeline:

1. **foundry** consumes [`EARS.md`](EARS.md) and builds `server/` **test-first** to the 100% line+branch
   coverage floor — the five MCP tools, the allowlist loaders, the param validators, the `/view` proxy.
2. **sentinel** runs the security gate on the result — `/security-gate`, `/secret-scan`,
   `/dependency-audit`, semgrep — and must pass before ship. The security model:
   - **workflow-template allowlist** — `submit_prompt` accepts a `template_id`, never a node graph (removes
     arbitrary-node execution + SSRF via URL-loading nodes);
   - **input validation** — params schema-checked (steps/seed bounded, prompt length-capped, model ∈ allowlist);
   - **model allowlist** — only checkpoints physically in the bind-mounted `DIFFUSION_MODELS` are selectable;
   - **path-traversal-safe `/view`** — filename/subfolder canonicalised and confined to the output dir;
   - **network isolation** — ComfyUI runs on a private container network, never exposed; only the MCP port is
     published;
   - **authn** — a token on the MCP endpoint; `.mcp.json` approval-gating is the second layer.
3. **container** — [`container/`](container/) builds ComfyUI + the server, bind-mounts `DIFFUSION_MODELS` (the
   i9's 1T_990 drive), puts ComfyUI on a private net, publishes only the MCP port.
4. **pressroom** documents it; `handler-comfyui` switches from `curl` to `mcp__comfyui__*`; the pinned
   `.mcp.json` entry is added to the marketplace and listed in `PREREQUISITES/`.

## Phase 2 — Later

- Per-template parameter UIs / presets for common figure kinds (hero, diagram-accent, texture).
- Multiple backends (a pool of ComfyUI workers) behind one MCP endpoint.
- Cache by (template_id, params, checkpoint) so identical figures are free.
