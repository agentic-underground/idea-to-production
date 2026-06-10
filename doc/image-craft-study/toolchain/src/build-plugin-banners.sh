#!/usr/bin/env bash
# build-plugin-banners.sh — the headline banner builder (Workstream E of VISUAL_UPGRADE_PLAN.md).
#
# For each of the 9 marketplace plugins it produces ONE wide-short (1920x400) branding banner:
#   plugins/<plugin>/diagrams/banner.png
#
# Anatomy (per the maintainer-resolved spec):
#   1. ATMOSPHERE BAND (raster, behind)  — a STYLIZED ComfyUI render (bas-relief / line-art /
#      whimsical-3D / painterly — NEVER photoreal), cropped + scaled to 1920x400, then DIMMED and
#      BLURRED so it whispers behind the wordmark. The band is atmosphere, not the subject; it carries
#      NO text (diffusion bakes gibberish). Graceful degrade: if the rig is unreachable (or a band
#      will not come out clean in 3 tries) we synthesise a deliberate SVG gradient/texture band so the
#      banner still looks intentional and the pipeline never blocks.
#   2. BRANDING OVERLAY (SVG, crisp, on top) — wordmark (plugin accent) + tagline + a small spirit
#      motif + a legibility SCRIM (dark gradient behind the text block so it reads on any band).
#      Transparent ground, 1920x400. This is the brand carrier and must be perfect regardless of band.
#   3. layout-check.sh runs on the overlay SVG (no text past the canvas edge) BEFORE compositing.
#   4. BLEND  — magick band.png overlay.png -compose over -composite -> banner.png  (<= ~600KB; if a
#      PNG blows the budget we ship a quality-88 JPG fallback, but prefer PNG).
#
# Re-runnable.  Build all:           bash build-plugin-banners.sh
#               Build one or a few:  bash build-plugin-banners.sh foundry sentinel
#               Force a vector band: BANNER_VECTOR_ONLY=1 bash build-plugin-banners.sh atelier
#
# Knobs (env):
#   PRESSROOM_COMFYUI_URL   rig endpoint (default the i9 workstation :8188)
#   BANNER_VECTOR_ONLY=1    skip the rig entirely; synthesise vector bands (fast, offline-safe)
#   BANNER_RIG_TRIES=N      rig attempts per band before degrading (default 3)
#
# Pure bash + jq + ImageMagick + rsvg-convert + curl. magick/rsvg are required (the banner is a
# composite); the rig is optional (degrades to vector). 0 caller text reaches a shell as code.
set -euo pipefail

# ---------------------------------------------------------------------------------------------------
# Paths & tools
# ---------------------------------------------------------------------------------------------------
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SRC_DIR/../../../.." && pwd)"
LAYOUT_CHECK="$SRC_DIR/layout-check.sh"
COMFYUI="${PRESSROOM_COMFYUI_URL:-http://10.10.10.163:8188}"
RIG_TRIES="${BANNER_RIG_TRIES:-3}"
VECTOR_ONLY="${BANNER_VECTOR_ONLY:-0}"

BW=1920          # banner width
BH=400           # banner height
SIZE_BUDGET=$((600 * 1024))   # ~600KB per banner

need() { command -v "$1" >/dev/null 2>&1 || { echo "FATAL: missing required tool: $1" >&2; exit 2; }; }
need magick; need rsvg-convert; need jq; need curl

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# ---------------------------------------------------------------------------------------------------
# Per-plugin spirit table (E2).  Fields, '|'-separated:
#   key | wordmark | tagline | accent(hex) | motif | bandstyle | promptseed | bandpos(positive prompt)
# accent = the plugin's wordmark colour (dark-mode canon: teal #5eead4 / amber #fbbf24 family).
# bandstyle drives the checkpoint+LoRA routing AND the vector-degrade palette.
# Taglines reconciled against each README (see report); all kept short to read at ~640px inline width.
# ---------------------------------------------------------------------------------------------------
read -r -d '' PLUGINS <<'TABLE' || true
i2p|idea-to-production|every plugin, one front door|#fbbf24|gateway|engrave|11|woodcut engraving of a single grand stone archway gateway threshold, bold black outlines on a plain pale parchment background, clean line drawing, crisp engraved hatch lines, vintage technical illustration, flat two-tone graphic, no greyscale tone, no shading gradients, no scenery fill, generous empty space, minimalist linework
concierge|concierge|a warm light at the door|#fbbf24|lantern|lineart|27|fine ink line-art of a single hanging lantern beside a doorway threshold, the lantern flame drawn as a deliberate clean geometric shape with radiating ray lines, crisp single-weight warm amber pen strokes on a deep near-black ground, flat graphic illustration, the motif set to the right, generous empty space on the left, minimalist linework, low contrast, no fill
market-scanner|market-scanner|sweep the field, kill weak early|#5eead4|radar|lineart|43|fine ink line-art of concentric radar sweep rings and a single rotating scan line, clean contour drawing, sparse hatching, single-weight teal pen strokes on a deep ink-blue ground, generous empty space across the band, minimalist linework, low contrast, no fill
ideator|ideator|scattered idea, build-ready package|#5eead4|fragments|lineart|58|fine ink line-art of scattered geometric fragments converging toward one neat assembled cluster, clean contour drawing, sparse hatching, single-weight teal pen strokes on a deep ink-blue ground, generous empty space on the left, minimalist linework, low contrast, no fill
atelier|atelier|screens become considered interfaces|#5eead4|drafting|painterly|66|atmospheric concept-art matte painting of an angled drafting table with a faint blueprint glow, loose visible brushwork, volumetric haze, moody low-key teal and amber palette, the table set to the right edge, vast hazy negative space on the left, painterly not photographic, deep shadow
foundry|foundry|test-first, value on one slice|#fbbf24|conveyor|engrave|74|woodcut engraving of an industrial conveyor belt with rollers gears and a forge, bold black outlines on a plain pale parchment background, clean line drawing, crisp engraved hatch lines, vintage technical illustration, flat two-tone graphic, no greyscale tone, no shading gradients, no scenery fill, generous empty space, minimalist linework
sentinel|sentinel|certify before exposure|#5eead4|shield|lineart|82|fine monochrome ink line-art of a single tall gate with a shield emblem, clean contour drawing, sparse hatching, single-weight pale ink strokes on a near-black ground, generous empty space across the band, minimalist linework, low contrast, no fill
pressroom|pressroom|illustrate, review, publish|#fbbf24|press|engrave|91|woodcut engraving of an old printing press with platen and stacked metal type plates, bold black outlines on a plain pale parchment background, clean line drawing, crisp engraved hatch lines, vintage technical illustration, flat two-tone graphic, no greyscale tone, no shading gradients, no scenery fill, generous empty space, minimalist linework
mission-control|mission-control|watch, respond, iterate|#5eead4|console|painterly|99|atmospheric concept-art matte painting of a curved mission-control console ring with faint telemetry waveforms, loose visible brushwork, volumetric haze, moody low-key teal palette, the console arc to the right, vast hazy negative space on the left, painterly not photographic, deep shadow
TABLE

# style -> checkpoint, lora1@strength, lora2@strength, cfg, sampler (verified live on the rig)
band_recipe() {
  case "$1" in
    basrelief)   echo "oasisSDXL_v10.safetensors|BAS-RELIEF.safetensors:0.8|xl_more_art-full_v1.safetensors:0.4|4.0|dpmpp_sde_gpu";;
    lineart)     echo "bluePencilXL_v050.safetensors|vntg-line-art-v2.safetensors:0.6||3.5|dpmpp_sde_gpu";;
    # engrave: a HARDER line-art routing for representational scene subjects (gateway/press/conveyor)
    # that the soft lineart recipe rendered as tonal masses (read as defocused photos after the band
    # blur). Stacks two ink/line LoRAs at high strength to force committed outline-only output.
    engrave)     echo "bluePencilXL_v050.safetensors|vntg-line-art-v2.safetensors:0.9|pensketch_lora_v2.3.safetensors:0.5|3.2|dpmpp_sde_gpu";;
    whimsical3d) echo "LahCuteCartoonSDXL_alpha.safetensors|blindbox_v1_mix.safetensors:0.4||4.0|dpmpp_3m_sde_gpu";;
    painterly)   echo "dynavisionXLAllInOneStylized_beta0411Bakedvae.safetensors|CraigMullins.safetensors:0.5|xl_more_art-full_v1.safetensors:0.5|4.2|dpmpp_3m_sde_gpu";;
    *) echo "oasisSDXL_v10.safetensors|BAS-RELIEF.safetensors:0.8||4.0|dpmpp_sde_gpu";;
  esac
}

# Shared banning negative (text / people / photoreal sheen) — never contradicts the dark positive.
# HARD photoreal bans added after an adversarial review flagged 4 bands as defocused photographs:
# no photo material, no bokeh blobs, no depth-of-field sheen, no 3d-render gloss.
NEG='photo, photograph, photorealistic, realistic, photography, bokeh, depth of field, dof, blur, blurry, out of focus, defocused, lens flare, 3d render, octane render, cgi, plastic sheen, glossy photoreal render, photographic skin, film grain, vignette, overexposed, high-key, text, words, letters, lettering, typography, captions, watermark, signature, logo, ui, numbers, person, people, human, face, portrait, crowd, hands, busy cluttered centre'

# ---------------------------------------------------------------------------------------------------
# Rig: render one stylized band via the allowlisted lora-detail template (LoRA stack + latent hires).
# Wide base res (1536x640) to discourage SDXL ultra-wide artifacts; we crop a 1920x400 slice after.
# Echoes the downloaded PNG path on success; non-zero (and no echo) on any failure.
# ---------------------------------------------------------------------------------------------------
rig_render_band() {
  local style="$1" seed="$2" pos="$3" out="$4"
  local rec ckpt l1 l2 cfg sampler ln1 ls1 ln2 ls2
  rec="$(band_recipe "$style")"
  IFS='|' read -r ckpt l1 l2 cfg sampler <<<"$rec"
  ln1="${l1%%:*}"; ls1="${l1##*:}"; [ -n "$ln1" ] || { ln1="$ckpt"; ls1=0; }
  if [ -n "$l2" ]; then ln2="${l2%%:*}"; ls2="${l2##*:}"; else ln2="$ln1"; ls2=0; fi

  local tmpl="$REPO_ROOT/plugins/pressroom/knowledge/comfyui-workflows/lora-detail.json"
  jq \
    --arg ckpt "$ckpt" --arg pos "$pos" --arg neg "$NEG" \
    --arg ln1 "$ln1" --argjson ls1 "$ls1" \
    --arg ln2 "$ln2" --argjson ls2 "$ls2" \
    --argjson seed "$seed" --argjson cfg "$cfg" --arg samp "$sampler" '
      del(._meta)
      | .["4"].inputs.ckpt_name=$ckpt
      | .["20"].inputs.lora_name=$ln1 | .["20"].inputs.strength_model=$ls1 | .["20"].inputs.strength_clip=$ls1
      | .["21"].inputs.lora_name=$ln2 | .["21"].inputs.strength_model=$ls2 | .["21"].inputs.strength_clip=$ls2
      | .["5"].inputs.width=1536 | .["5"].inputs.height=640
      | .["6"].inputs.text=$pos | .["7"].inputs.text=$neg
      | .["3"].inputs.seed=$seed | .["3"].inputs.steps=40 | .["3"].inputs.cfg=$cfg
      | .["3"].inputs.sampler_name=$samp | .["3"].inputs.scheduler="karras"
      | .["11"].inputs.seed=$seed | .["11"].inputs.cfg=$cfg
      | .["11"].inputs.sampler_name=$samp | .["11"].inputs.scheduler="karras"
      | .["10"].inputs.scale_by=1.25 | .["11"].inputs.denoise=0.4
    ' "$tmpl" > "$WORK/wf.json" || return 1

  local pid
  pid="$(curl -sf -m 15 "$COMFYUI/prompt" -X POST -H 'Content-Type: application/json' \
        --data "$(jq -n --slurpfile p "$WORK/wf.json" --arg c "banner-$$" '{prompt:$p[0], client_id:$c}')" \
        | jq -r '.prompt_id // empty')" || return 1
  [ -n "$pid" ] || return 1

  # poll up to ~150s
  local i fn sub
  for i in $(seq 1 50); do
    if curl -sf -m 10 "$COMFYUI/history/$pid" | jq -e --arg p "$pid" '.[$p].outputs' >/dev/null 2>&1; then
      break
    fi
    sleep 3
  done
  read -r fn sub < <(curl -sf -m 10 "$COMFYUI/history/$pid" \
      | jq -r --arg p "$pid" '.[$p].outputs[]?.images[0]? | "\(.filename) \(.subfolder)"' 2>/dev/null | head -1)
  [ -n "${fn:-}" ] && [ "$fn" != "null" ] || return 1
  curl -sf -m 30 "$COMFYUI/view?filename=$fn&subfolder=${sub:-}&type=output" -o "$out" || return 1
  [ -s "$out" ] || return 1
  return 0
}

# Quick stylization sanity gate on a freshly rendered band: reject near-uniform (failed/empty) renders.
# We do NOT try to machine-detect "photoreal" (that's the pixel review's job); we only reject obviously
# broken bands (all-one-colour / blank) so a bad roll triggers a re-try instead of shipping.
band_is_usable() {
  local f="$1" sd
  sd="$(magick "$f" -colorspace Gray -format '%[fx:standard_deviation]' info: 2>/dev/null || echo 0)"
  awk -v s="$sd" 'BEGIN{exit !(s>0.02)}'
}

# ---------------------------------------------------------------------------------------------------
# Band finishing: crop a central horizontal 1920x400 slice, then DIM + BLUR (atmosphere).
# Also nudges the LEFT/CENTRE wordmark zone darker so the scrim has the calmest region to sit on.
# ---------------------------------------------------------------------------------------------------
finish_band() {
  local in="$1" out="$2"
  magick "$in" \
    -resize "${BW}x${BH}^" -gravity center -extent "${BW}x${BH}" \
    -modulate 66,92,100 \
    -blur 0x5 \
    -fill black -colorize 8% \
    "$out"
}

# ---------------------------------------------------------------------------------------------------
# Vector-degrade band: an intentional, deliberate SVG gradient + soft texture, themed per band style.
# Produced when the rig is offline / BANNER_VECTOR_ONLY / 3 rig tries all fail. Never looks accidental.
# ---------------------------------------------------------------------------------------------------
vector_band_svg() {
  local style="$1" accent="$2" svg="$3" motif="${4:-}"
  # Per-style colour ground (dark canon). c1=deep ground, c2=mid, glow=accent tint.
  local c1 c2
  case "$style" in
    basrelief)   c1="#171410"; c2="#241d14";;
    lineart)     c1="#0b1220"; c2="#10192e";;
    engrave)     c1="#13110c"; c2="#201a10";;
    whimsical3d) c1="#14101c"; c2="#201528";;
    painterly)   c1="#0d1116"; c2="#161b22";;
    *)           c1="#101018"; c2="#1a1a28";;
  esac
  cat > "$svg" <<SVG
<svg width="$BW" height="$BH" viewBox="0 0 $BW $BH" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="vg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="$c1"/>
      <stop offset="1" stop-color="$c2"/>
    </linearGradient>
    <radialGradient id="vglow" cx="0.78" cy="0.4" r="0.7">
      <stop offset="0" stop-color="$accent" stop-opacity="0.22"/>
      <stop offset="0.5" stop-color="$accent" stop-opacity="0.06"/>
      <stop offset="1" stop-color="$accent" stop-opacity="0"/>
    </radialGradient>
    <filter id="vgrain"><feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" result="n"/>
      <feColorMatrix in="n" type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0.05 0"/></filter>
  </defs>
  <rect width="$BW" height="$BH" fill="url(#vg)"/>
  <rect width="$BW" height="$BH" fill="url(#vglow)"/>
  <g stroke="$accent" stroke-opacity="0.10" stroke-width="1" fill="none">
    <path d="M 1100 ${BH} C 1300 250, 1500 150, $BW 60"/>
    <path d="M 1240 ${BH} C 1420 280, 1620 180, $BW 120"/>
    <path d="M 1380 ${BH} C 1560 300, 1760 210, $BW 180"/>
  </g>
$( [ -n "$motif" ] && {
     # A large, faint, intentional line-drawing of the plugin's spirit motif ghosted into the
     # band's right half — makes the vector band SUBJECT-relevant (a drawn gateway / press /
     # conveyor / lantern), unambiguously graphic, never accidental. ~2.6x the overlay motif,
     # low opacity so the crisp overlay motif still reads on top.
     echo "  <g opacity=\"0.16\" transform=\"translate(1230 200) scale(2.6)\">"
     motif_fragment "$motif" "$accent" 0 0
     echo "  </g>"
   } )
  <rect width="$BW" height="$BH" filter="url(#vgrain)"/>
</svg>
SVG
}

# ---------------------------------------------------------------------------------------------------
# Spirit-motif SVG fragment per plugin (small, set to the right so it never fights the wordmark).
# Drawn in the plugin accent; lives inside the overlay layer. Centre at (mx,my), scale ~ s.
# ---------------------------------------------------------------------------------------------------
motif_fragment() {
  local motif="$1" accent="$2" mx="$3" my="$4"
  case "$motif" in
    gateway) cat <<G
  <g transform="translate($mx $my)" fill="none" stroke="$accent" stroke-width="3" stroke-linecap="round">
    <path d="M -46 52 L -46 -18 A 46 46 0 0 1 46 -18 L 46 52" stroke-opacity="0.95"/>
    <path d="M -30 52 L -30 -8 A 30 30 0 0 1 30 -8 L 30 52" stroke-opacity="0.5"/>
    <circle cx="0" cy="-30" r="5" fill="$accent" stroke="none"/>
    <g stroke-opacity="0.55"><line x1="-66" y1="40" x2="-90" y2="34"/><line x1="66" y1="40" x2="90" y2="34"/><line x1="0" y1="-52" x2="0" y2="-70"/></g>
  </g>
G
    ;;
    lantern) cat <<G
  <g transform="translate($mx $my)" fill="none" stroke="$accent" stroke-width="3" stroke-linecap="round">
    <line x1="0" y1="-58" x2="0" y2="-40"/>
    <path d="M -22 -40 L 22 -40 L 28 44 L -28 44 Z" stroke-opacity="0.95"/>
    <rect x="-16" y="-30" width="32" height="62" rx="4" fill="$accent" fill-opacity="0.16" stroke-opacity="0.7"/>
    <circle cx="0" cy="2" r="9" fill="$accent" stroke="none" fill-opacity="0.9"/>
    <g stroke-opacity="0.4"><line x1="0" y1="58" x2="-26" y2="80"/><line x1="0" y1="58" x2="26" y2="80"/><line x1="0" y1="58" x2="0" y2="86"/></g>
  </g>
G
    ;;
    radar) cat <<G
  <g transform="translate($mx $my)" fill="none" stroke="$accent" stroke-width="2.5">
    <circle cx="0" cy="0" r="58" stroke-opacity="0.35"/>
    <circle cx="0" cy="0" r="40" stroke-opacity="0.5"/>
    <circle cx="0" cy="0" r="22" stroke-opacity="0.7"/>
    <line x1="0" y1="0" x2="48" y2="-34" stroke-width="3.5" stroke-linecap="round"/>
    <path d="M 0 0 L 58 0 A 58 58 0 0 0 48 -34 Z" fill="$accent" fill-opacity="0.16" stroke="none"/>
    <circle cx="0" cy="0" r="4" fill="$accent" stroke="none"/>
  </g>
G
    ;;
    fragments) cat <<G
  <g transform="translate($mx $my)" fill="none" stroke="$accent" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
    <rect x="30" y="-14" width="26" height="26" rx="3" stroke-opacity="0.95" transform="rotate(6 43 -1)"/>
    <rect x="30" y="16" width="26" height="22" rx="3" stroke-opacity="0.95" transform="rotate(-5 43 27)"/>
    <g stroke-opacity="0.5">
      <rect x="-78" y="-40" width="18" height="18" rx="2" transform="rotate(-18 -69 -31)"/>
      <rect x="-44" y="34" width="16" height="16" rx="2" transform="rotate(22 -36 42)"/>
      <rect x="-86" y="20" width="14" height="14" rx="2" transform="rotate(8 -79 27)"/>
    </g>
    <g stroke-opacity="0.4"><line x1="-58" y1="-26" x2="26" y2="-4"/><line x1="-30" y1="40" x2="28" y2="22"/><line x1="-72" y1="26" x2="24" y2="6"/></g>
  </g>
G
    ;;
    drafting) cat <<G
  <g transform="translate($mx $my)" fill="none" stroke="$accent" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
    <path d="M -64 44 L 60 44" stroke-opacity="0.5"/>
    <path d="M -52 44 L -28 -32 L 56 -32 L 40 44 Z" stroke-opacity="0.9" fill="$accent" fill-opacity="0.10"/>
    <g stroke-opacity="0.6"><line x1="-16" y1="-20" x2="36" y2="-20"/><line x1="-20" y1="-4" x2="32" y2="-4"/><line x1="-24" y1="12" x2="28" y2="12"/></g>
    <line x1="-40" y1="44" x2="-52" y2="74" stroke-opacity="0.5"/><line x1="40" y1="44" x2="52" y2="74" stroke-opacity="0.5"/>
  </g>
G
    ;;
    conveyor) cat <<G
  <g transform="translate($mx $my)" fill="none" stroke="$accent" stroke-width="2.5" stroke-linecap="round">
    <rect x="-66" y="18" width="132" height="22" rx="11" stroke-opacity="0.85"/>
    <g stroke-opacity="0.5"><circle cx="-50" cy="48" r="9"/><circle cx="-12" cy="48" r="9"/><circle cx="26" cy="48" r="9"/><circle cx="56" cy="48" r="9"/></g>
    <rect x="-22" y="-18" width="30" height="30" rx="4" fill="$accent" fill-opacity="0.16" stroke-opacity="0.95"/>
    <g stroke-opacity="0.55"><path d="M 30 -8 l 16 0 m -6 -6 l 6 6 l -6 6"/></g>
  </g>
G
    ;;
    shield) cat <<G
  <g transform="translate($mx $my)" fill="none" stroke="$accent" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
    <path d="M -64 50 L -64 -34 M 64 50 L 64 -34" stroke-opacity="0.45"/>
    <path d="M -64 -34 L 64 -34" stroke-opacity="0.45"/>
    <path d="M 0 -28 L 38 -16 L 38 18 C 38 40, 18 52, 0 60 C -18 52, -38 40, -38 18 L -38 -16 Z" stroke-opacity="0.95" fill="$accent" fill-opacity="0.10"/>
    <path d="M -14 16 l 10 12 l 22 -26" stroke-width="3.5" stroke-opacity="0.95"/>
  </g>
G
    ;;
    press) cat <<G
  <g transform="translate($mx $my)" fill="none" stroke="$accent" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
    <rect x="-58" y="-40" width="116" height="20" rx="4" stroke-opacity="0.85"/>
    <line x1="-40" y1="-20" x2="-40" y2="20" stroke-opacity="0.6"/><line x1="40" y1="-20" x2="40" y2="20" stroke-opacity="0.6"/>
    <rect x="-58" y="20" width="116" height="16" rx="4" fill="$accent" fill-opacity="0.14" stroke-opacity="0.9"/>
    <g stroke-opacity="0.5"><line x1="-44" y1="48" x2="44" y2="48"/><line x1="-38" y1="60" x2="38" y2="60"/></g>
  </g>
G
    ;;
    console) cat <<G
  <g transform="translate($mx $my)" fill="none" stroke="$accent" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
    <path d="M -62 36 A 62 62 0 0 1 62 36" stroke-opacity="0.85"/>
    <path d="M -42 36 A 42 42 0 0 1 42 36" stroke-opacity="0.45"/>
    <path d="M -54 6 l 10 0 l 6 -18 l 10 30 l 8 -14 l 7 0 l 6 8 l 9 0" stroke-width="2.5" stroke-opacity="0.95"/>
    <circle cx="0" cy="36" r="5" fill="$accent" stroke="none"/>
    <g stroke-opacity="0.5"><line x1="-30" y1="36" x2="-30" y2="52"/><line x1="0" y1="36" x2="0" y2="56"/><line x1="30" y1="36" x2="30" y2="52"/></g>
  </g>
G
    ;;
    *) echo "  <circle cx=\"$mx\" cy=\"$my\" r=\"30\" fill=\"none\" stroke=\"$accent\" stroke-width=\"3\"/>";;
  esac
}

# ---------------------------------------------------------------------------------------------------
# OVERLAY GENERATOR (layout-check-compatible): when called with a dir arg ($1) it writes ONE
# f0001.svg frame there (so `layout-check.sh build-plugin-banners.sh ...` could be wired); but the
# normal path calls write_overlay_svg directly with explicit fields. We expose both.
#
# Layout: left-anchored wordmark + tagline in the calm left/centre zone; motif at the right; a
# left-to-right scrim (dark on the text side, fading right) guarantees legibility over any band.
# All text x-extents are kept well inside 0..1920 (checked by layout-check.sh).
# ---------------------------------------------------------------------------------------------------
write_overlay_svg() {
  local wordmark="$1" tagline="$2" accent="$3" motif="$4" svg="$5"
  local tx=120                      # left text anchor
  local wm_fs=88                    # wordmark font-size
  # Auto-shrink the wordmark if it would approach the motif zone (~x=1430). est width = chars*fs*0.62.
  local wlen=${#wordmark}
  while [ "$wm_fs" -gt 52 ]; do
    local est=$(( wlen * wm_fs * 62 / 100 ))
    [ $(( tx + est )) -lt 1400 ] && break
    wm_fs=$(( wm_fs - 4 ))
  done
  local micro_fs=20 tag_fs=30
  local mx=1620 my=200             # motif centre (right zone)

  cat > "$svg" <<SVG
<svg width="$BW" height="$BH" viewBox="0 0 $BW $BH" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <!-- legibility scrim: darkest on the left text zone, fading to clear over the band/motif -->
    <linearGradient id="scrim" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0.00" stop-color="#0b0b12" stop-opacity="0.92"/>
      <stop offset="0.40" stop-color="#0b0b12" stop-opacity="0.78"/>
      <stop offset="0.70" stop-color="#0b0b12" stop-opacity="0.32"/>
      <stop offset="1.00" stop-color="#0b0b12" stop-opacity="0.05"/>
    </linearGradient>
    <linearGradient id="vscrim" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0b0b12" stop-opacity="0.30"/>
      <stop offset="0.5" stop-color="#0b0b12" stop-opacity="0"/>
      <stop offset="1" stop-color="#0b0b12" stop-opacity="0.42"/>
    </linearGradient>
    <radialGradient id="accentwash" cx="0.12" cy="0.5" r="0.6">
      <stop offset="0" stop-color="$accent" stop-opacity="0.10"/>
      <stop offset="1" stop-color="$accent" stop-opacity="0"/>
    </radialGradient>
  </defs>

  <!-- scrims (these are the legibility guarantee; band shows through on the right) -->
  <rect width="$BW" height="$BH" fill="url(#scrim)"/>
  <rect width="$BW" height="$BH" fill="url(#vscrim)"/>
  <rect width="$BW" height="$BH" fill="url(#accentwash)"/>

  <!-- accent hairline framing (premium edge, fully inside the canvas) -->
  <rect x="14" y="14" width="$((BW-28))" height="$((BH-28))" rx="20" fill="none" stroke="$accent" stroke-opacity="0.22" stroke-width="1.5"/>
  <line x1="$tx" y1="150" x2="$tx" y2="252" stroke="$accent" stroke-width="3" stroke-opacity="0.85" stroke-linecap="round"/>

$(motif_fragment "$motif" "$accent" "$mx" "$my")

  <!-- ============ WORDMARK + TAGLINE (left-anchored, in the calm scrim zone) ============ -->
  <g font-family="DejaVu Sans" text-anchor="start">
    <text x="$((tx+22))" y="120" font-size="$micro_fs" letter-spacing="4" fill="#b8bed0" font-weight="bold">A  CLAUDE  CODE  PLUGIN  MARKETPLACE</text>
    <text x="$((tx+18))" y="210" font-size="$wm_fs" font-weight="bold" letter-spacing="0.5" fill="$accent">$wordmark</text>
    <text x="$((tx+22))" y="266" font-size="$tag_fs" letter-spacing="1" fill="#e6e9f0">$tagline</text>
  </g>
</svg>
SVG
}

# ---------------------------------------------------------------------------------------------------
# Build ONE plugin's banner.
# ---------------------------------------------------------------------------------------------------
build_one() {
  local line="$1"
  local key wordmark tagline accent motif bandstyle seed pos
  IFS='|' read -r key wordmark tagline accent motif bandstyle seed pos <<<"$line"

  local outdir="$REPO_ROOT/plugins/$key/diagrams"
  mkdir -p "$outdir"
  local final="$outdir/banner.png"
  local band="$WORK/$key-band.png"
  local overlay_svg="$WORK/$key-overlay.svg"
  local overlay_png="$WORK/$key-overlay.png"
  local mode="" recipe_note=""

  # ---- 1. atmosphere band ----
  if [ "$VECTOR_ONLY" = "1" ]; then
    mode="vector"; recipe_note="vector-degrade (forced)"
  elif ! curl -sf -m 3 "$COMFYUI/system_stats" >/dev/null 2>&1; then
    mode="vector"; recipe_note="vector-degrade (rig offline)"
  else
    local raw="$WORK/$key-raw.png" t got=0
    for t in $(seq 1 "$RIG_TRIES"); do
      local s=$(( seed + (t-1)*1000 ))
      echo "  [$key] rig attempt $t/$RIG_TRIES (style=$bandstyle seed=$s)..." >&2
      if rig_render_band "$bandstyle" "$s" "$pos" "$raw" && band_is_usable "$raw"; then
        got=1; break
      fi
    done
    if [ "$got" = "1" ]; then
      mode="rig"
      local rec; rec="$(band_recipe "$bandstyle")"
      recipe_note="$bandstyle · ${rec%%|*} · ${rec#*|}"; recipe_note="${recipe_note%|*|*}"
      recipe_note="$bandstyle · $(band_recipe "$bandstyle" | awk -F'|' '{printf "%s + %s %s", $1, $2, $3}')"
    else
      mode="vector"; recipe_note="vector-degrade (rig render failed after $RIG_TRIES tries)"
    fi
  fi

  if [ "$mode" = "rig" ]; then
    finish_band "$WORK/$key-raw.png" "$band"
  else
    local vsvg="$WORK/$key-vband.svg"
    vector_band_svg "$bandstyle" "$accent" "$vsvg" "$motif"
    rsvg-convert -w "$BW" -h "$BH" "$vsvg" -o "$band"
  fi

  # ---- 2. overlay SVG ----
  write_overlay_svg "$wordmark" "$tagline" "$accent" "$motif" "$overlay_svg"

  # ---- 3. layout-check the overlay (no text past edges) ----
  local lcdir="$WORK/$key-lc"; mkdir -p "$lcdir"
  cp "$overlay_svg" "$lcdir/f0001.svg"
  # tiny throwaway generator so layout-check (which runs a generator into a dir) can vet our SVG
  cat > "$WORK/$key-gen.sh" <<GEN
#!/usr/bin/env bash
cp "$overlay_svg" "\$1/f0001.svg"
GEN
  chmod +x "$WORK/$key-gen.sh"
  if bash "$LAYOUT_CHECK" "$WORK/$key-gen.sh" >/dev/null 2>"$WORK/$key-lc.err"; then
    echo "  [$key] layout-check OK" >&2
  else
    echo "  [$key] WARNING layout-check flagged overflow:" >&2
    cat "$WORK/$key-lc.err" >&2
  fi

  # ---- 4. blend band + overlay ----
  rsvg-convert -w "$BW" -h "$BH" "$overlay_svg" -o "$overlay_png"
  magick "$band" "$overlay_png" -compose over -composite \
    -strip -define png:compression-level=9 "$final"

  # ---- size budget: PNG preferred; JPG-88 fallback if over ~600KB ----
  local sz; sz="$(stat -c%s "$final")"
  if [ "$sz" -gt "$SIZE_BUDGET" ]; then
    local jpg="${final%.png}.jpg"
    magick "$band" "$overlay_png" -compose over -composite -strip -quality 88 "$jpg"
    local jsz; jsz="$(stat -c%s "$jpg")"
    echo "  [$key] PNG ${sz}B over budget — wrote JPG fallback ${jsz}B at $jpg" >&2
    sz="${sz} (PNG) / ${jsz} (JPG fallback)"
  fi

  printf '%-16s | %-9s | %s | %sB\n' "$key" "$mode" "$recipe_note" "$sz"
}

# ---------------------------------------------------------------------------------------------------
# Main: build the requested plugins (default: all 9).
# ---------------------------------------------------------------------------------------------------
declare -a TARGETS=("$@")
echo "rig: $COMFYUI  (vector_only=$VECTOR_ONLY, tries=$RIG_TRIES)" >&2
echo "----- banner build report -----"
printf '%-16s | %-9s | %s | %s\n' "plugin" "mode" "recipe" "size"
while IFS= read -r line; do
  [ -n "$line" ] || continue
  key="${line%%|*}"
  if [ "${#TARGETS[@]}" -gt 0 ]; then
    match=0; for t in "${TARGETS[@]}"; do [ "$t" = "$key" ] && match=1; done
    [ "$match" = "1" ] || continue
  fi
  build_one "$line"
done <<<"$PLUGINS"
echo "-------------------------------"
