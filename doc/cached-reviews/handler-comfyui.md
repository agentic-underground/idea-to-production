# Cached review — PRESSROOM handler-comfyui

**Target file:** `plugins/pressroom/agents/handler-comfyui.md`  
**Unit:** `handler-comfyui`  
**Findings:** 9 · **Capability-uplift proposals:** 6

> Cached output from the adversarial Review stage — raw reviewer findings BEFORE the refute/verify pass and BEFORE any edits were applied. Severity: CRITICAL / HIGH / MEDIUM / LOW / SUGGESTION.

## Findings

### 1. [HIGH] Doctrine's only concrete submit script fails at jq compile time — $CKPT and $SEED are never bound

**Evidence:** Lines 83–91: `jq --arg pos "$POSITIVE" --arg neg "$NEGATIVE" ' del(._meta) | .["4"].inputs.ckpt_name=$CKPT ... | .["3"].inputs.seed=$SEED ...'`. The filter is single-quoted, so $CKPT/$SEED are jq variables, and no `--arg CKPT`/`--argjson SEED` binds them. Verified empirically: jq exits 3 with "jq: error: $CKPT is not defined ... 2 compile errors". Consequence chain: /tmp/wf.json is empty → line 93's `--slurpfile p /tmp/wf.json` makes `$p[0]` null → the handler POSTs `{"prompt":null}` → `PID` becomes null/empty → the line-95 poll loop spins forever. Bonus collision: jq's failure exit code (3) is the same code line 64 uses as the deliberate decline signal, so a script failure is indistinguishable from a clean decline.

**Recommendation:** Bind the variables: add `--arg CKPT "$CKPT" --argjson SEED "$SEED"` (SEED via --argjson so it stays numeric — --arg would inject a string into KSampler.seed). Then gate the POST on a validity check of the filled file, e.g. `jq -e '.["3"].inputs.seed and .["4"].inputs.ckpt_name' /tmp/wf.json || decline`, and pick a decline exit code that cannot be produced by a tool failure.

### 2. [HIGH] Submit-and-poll has no timeout and no error branch — contradicts the handler's own 'decline cleanly, do not block' prime directive

**Evidence:** Line 95: `until curl -sf "$COMFYUI/history/$PID" | jq -e --arg p "$PID" '.[$p].outputs' >/dev/null 2>&1; do sleep 3; done`. ComfyUI's POST /prompt returns `{"error":..., "node_errors":...}` (or HTTP 400) for a rejected graph — then PID is null and /history/null never yields outputs; a job that errors server-side (OOM, missing asset) writes a history entry with `status.status_str: "error"` and NO `outputs` — the loop spins forever in both cases. This directly contradicts lines 40–41: "A 3-second probe before any work; if it fails, decline — do not block." The covenant itself anticipates "a template that OOMs at 24GB" (line 132) yet the execution path cannot survive one.

**Recommendation:** After POST, branch on `.prompt_id // empty` and surface `.node_errors` in the hand-back. Bound the poll (e.g. `for i in $(seq 1 120)` with 3 s sleeps, budget scaled by steps×resolution), check `.[$p].status.status_str == "error"` each tick, and on budget exhaustion POST `$COMFYUI/interrupt` then decline with the diagnosis.

### 3. [HIGH] Default endpoint is the author's private LAN workstation IP — machine-specific coupling in a live marketplace surface

**Evidence:** Lines 29–32 and 63: `COMFYUI="${PRESSROOM_COMFYUI_URL:-http://10.10.10.163:8188}"` … "(default the i9 workstation, ComfyUI port 8188)". For every install other than the maintainer's, the default resolves to a stranger's RFC-1918 address — the probe either fails (handler always declines, silently degrading the plugin to vector-only) or, worse, pokes an unrelated device on the installer's network. inspection-core.md Phase 0/Phase 2 names "portability (no machine-specific coupling)" a defect class for agent definitions. The same IP is restated in knowledge/comfyui-model-guide.md, compounding the coupling.

**Recommendation:** Default to ComfyUI's own default bind, `http://127.0.0.1:8188`, and state that remote rigs are reached ONLY via `$PRESSROOM_COMFYUI_URL`. Keep the i9/RTX-3090 details as an example deployment note, not the baked default.

### 4. [MEDIUM] Missing SUBJECT_MATTER_UNDERSTANDING contract (carried by every foundry handler, absent from every pressroom agent)

**Evidence:** Marketplace convention: every agent carries the SOLID covenant AND the SUBJECT_MATTER_UNDERSTANDING contract. Foundry handlers state it explicitly — plugins/foundry/agents/handler-ansible.md line 10: "Carries the SOLID self-improvement covenant and the project's SUBJECT_MATTER_UNDERSTANDING." `grep -rl SUBJECT_MATTER plugins/pressroom/` returns nothing — handler-comfyui (and its six pressroom siblings) carry only the covenant (lines 130–138).

**Recommendation:** Add the SUBJECT_MATTER_UNDERSTANDING line to the description and a body sentence binding it (the handler must reach understanding-parity with the SPEC's intent before generating). Note for the orchestrating improver: this is plugin-wide across pressroom, not unique to this file.

### 5. [MEDIUM] Hardcoded LoRA filenames contradict the handler's own 'copy live asset names verbatim' directive

**Evidence:** Line 54 commands: "Copy live asset names verbatim (subfolder prefixes are part of the name; collisions exist)." Yet lines 86–87 bake `"lowkey_v1.1.safetensors"` and `"LowRA.safetensors"` into the fill script (and line 56 into the dark-mode directive) with no instruction to resolve them against the live `/object_info/LoraLoader` list first or to degrade when absent. On any rig but the author's, the submit is rejected (LoRA not found) — which, per the unbounded poll above, becomes a hang rather than a decline. The model guide itself warns names are "verbatim live filenames enumerated from the rig" and that subfolder prefixes vary post-reorg.

**Recommendation:** Make asset resolution mandatory doctrine: every ckpt/LoRA name written into a template MUST appear in the just-fetched live list; if a doctrine LoRA is missing, substitute the model-guide class alternative or zero that slot's strengths (the mechanism line 100 already documents) and note the substitution in the hand-back.

### 6. [MEDIUM] Download step is whitespace-unsafe and the /view URL is not encoded

**Evidence:** Lines 96–97: `read -r FN SUB < <(... | jq -r ... '"\(.filename) \(.subfolder)"')` splits on whitespace — a filename or subfolder containing a space mis-parses (and an empty subfolder shifts fields); then `"$COMFYUI/view?filename=$FN&subfolder=$SUB&type=output"` interpolates both raw, so spaces/&/unicode break the request.

**Recommendation:** Emit tab-separated fields (`@tsv`) with `IFS=$'\t' read -r FN SUB`, and fetch with `curl -G "$COMFYUI/view" --data-urlencode "filename=$FN" --data-urlencode "subfolder=$SUB" --data-urlencode "type=output"`.

### 7. [LOW] The allowlisted `upscale` template has no usage doctrine anywhere in the handler

**Evidence:** Line 36–37 allowlists five templates including `upscale`, and knowledge/comfyui-workflows/upscale.json exists — but the multi-stage directive (lines 45–50) and the pipeline walkthrough name only lora-detail, txt2img-hires-fix, and tricomposite. A cold-start handler has a tool on its belt it is never told when to draw.

**Recommendation:** Add one sentence to the multi-stage directive: when to chain the content-preserving upscale-model pass after a latent hires (see capability gap on upscale doctrine for the full decision rule).

### 8. [LOW] Reproducibility hand-back is destroyed by the sanctioned Recipe-3 finish (-strip deletes the PNG's embedded workflow)

**Evidence:** Section 4 (lines 124–128) promises reproducibility via "template id + checkpoint + LoRA stack + filled params + seed", but section 2b sanctions raster-toolchain Recipe 3, whose ship step is `magick in.png -strip -quality 86 ship.jpg` — `-strip` removes ComfyUI's embedded workflow/prompt metadata, the only machine-readable copy of the recipe; the hand-back recipe then lives solely in chat prose. The positive/negative prompts are also not explicitly enumerated in the hand-back list.

**Recommendation:** Persist the exact filled API-format workflow (/tmp/wf.json) as a sidecar `NN-name.recipe.json` beside the PNG BEFORE any finish, and add the prompts explicitly to the hand-back contract.

### 9. [SUGGESTION] Frontmatter tool list exceeds instructed need

**Evidence:** Line 11: `tools: Read, Write, Edit, Bash, Grep, Glob` — the body instructs only Bash (curl/jq) and Read (PNG self-review); Write/Edit/Grep/Glob are never directed (artifacts are written via Bash redirection). Edit is arguably needed for the covenant's knowledge-doc feedback, but that is not stated.

**Recommendation:** Either trim to least privilege (Read, Bash + Edit) or add one line tying Write/Edit to the covenant's knowledge-feed duty so the grant is justified.

## Capability-uplift proposals

### 1. No model-family gate — doctrine is hardwired SDXL (CLIP prompts, negatives, CFG 3.5–4.5) and will mis-drive Flux/SD3.5-class checkpoints

**Proposal:** Add a 'Family gate (before any fill)' subsection to step 1: "Classify the chosen checkpoint's family before filling any template — from its name and from `/object_info` loader signatures. SDXL-class: CFG 3.5–4.5 (stylized) per the model guide, short concrete negative, CLIP natural phrases, native buckets (1024², 1216×832, 832×1216, 1344×768). Flux-class (flux1-dev/schnell): guidance-distilled — KSampler cfg=1.0, steer with a FluxGuidance value ≈3.5 (dev) instead; the negative prompt is INERT at cfg 1 — leave it empty, never spend tokens there; prompt in full natural sentences (T5 encoder); fp8 needs ≥12 GB VRAM. SD3.5-class: cfg 4–6, T5 natural language, triple-encoder loader. NEVER fill an SDXL template with a non-SDXL checkpoint — if the rig's best asset for the intent is Flux/SD3-class and no matching allowlisted template exists, decline to the orchestrator naming the missing template rather than submit a graph that cannot work." Sources: ComfyUI 2026 setup guides covering Flux/SD3.5 loader + CFG differences (localaimaster.com/blog/comfyui-complete-guide, tech-insider.org comfyui SDXL & Flux tutorial).

**Rationale:** Research confirms Flux and SD3.5 took different loaders, CFG regimes, and prompt encoders when ComfyUI added them; the rig carries 89 checkpoints and the live list WILL grow past SDXL. Today the handler would pour SDXL CFG discipline and a negative prompt into a Flux run — burning the negative entirely and frying the image at CFG 4 — with no doctrine telling it why the result is wrong.

### 2. No ControlNet/IPAdapter conditioning doctrine — composition cannot be locked across retries, A/B slots, or a document's figure set

**Proposal:** Add a prime directive 'Structure vs style: condition, don't gamble.' — "LoRAs carry style/identity; STRUCTURE is carried by ControlNet and style-coherence across a figure set by IPAdapter (both present on the rig per the model guide). (a) When a retry must fix light/colour but PRESERVE a winning composition, run the previous best PNG through a depth (or canny) ControlNet at strength 0.5–0.7 instead of praying to a new seed. (b) When the SPEC's `ab.axis_of_divergence` is anything other than composition, lock composition across A/B the same way so the divergence is the one named axis. (c) When a doc ships multiple heroes, pass the accepted first hero as an IPAdapter style reference (weight 0.5–0.8, end_percent ≤0.8 — at 1.0 it injects noise) so the set reads as one art direction. Requires one new allowlisted template, `controlnet-compose.json` (LoadImage → ControlNet/IPAdapter apply → the lora-detail spine); never accept a caller-supplied graph for it." Sources: Flux/SD ControlNet+IPAdapter usage guides (digitalcreativeai.net, stablediffusiontutorials.com) and multi-adapter best practice — "let LoRAs handle identity/style, ControlNet for structure; start with modest strengths" (neurocanvas.net multi-LoRA workflows).

**Rationale:** The handler's only steering tools today are prompt anchors and seeds, so every regeneration is a composition lottery — directly at odds with the A/B loop's demand that options differ on ONE named axis and with award-tier consistency across a document's figures. The rig already has the nodes; only the doctrine and one template are missing.

### 3. Latent-hires vs upscale-model decision rule is absent — the allowlisted `upscale` template is dormant and the two mechanisms are not distinguished

**Proposal:** Add to the multi-stage directive: "Two different upscalers, two different jobs. LATENT hires (LatentUpscaleBy + second KSampler, denoise 0.3–0.55) INVENTS detail and changes content — use it mid-pipeline to enrich micro-texture (landscapes/product: proven +4–6 in the craft study), never on tight faces above 0.35 denoise (proven −6 regression). UPSCALE-MODEL passes (the `upscale` template: 4x-UltraSharp / Remacri class) PRESERVE content at zero denoise — use them as the FINAL resolution step after the image already passes self-review, then `vips thumbnail` down to the width budget (supersample-then-downscale is the cheapest sharpness win). Standard award-tier chain: base → latent hires (genre-gated denoise) → self-review → upscale-model 2–4× → downscale to budget. Never run a second latent pass to fix softness — that is the upscale template's job." Sources: hires-fix upscaler comparisons showing 4x-UltraSharp produces best results at ANY denoise incl. 0.0 while latent upscalers need ≥0.5 and alter content (Fabian W., medium.com hires-fix upscaler comparison; stable-diffusion-art.com AI-upscaler guide).

**Rationale:** The handler allowlists `upscale` (line 37) but never says when to use it, and its own craft study proves latent hires is genre-dependent, not free. Research cleanly separates the two mechanisms (content-inventing vs content-preserving); without the rule the handler either skips the finishing pass or mis-applies latent upscale to faces — both cap below the award bar.

### 4. Self-review says 'regenerate' but carries no artifact-diagnosis → knob matrix, so retries are blind re-rolls

**Proposal:** Add a 'Diagnose, then turn ONE knob' table to step 3: "fried/oversaturated, crunchy edges → CFG too high: drop 1–1.5 (stylized class lives at 3.5–4.5). Mushy, low-contrast, undercooked → steps too low or sampler mismatch: raise steps toward 50–60 or switch dpmpp_2m→dpmpp_sde_gpu on karras. Doubled subjects / extra limbs / scene wrap → resolution off the model's native bucket: snap to 1024², 1216×832, 832×1216, 1344×768 and let the hires pass add size. Smooth 'AI-skin' on faces after hires → re-detail denoise to 0.25–0.35 or FaceDetailer (recipe E), never full-frame 0.45. Muddy darks → negative contradicts the positive (the dark-key rule in prompt-craft): purge dark/shadow terms from the negative. Style not committing → LoRA stack under-weighted or fighting: solo each LoRA first, keep summed style weights ≤~1.2, and prefer lowering strength_clip before strength_model when prompt semantics degrade. ECONOMY: explore with a 4–6 image batch_size sweep at base resolution, pick the best, and run the expensive hires/upscale stages on the winner only — never hires every seed." Sources: sampler/scheduler pairing guidance (comfyui.dev compatibility matrix, comfyui-wiki.com sampler docs), LoRA weight/strength_clip discipline (neurocanvas.net, runcomfy.com LoRA Stacker docs).

**Rationale:** Step 3 currently names failure classes but only one remedy ('adjust... and regenerate'), so a cold-start handler burns whole multi-stage pipelines per guess. A symptom→parameter map plus cheap-sweep-then-hires-the-winner is standard practice and converts the award bar from a seed lottery into a controlled search — fewer turns, exactly what the covenant promises.

### 5. No VRAM-aware planning or structured execution-failure taxonomy (OOM, node_errors, interrupted) — the covenant mentions OOM but the doctrine cannot detect or react to one

**Proposal:** Extend step 1 and step 2: "The probe already fetches /system_stats — READ it: record total/free VRAM and pick the plan to fit (SDXL multi-stage comfortable ≥8 GB; Flux/SD3.5 fp8 ≥12 GB; on a tight rig cap base res at 1024-bucket and hires scale at 1.5, and prefer the upscale-model finish — it runs tiled — over a larger latent pass). After POST, treat the response as tri-state: `prompt_id` → enqueued (confirm via /queue); `node_errors` non-empty → diagnose (missing asset → re-resolve names per the verbatim rule; bad input type → template defect, feed the covenant); HTTP error → decline. While polling, `status.status_str == "error"` ends the wait — extract the failing node's message; an OOM message means halve the hires scale or drop to the 1024 bucket and retry ONCE, then decline with the evidence. Every decline names its class (offline | rejected | execution-error | budget-exhausted) so the orchestrator and the covenant learn from it." Source: VRAM tiering per family from current ComfyUI guides (localaimaster.com/blog/comfyui-complete-guide).

**Rationale:** The self-improvement covenant explicitly imagines 'a template that OOMs at 24GB' feeding the knowledge base, yet nothing in the procedure can observe an OOM — execution errors today are an infinite poll (finding 2). A typed failure taxonomy is what makes the covenant's learning loop real instead of aspirational, and VRAM-aware planning prevents the failures instead of diagnosing them.

### 6. No determinism/provenance ledger — seeds are vibes, and the one machine-readable recipe (PNG-embedded workflow) is destroyed by the sanctioned -strip finish

**Proposal:** Add a 'Reproducibility is an artifact, not a paragraph' rule to steps 2/4: "Generate the seed once per attempt (`SEED=$RANDOM$RANDOM`), log it, and FREEZE it whenever you are varying anything else (prompt anchors, LoRA weights, ControlNet strength) so each retry is a controlled experiment; honour the A/B slot by changing the named divergence axis with the seed frozen, not by re-rolling. Before any Recipe-3 finish, copy the exact filled API-format workflow to `<doc-dir>/diagrams/NN-name.recipe.json` (cp /tmp/wf.json …) — `magick -strip` deletes the workflow ComfyUI embeds in the PNG, so the sidecar is the only durable recipe. The hand-back includes the sidecar path; regenerating the figure later is `jq '.["3"].inputs.seed=…' recipe.json | POST` — one command, zero archaeology." Grounded in the A/B loop's own reproducibility demand (spec-schema.md: 'The SPEC plus these four make a turn of the A/B-until-best loop fully reproducible') and the controlled-variable method the 2026-06-10 craft study used to validate the decision tree.

**Rationale:** Section 4 promises a reproducible recipe but ships it as chat prose, and section 2b's blessed finish actively erases the embedded copy — so six months later no one can regenerate or A/B-iterate a shipped hero. Frozen-seed single-variable retries are also the only way the diagnosis matrix (gap 4) produces attributable evidence for the covenant.
