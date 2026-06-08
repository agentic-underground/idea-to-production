# comfyui-mcp — EARS requirements (FOUNDRY's build input)

The spec FOUNDRY consumes to build `server/` test-first. EARS = Easy Approach to Requirements Syntax:
*ubiquitous*, *event-driven* (WHEN), *state-driven* (WHILE), *unwanted-behaviour* (IF…THEN), *optional* (WHERE).
Every requirement is a test coordinate; the sum of the green tests is the server.

## Glossary
- **Allowlisted template** — a workflow JSON in `workflows/`, the only graph the server will ever submit.
- **Model allowlist** — the set of checkpoint files physically present in the bind-mounted `DIFFUSION_MODELS`.
- **Caller** — an authenticated MCP client (PRESSROOM's `handler-comfyui`).

## Ubiquitous (always true)
- U1. The server SHALL expose exactly five MCP tools: `list_models`, `set_model`, `list_templates`,
  `submit_prompt`, `get_result` — and no tool that accepts a raw ComfyUI node graph.
- U2. The server SHALL reach ComfyUI only over the private container network; ComfyUI SHALL NOT be reachable
  from outside the container network.
- U3. Every MCP request SHALL carry a valid auth token; a missing/invalid token SHALL be rejected with no
  side effect.

## Event-driven (WHEN <trigger>, the server SHALL <response>)
- E1. WHEN `list_models` is called, the server SHALL return only checkpoint names present in the model
  allowlist (the bind-mounted folder), never the raw `/object_info` node list.
- E2. WHEN `set_model` is called with a name in the allowlist, the server SHALL record it as the active model
  and return confirmation.
- E3. WHEN `submit_prompt` is called with a valid `template_id` and valid params, the server SHALL fill that
  template, submit it to ComfyUI, and return a `job_id`.
- E4. WHEN `get_result` is called with a `job_id` owned by the caller, the server SHALL return status, and on
  completion the PNG bytes fetched via a path-confined `/view`.

## Unwanted behaviour (IF <condition>, THEN the server SHALL <mitigation>)
- X1. IF `submit_prompt` is given a `template_id` not in the allowlist, THEN the server SHALL reject the
  request and submit nothing.
- X2. IF any submitted payload contains a node graph, a node not used by the named template, or a URL/file
  input, THEN the server SHALL reject it (no arbitrary-node execution, no SSRF).
- X3. IF `set_model`/`submit_prompt` names a model not in the allowlist, THEN the server SHALL reject it and
  fetch no remote model.
- X4. IF `get_result`'s `filename`/`subfolder` resolves outside the output directory (path traversal), THEN
  the server SHALL reject it.
- X5. IF a param is out of bounds (steps/seed beyond limits, prompt over the length cap), THEN the server
  SHALL reject the request with a validation error and submit nothing.
- X6. IF a `job_id` is not owned by the calling token, THEN the server SHALL refuse to return its result.

## State-driven (WHILE <state>, the server SHALL <behaviour>)
- S1. WHILE ComfyUI is unreachable, the server SHALL return a typed "backend unavailable" error to every
  generation call (so the handler declines cleanly), and SHALL recover automatically when it returns.

## Optional (WHERE <feature present>, the server SHALL <behaviour>)
- O1. WHERE a template declares a transparent-VAE / background-removal node, `submit_prompt` SHALL be able to
  request an alpha-channel PNG (the dark-mode "groundless raster" path).

## Non-functional
- N1. Param validation SHALL run before any network call to ComfyUI.
- N2. The server SHALL hold no secrets in source; the auth token and endpoint SHALL come from the environment
  (sentinel `/secret-scan` clean).
- N3. 100% line + branch coverage is the build floor (FOUNDRY mandate), including every X-requirement
  rejection path.
