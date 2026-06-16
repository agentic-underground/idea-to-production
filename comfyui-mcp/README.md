# comfyui-mcp — a demonstrably-secure ComfyUI backend

A buildable sub-project (a deployable *service*, not a Claude Code plugin): a **containerised ComfyUI**
fronted by a dedicated **MCP server** that lets agents generate images through a narrow, validated, allowlisted
surface — never raw ComfyUI. It is the secured backend for PRESSROOM's
[`handler-comfyui`](../plugins/pressroom/agents/handler-comfyui.md).

## Why this exists

`handler-comfyui` today talks **raw HTTP** to a live ComfyUI server (`$PRESSROOM_COMFYUI_URL`, default the i9
workstation at `http://10.10.10.19`). That MVP works, but the only trust boundary is the LAN — ComfyUI's API
accepts arbitrary node graphs, and some nodes load URLs/files (arbitrary-execution and SSRF surface). This
sub-project closes that gap with a server that exposes only what a figure needs and validates everything.

## The shape

```
comfyui-mcp/
├── README.md            # this file
├── ROADMAP.md           # MVP-now (raw HTTP) vs the full secured build, phased
├── EARS.md              # the spec FOUNDRY consumes to build server/ test-first
├── server/              # the MCP server (foundry-built, sentinel-secured) — see server/README.md
├── workflows/           # ALLOWLISTED workflow templates — the ONLY graphs the server will submit
│   └── txt2img-basic.json
└── container/
    ├── Dockerfile       # ComfyUI + the MCP server
    └── compose.yml      # bind-mount DIFFUSION_MODELS, private network, only the MCP port published
```

## MCP tools (the whole surface)

| Tool | Does | Validates |
|---|---|---|
| `list_models` | list selectable checkpoints | only files physically present in the bind-mounted `DIFFUSION_MODELS` allowlist |
| `set_model` | select the checkpoint for subsequent prompts | name ∈ allowlist |
| `list_templates` | list allowlisted workflow templates | — |
| `submit_prompt` | fill an allowlisted template + submit | `template_id` ∈ allowlist; params schema-checked (bounded steps/seed, length-capped prompt, model ∈ allowlist) |
| `get_result` | poll status + fetch the PNG | `job_id` owned by caller; `/view` params canonicalised, confined to the output dir (no path traversal) |

Agents **never** pass a node graph. They pick a `template_id` and fill named parameters; the server owns the
graph. This single decision removes the arbitrary-node / SSRF class.

## Built by dogfooding the marketplace

This is the headline: the marketplace builds its own infrastructure. [`EARS.md`](EARS.md) → **foundry** builds
`server/` test-first to the 100% coverage floor → **sentinel** runs `/security-gate` + `/secret-scan` +
`/dependency-audit` → **pressroom** documents it. Then `handler-comfyui` switches from raw `curl` to
`mcp__comfyui__*` tools and the Phase-0 gap is closed. The build is tracked in the marketplace roadmap tree
[`.i2p/roadmap/`](../.i2p/roadmap/) as EPIC [73] (Phase 1: items 74–78) + Phase 2 (79–80), migrated under
roadmap item [47]; the implement-or-archive disposition [45] is resolved (implement).

## License
Dual-licensed under **MIT OR Apache-2.0** (matching the marketplace).
