#!/usr/bin/env bash
# Phase 7 — regenerate the 5 plugin heroes through the multi-stage lora-detail pipeline
# (LoRA dark-key stack -> base -> latent hires-fix), art-directed prompts. Single GPU, sequential.
set -u
U="${PRESSROOM_COMFYUI_URL:-http://10.10.10.163:8188}"
ROOT="/home/user/Code/idea-to-production"
OUT="$ROOT/doc/image-craft-study/verification/new"
TPL="$ROOT/comfyui-mcp/workflows/lora-detail.json"
mkdir -p "$OUT"
NEG="text, words, letters, numbers, watermark, signature, logo, ui, labels, people, person, human, figure, hands, face, bright sky, daylight, white background, overexposed, washed out, flat lighting, blurry, lowres, jpeg artifacts, deformed, cluttered, oversaturated, cartoonish"

gen () { # $1 name  $2 ckpt  $3 seed  $4 positive
  local name="$1" ckpt="$2" seed="$3" pos="$4"
  echo ">>> $name  ($ckpt, seed $seed)"
  jq --arg pos "$pos" --arg neg "$NEG" --arg ckpt "$ckpt" --argjson seed "$seed" '
    del(._meta)
    | .["4"].inputs.ckpt_name=$ckpt
    | .["20"].inputs.lora_name="lowkey_v1.1.safetensors" | .["20"].inputs.strength_model=0.55 | .["20"].inputs.strength_clip=0.55
    | .["21"].inputs.lora_name="LowRA.safetensors"       | .["21"].inputs.strength_model=0.35 | .["21"].inputs.strength_clip=0.35
    | .["5"].inputs.width=1216 | .["5"].inputs.height=832
    | .["3"].inputs.seed=$seed | .["6"].inputs.text=$pos | .["7"].inputs.text=$neg
    | .["10"].inputs.scale_by=1.5 | .["11"].inputs.denoise=0.45
  ' "$TPL" > /tmp/wf_$name.json
  local pid
  pid=$(curl -s -m 20 "$U/prompt" -X POST -H 'Content-Type: application/json' \
        --data "$(jq -n --slurpfile p /tmp/wf_$name.json --arg c "regen-$name" '{prompt:$p[0], client_id:$c}')" \
        | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('prompt_id','ERR:'+json.dumps(d)[:200]))")
  echo "    pid=$pid"
  for i in $(seq 1 90); do
    r=$(curl -s -m 10 "$U/history/$pid" | python3 -c "import sys,json
try:
 d=json.load(sys.stdin); o=d.get('$pid',{}).get('outputs',{})
 im=o.get('9',{}).get('images',[])
 print(im[0]['filename']+'|'+im[0].get('subfolder','')) if im else print('WAIT')
except: print('WAIT')")
    [ "$r" != "WAIT" ] && { fn="${r%%|*}"; sub="${r##*|}"; curl -s -m 30 "$U/view?filename=$fn&subfolder=$sub&type=output" -o "$OUT/$name.png"; echo "    saved $OUT/$name.png"; return; }
    sleep 4
  done
  echo "    TIMEOUT $name"
}

gen i2p            "protovisionXLHighFidelity3D_beta0520Bakedvae.safetensors" 42 \
"a grand luminous gateway archway opening onto a vast constellation of glowing nodes receding into deep space, a single bright amber keystone crowning the teal-lit arch with a god-ray beam, cinematic concept art, volumetric light, chiaroscuro, one strong central focal point, complementary teal and amber colour script, atmospheric perspective, deep near-black low-key background, intricate detail, masterpiece"

gen sentinel       "juggernautXL_version2.safetensors" 77 \
"a lone vigilant lighthouse on a dark rocky headland at night, a warm amber beacon glowing at its summit casting a volumetric teal scanning beam across a luminous bioluminescent cyan shoreline below, cinematic, chiaroscuro, strong single focal point on the rim-lit tower, complementary teal and amber, deep low-key night, atmospheric haze, masterpiece concept art"

gen atelier        "dynavisionXLAllInOneStylized_beta0411Bakedvae.safetensors" 614 \
"a master craftsman's design atelier at night, an angled drafting table glowing with abstract cyan holographic wireframe blueprints, a warm amber desk lamp pooling motivated light over wooden surfaces, elegant drafting tools at rest, dark wood-panelled studio, chiaroscuro, strong focal point on the lit drafting desk, complementary teal and amber colour script, low-key, depth of field, cinematic, masterpiece"

gen concierge      "juggernautXL_version2.safetensors" 303 \
"a warm welcoming tall arched doorway at night, a glowing amber lantern spilling warm motivated light across a teal-dark wood-panelled entrance hall with a wooden floor, an inviting threshold, cinematic, warm-cool temperature contrast, strong focal point on the lit doorway, low-key, atmospheric depth, masterpiece concept art"

gen mission-control "protovisionXLHighFidelity3D_beta0520Bakedvae.safetensors" 503 \
"a calm empty futuristic mission control operations room, a large central glowing teal globe beneath a warm amber ceiling dome, symmetric curved banks of monitors showing only abstract glowing teal waveforms, empty operator chairs, motivated screen-glow lighting, strong central focal point, complementary teal and amber colour script, deep low-key, cinematic depth, masterpiece concept art"

echo "ALL DONE"
