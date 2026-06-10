---
name: template-meta-strip
description: The txt2img-basic.json template ships a _meta block that must be deleted before POST or ComfyUI rejects the prompt
metadata:
  type: feedback
---

When filling the allowlisted `/tmp/txt2img-basic.json` template and POSTing to `$COMFYUI/prompt`, **delete the top-level `_meta` key first** (`jq 'del(._meta)'`).

**Why:** ComfyUI iterates every top-level key as a node and requires `class_type`. `_meta` (the template's documentation/fillable block) has none, so the API returns `{"error":{"type":"invalid_prompt","message":"Cannot execute because a node is missing the class_type property.","details":"Node ID '#_meta'"}}` and `prompt_id` comes back empty. The failure is silent if you only read `.prompt_id` — it just yields "".

**How to apply:** In the Draft step, after `jq` fills ckpt/prompts/geometry, pipe through `del(._meta)` (or include it in the same jq filter) before building the `{prompt, client_id}` submit payload. If a submit returns an empty prompt_id, re-run the POST with `curl -s` (drop `-f`) and `jq .` the body to surface the error.
