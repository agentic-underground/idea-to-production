#!/usr/bin/env python3
"""Adaptation pass for the ComfyUI workflow-mining study.

For each mined PNG under raw/official/:
  1. Extract the embedded API `prompt` graph (via extract-workflow.py's reader).
  2. Map every referenced asset to the nearest available rig asset, against the
     live object_info menus snapshotted into LIVE_MENUS below.
  3. Classify the adapted graph: rerunnable | needs-input | merge (or dropped).
  4. Emit adapted/NN-<slug>.json, append to adaptation-journal.jsonl, and rebuild
     catalog.md.

Pure stdlib. Parameter-only — no untrusted text ever reaches a shell.
Idempotent: overwrites adapted/*.json, truncates+rewrites journal and catalog.
"""
import os, sys, json, re, struct, zlib

HERE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(HERE, "raw", "official")
ADAPTED = os.path.join(HERE, "adapted")
JOURNAL = os.path.join(HERE, "adaptation-journal.jsonl")
CATALOG = os.path.join(HERE, "catalog.md")

# ---------------------------------------------------------------------------
# PNG text-chunk reader (same logic as extract-workflow.py, inlined for one pass)
# ---------------------------------------------------------------------------
def png_text_chunks(path):
    meta = {}
    with open(path, "rb") as f:
        if f.read(8) != b"\x89PNG\r\n\x1a\n":
            raise ValueError("not a PNG")
        while True:
            ln = f.read(4)
            if len(ln) < 4:
                break
            n = struct.unpack(">I", ln)[0]
            ctype = f.read(4)
            data = f.read(n)
            f.read(4)
            if ctype == b"tEXt":
                k, _, v = data.partition(b"\x00")
                meta[k.decode("latin-1")] = v.decode("utf-8", "ignore")
            elif ctype == b"zTXt":
                k, _, rest = data.partition(b"\x00")
                try:
                    meta[k.decode("latin-1")] = zlib.decompress(rest[1:]).decode("utf-8", "ignore")
                except Exception:
                    pass
            elif ctype == b"iTXt":
                k, _, rest = data.partition(b"\x00")
                comp_flag = rest[0] if rest else 0
                body = rest[2:]
                _, _, body = body.partition(b"\x00")
                _, _, body = body.partition(b"\x00")
                if comp_flag == 1:
                    try:
                        body = zlib.decompress(body)
                    except Exception:
                        pass
                meta[k.decode("latin-1")] = body.decode("utf-8", "ignore")
            elif ctype == b"IEND":
                break
    return meta

# ---------------------------------------------------------------------------
# Live rig menus (snapshotted from object_info on the run date). Used both to
# detect exact/basename matches and as the candidate pool for substitution.
# ---------------------------------------------------------------------------
LIVE = {
    "ckpt": set(),       # filled below
    "lora": set(),
    "upscale": set(),
    "controlnet": set(),
    "vae": set(),
    "clipvision": {"clip_vision_g.safetensors"},
    "gligen": set(),     # empty on rig
    "hypernetwork": set(),  # empty on rig
}

LIVE["ckpt"] = set("""512-base-ema.ckpt 512-inpainting-ema.safetensors 768-v-ema.ckpt 7Of9_v20.safetensors
LIGHTNING/RealitiesEdgeXLLIGHTNING_V7Bakedvae.safetensors LIGHTNING/airtistRealisticXL_v50Lightning.safetensors
LIGHTNING/amalgamationxl_v2XLightning2.safetensors LIGHTNING/colorfulxlLightning_v16.safetensors
LIGHTNING/copaxArtBrush_v1Lightning.safetensors LIGHTNING/dreamshaperXL_lightningInpaint.safetensors
LIGHTNING/easymodeXLTurbo_v10Lightning.safetensors LIGHTNING/juggernautXL_v9Rdphoto2Lightning.safetensors
LIGHTNING/truesketchsdxl_v10.safetensors LahCuteCartoonSDXL_alpha.safetensors RealitiesEdgeXLANIME_20.safetensors
RealitiesEdgeXL_4.safetensors SDXL/LahCuteCartoonSDXL_alpha.safetensors SDXL/sd_xl_base_1.0.safetensors
SDXL/sd_xl_refiner_1.0.safetensors SDXL/svd_xt_1_1.safetensors aio_v10.safetensors animagineXL_v10.safetensors
animeArtDiffusionXL_alpha3.safetensors animeChangefulXL_v10ReleasedCandidate.safetensors artisanalXL_alpha1.safetensors
astreapixieXLAnime_v16.safetensors blackHOLE_tachyon.safetensors bluePencilXL_v050.safetensors
breakdomainxl_v03d.safetensors cardosAnimated_v20.safetensors colossusProjectXLSFW_v10BakedVAEFP16.safetensors
copaxCuteXLSDXL10_v4.safetensors counterfeitxl_v10.safetensors crystalClearXL_ccxl.safetensors
cyberrealistic_v31.safetensors digimaginationXL_v10.safetensors dreamshaper_5BakedVae.safetensors
dreamshaper_8.safetensors dreamshaper_8Inpainting.safetensors duchaitenAiartSDXL_v10.safetensors
dynavisionXLAllInOneStylized_beta0411Bakedvae.safetensors epicdream_lullaby.safetensors
epicrealism_naturalSinRC1VAE.safetensors epicrealism_v10-inpainting.safetensors fantasticCharacters_v55.safetensors
foddaxlPhotorealism_v51.safetensors forrealxl_v05.safetensors fullyREALXL_v90Vividreal.safetensors
infinianimexl_v16.safetensors insomnia_v11.safetensors juggernautXL_version2.safetensors lunaMia_v40.safetensors
mbbxlUltimate_v10RC.safetensors modernDisneyXL_v11.safetensors
nightvisionXLPhotorealisticPortrait_v0743ReleaseBakedvae.safetensors nigi-cyber-umaaji.safetensors
nigi3d_v20.safetensors nijianimesdxl_v10.safetensors nodesAndConnectionsXL_v10.safetensors
notAnimefullFinalXL_v10.safetensors novaPrimeXL_v10.safetensors oasisSDXL_v10.safetensors peaeXl_v10.safetensors
photoVisionXL_v10.safetensors pixelwave_02.safetensors protovisionXLHighFidelity3D_beta0520Bakedvae.safetensors
psyAnimatedXL_v11.safetensors razorcream_v10.safetensors realcartoon3d_v15-inpainting.safetensors
realcartoon3d_v8.safetensors realcartoonXL_v3.safetensors realisticStockPhoto_v10.safetensors
reproductionSDXL_2v12.safetensors rundiffusionXL_beta.safetensors samaritan3dCartoon_v40SDXL.safetensors
sdxlEvolvedAesthetic_v10.safetensors sdxlEvolved_v10.safetensors sdxlYamersAnime_stageAnima.safetensors
sdxlYamersRealism_version2.safetensors stableDiffusionXL_v30.safetensors truesketchsdxl_v10.safetensors
ultralight_04.safetensors ultriumV70SDXLVAE.safetensors ultriumV80NSFWSFWSDXL_ultriumV70SDXLVAE.safetensors
v2-1_768-ema-pruned.safetensors vision25dXL10_v30.safetensors xlArtSupply_c10.safetensors
xlYamersCartoonArcadia_v1.safetensors zavychromaxl_v12.safetensors ziovXLScifiGiantRobotsSky_v10.safetensors""".split())

LIVE["upscale"] = set("""ESRGAN/4x-UltraSharp.pth ESRGAN/4x-UniScaleV2_Moderate.pth ESRGAN/4x-UniScaleV2_Sharp.pth
ESRGAN/4x-UniScaleV2_Soft.pth ESRGAN/4x-UniScale_Restore.pth ESRGAN/4xLSDIRplus.pth ESRGAN/4xLSDIRplusR.pth
ESRGAN/4x_NMKD-Superscale-SP_178000_G.pth ESRGAN/4x_foolhardy_Remacri.pth ESRGAN/BSRGAN.pth ESRGAN/DF2K.pth
ESRGAN/DF2K_JPEG.pth ESRGAN/ESRGAN_4x.pth ESRGAN/RealESRGAN_x4plus.pth ESRGAN/realesr-general-x4v3.pth
RealESRGAN/RealESRGAN_x2plus.pth RealESRGAN/RealESRGAN_x4plus.pth RealESRGAN/RealESRGAN_x4plus_anime_6B.pth
RealESRGAN/realesr-animevideov3.pth RealESRGAN/realesr-general-wdn-x4v3.pth RealESRGAN/realesr-general-x4v3.pth
SwinIR/001_classicalSR_DF2K_s64w8_SwinIR-M_x4.pth SwinIR/2xLexicaSwinIR.pth SwinIR/SwinIR_4x.pth""".split())

LIVE["controlnet"] = set("""ControlNet-v1-1/control_v11e_sd15_ip2p.pth ControlNet-v1-1/control_v11e_sd15_shuffle.pth
ControlNet-v1-1/control_v11f1e_sd15_tile.pth ControlNet-v1-1/control_v11f1p_sd15_depth.pth
ControlNet-v1-1/control_v11p_sd15_canny.pth ControlNet-v1-1/control_v11p_sd15_inpaint.pth
ControlNet-v1-1/control_v11p_sd15_lineart.pth ControlNet-v1-1/control_v11p_sd15_mlsd.pth
ControlNet-v1-1/control_v11p_sd15_normalbae.pth ControlNet-v1-1/control_v11p_sd15_openpose.pth
ControlNet-v1-1/control_v11p_sd15_scribble.pth ControlNet-v1-1/control_v11p_sd15_seg.pth
ControlNet-v1-1/control_v11p_sd15_softedge.pth ControlNet-v1-1/control_v11p_sd15s2_lineart_anime.pth
control-lora/control-LoRAs-rank256/control-lora-canny-rank256.safetensors
control-lora/control-LoRAs-rank256/control-lora-depth-rank256.safetensors
controlnet-canny-sdxl-1.0/diffusion_pytorch_model.safetensors
controlnet-openpose-sdxl-1.0/OpenPoseXL2.safetensors""".split())

LIVE["vae"] = set("""SD1.x/Anything-V3.0.vae.pt SD1.x/color101VAE_v1.pt SD1.x/customvae_q6.safetensors
SD1.x/customvae_q6b.safetensors SD1.x/customvae_v10.pt SD1.x/customvae_v20.pt SD1.x/customvae_v22.safetensors
SD1.x/difconsistencyRAWVAE_v10LOWSafestensor.safetensors SD1.x/difconsistencyRAWVAE_v10MEDIUMSafestensor.safetensors
SD1.x/difconsistencyRAWVAE_v10Safestensor.safetensors SD1.x/fixYourColorsVAE_vaeFtMse840000Ema.ckpt
SD1.x/kl-f8-anime2.vae.pt SD1.x/mangledMergeVAE_v10.pt SD1.x/rmada-cold-vae.ckpt
SD1.x/toneRangeCompressor_trcvae.safetensors SD1.x/vae-ft-mse-840000-ema-pruned.safetensors
SD1.x/vaeFtMse840000Ema_v10.safetensors SD1.x/vaeFtMse840000Ema_v100.pt SD1.x/zVae_v10.safetensors
SDXL/BreakDomainXL_VAE.safetensors SDXL/sdxl-vae-fp16-fix.safetensors SDXL/sdxl_vae.1.safetensors
SDXL/stabilityai-sdxl_vae.safetensors""".split())

LIVE["lora"] = {"LowRA.safetensors", "SDXL/xl_more_art-full_v1.safetensors",
                "xl_more_art-full_v1.safetensors", "epiNoiseoffset_placeholder"}  # full lora set not needed; pool subset

# Substitution analogs of the same family. Each value is (live_name, kind)
# where kind ∈ {keep, path-move, substitute}. path-move = same model, different
# folder/extension; substitute = nearest analog of the same model family.
CKPT_MAP = {
    "v1-5-pruned-emaonly.ckpt":            ("dreamshaper_8.safetensors", "substitute"),
    "Anything-V3.0.ckpt":                  ("cardosAnimated_v20.safetensors", "substitute"),
    "cardosAnime_v10.safetensors":         ("cardosAnimated_v20.safetensors", "substitute"),
    "cardosAnimated_v20.safetensors":      ("cardosAnimated_v20.safetensors", "keep"),
    "AbyssOrangeMix2_hard.safetensors":    ("cardosAnimated_v20.safetensors", "substitute"),
    "AOM3A1.safetensors":                  ("cardosAnimated_v20.safetensors", "substitute"),
    "AOM3A3.safetensors":                  ("cardosAnimated_v20.safetensors", "substitute"),
    "wd-illusion-fp16.safetensors":        ("cardosAnimated_v20.safetensors", "substitute"),
    "sd-v1-5-inpainting.ckpt":             ("512-inpainting-ema.safetensors", "substitute"),
    "512-inpainting-ema.safetensors":      ("512-inpainting-ema.safetensors", "keep"),
    "v2-1_768-ema-pruned.ckpt":            ("v2-1_768-ema-pruned.safetensors", "path-move"),
    "sd_xl_base_1.0.safetensors":          ("SDXL/sd_xl_base_1.0.safetensors", "path-move"),
    "sd_xl_1.0.safetensors":               ("SDXL/sd_xl_base_1.0.safetensors", "substitute"),
    "sd_xl_refiner_1.0.safetensors":       ("SDXL/sd_xl_refiner_1.0.safetensors", "path-move"),
    "sd_xl_turbo_1.0_fp16.safetensors":    ("LIGHTNING/easymodeXLTurbo_v10Lightning.safetensors", "substitute"),
    "cosxl.safetensors":                   ("SDXL/sd_xl_base_1.0.safetensors", "substitute"),
    "albedobaseXL_v21.safetensors":        ("juggernautXL_version2.safetensors", "substitute"),
}
VAE_MAP = {
    "vae-ft-mse-840000-ema-pruned.safetensors": ("SD1.x/vae-ft-mse-840000-ema-pruned.safetensors", "path-move"),
    "kl-f8-anime2.ckpt":                         ("SD1.x/kl-f8-anime2.vae.pt", "path-move"),
}
LORA_MAP = {
    "theovercomer8sContrastFix_sd15.safetensors": ("LowRA.safetensors", "substitute"),
    "epiNoiseoffset_v2.safetensors":              ("LowRA.safetensors", "substitute"),
    "lcm_lora_sdxl.safetensors":                  ("SDXL/xl_more_art-full_v1.safetensors", "substitute"),
}
CN_MAP = {
    "control_scribble.safetensors":          ("ControlNet-v1-1/control_v11p_sd15_scribble.pth", "substitute"),
    "control_openpose.safetensors":          ("ControlNet-v1-1/control_v11p_sd15_openpose.pth", "substitute"),
    "t2iadapter_depth_sd14v1.pth":           ("ControlNet-v1-1/control_v11f1p_sd15_depth.pth", "substitute"),
    "diff_control_sd15_depth_fp16.safetensors": ("ControlNet-v1-1/control_v11f1p_sd15_depth.pth", "substitute"),
}
UPSCALE_MAP = {
    "RealESRGAN_x4plus.pth": ("RealESRGAN/RealESRGAN_x4plus.pth", "path-move"),
    "RealESRGAN_x2.pth":     ("RealESRGAN/RealESRGAN_x2plus.pth", "substitute"),
}
CLIPVISION_MAP = {
    "clip_vision_g.safetensors": ("clip_vision_g.safetensors", "keep"),
}

# Asset class → (input key, lookup map, drop-if-no-analog flag)
ASSET_FIELDS = {
    "CheckpointLoaderSimple":  ("ckpt_name", CKPT_MAP, "checkpoint"),
    "unCLIPCheckpointLoader":  ("ckpt_name", None, "unclip-checkpoint"),  # no analog → drop
    "LoraLoader":              ("lora_name", LORA_MAP, "lora"),
    "UpscaleModelLoader":      ("model_name", UPSCALE_MAP, "upscale"),
    "ControlNetLoader":        ("control_net_name", CN_MAP, "controlnet"),
    "DiffControlNetLoader":    ("control_net_name", CN_MAP, "controlnet"),
    "VAELoader":               ("vae_name", VAE_MAP, "vae"),
    "CLIPVisionLoader":        ("clip_name", CLIPVISION_MAP, "clipvision"),
    "GLIGENLoader":            ("gligen_name", None, "gligen"),          # no analog → drop
    "HypernetworkLoader":      ("hypernetwork_name", None, "hypernetwork"),  # no analog → drop
}

# ---------------------------------------------------------------------------
def slug_for(fname):
    base = fname[:-4] if fname.endswith(".png") else fname
    s = re.sub(r"[^a-z0-9]+", "-", base.lower()).strip("-")
    return s

def classify(graph):
    """rerunnable | needs-input | merge — by structure."""
    types = {n.get("class_type", "") for n in graph.values()}
    if any(t.startswith("ModelMerge") or t.startswith("CLIPMerge") for t in types):
        return "merge"
    # build id->classtype
    ct = {nid: n.get("class_type", "") for nid, n in graph.items()}
    # find LoadImage node ids
    loadimg = {nid for nid, t in ct.items() if t in ("LoadImage", "LoadImageMask")}
    if not loadimg:
        return "rerunnable"
    # does any LoadImage feed (transitively, 1-hop is enough for these graphs)
    # a control/inpaint/img2img/unclip consumer? Consumers we treat as input-bound:
    INPUT_CONSUMERS = {
        "ControlNetApply", "ControlNetApplyAdvanced", "ControlNetApplySD3",
        "VAEEncodeForInpaint", "VAEEncode", "unCLIPConditioning",
        "CLIPVisionEncode", "GLIGENTextBoxApply", "ImageScale",  # img2img usually scales the source
    }
    # Any node that consumes a LoadImage output and is an input-consumer → needs-input.
    # Generic: if a LoadImage feeds *anything* that is not purely a SaveImage/PreviewImage,
    # the graph depends on an external raster we don't have.
    for nid, n in graph.items():
        consumer_t = n.get("class_type", "")
        for v in n.get("inputs", {}).values():
            if isinstance(v, list) and len(v) == 2 and isinstance(v[0], str) and v[0] in loadimg:
                if consumer_t in INPUT_CONSUMERS or consumer_t in (
                    "VAEEncodeForInpaint", "ControlNetApply"):
                    return "needs-input"
                # any other consumer of a loaded image that is not a save/preview
                if consumer_t not in ("SaveImage", "PreviewImage"):
                    return "needs-input"
    return "rerunnable"

def adapt_graph(graph):
    """Mutate asset names in-place; return (substitutions, drop_reason|None)."""
    subs = []
    for nid, n in graph.items():
        ct = n.get("class_type", "")
        if ct not in ASSET_FIELDS:
            continue
        key, amap, cls = ASSET_FIELDS[ct]
        ins = n.get("inputs", {})
        if key not in ins or not isinstance(ins[key], str):
            continue
        cur = ins[key]
        if amap is None:
            # asset class has no analog on the rig → drop the whole graph
            return subs, f"{cls} required but no analog on rig ({cur})"
        # exact match in live menu?
        live_set = {
            "checkpoint": LIVE["ckpt"], "lora": LIVE["lora"], "upscale": LIVE["upscale"],
            "controlnet": LIVE["controlnet"], "vae": LIVE["vae"], "clipvision": LIVE["clipvision"],
        }.get(cls, set())
        if cur in live_set:
            continue  # keep as-is, exact
        if cur in amap:
            new, kind = amap[cur]
            if new != cur:
                ins[key] = new
                if kind != "keep":
                    subs.append({"class": cls, "from": cur, "to": new})
            continue
        # unknown asset with a map but no entry → cannot resolve safely → drop
        return subs, f"{cls} reference '{cur}' not resolvable against rig menu"
    return subs, None

def technique_of(graph):
    types = {n.get("class_type", "") for n in graph.values()}
    tags = []
    if any(t.startswith("ModelMerge") or t.startswith("CLIPMerge") for t in types):
        tags.append("merge")
    if "ControlNetLoader" in types or "DiffControlNetLoader" in types or "ControlNetApply" in types:
        tags.append("controlnet")
    if "VAEEncodeForInpaint" in types or any("inpaint" in t.lower() for t in types):
        tags.append("inpaint")
    if "LoraLoader" in types:
        tags.append("lora")
    if "unCLIPConditioning" in types or "unCLIPCheckpointLoader" in types or "CLIPVisionEncode" in types:
        tags.append("unclip")
    if "GLIGENLoader" in types or "GLIGENTextBoxApply" in types:
        tags.append("gligen")
    if "HypernetworkLoader" in types:
        tags.append("hypernetwork")
    if any(t in types for t in ("ImageUpscaleWithModel", "LatentUpscale", "LatentUpscaleBy", "ImageScale")):
        tags.append("hires")
    if any("ConditioningSetArea" == t or "ConditioningCombine" == t for t in types):
        tags.append("area-composition")
    return tags or ["txt2img"]

def family_of(graph):
    """Infer model family from the checkpoint name first (most reliable), then
    fall back to native resolution. Resolution alone is unreliable: SD1.5
    workflows often use wide/tall aspect ratios whose long edge exceeds 1024."""
    names = []
    res = []
    for n in graph.values():
        ct = n.get("class_type", "")
        ins = n.get("inputs", {})
        if "ckpt_name" in ins and isinstance(ins["ckpt_name"], str):
            names.append(ins["ckpt_name"])
        if ct == "EmptyLatentImage":
            w = ins.get("width"); h = ins.get("height")
            if isinstance(w, int) and isinstance(h, int):
                res.append((w, h))
    joined = " ".join(names).lower()
    # checkpoint-name signal (post-substitution these are known rig models)
    if "sdxl" in joined or re.search(r"xl[/_.]|/sd_xl|cosxl|turbo|lightning", joined):
        return "SDXL"
    if "768" in joined or "v2-1" in joined or "v-ema" in joined or "768-v-ema" in joined:
        return "SD2.1"
    if names:
        return "SD1.5"
    # no checkpoint name at all → fall back to a square-shortest-edge heuristic
    if any(min(w, h) >= 1024 for w, h in res):
        return "SDXL"
    return "SD1.5"

GOOD_FOR = {
    "2-pass-txt2img-hiresfix-esrgan-workflow": "two-pass hi-res txt2img with an ESRGAN model upscale between passes",
    "2-pass-txt2img-hiresfix-latent-workflow": "two-pass hi-res via latent upscale (classic hiresfix)",
    "2-pass-txt2img-latent-upscale-different-prompt-model": "latent-upscale second pass with a different prompt/model for detail",
    "area-composition-morning-day-evening-night": "area-conditioned scene split into time-of-day quadrants",
    "area-composition-night-evening-day-morning": "area-conditioned time-of-day gradient (reverse order)",
    "area-composition-night-evening-day-morning-subject": "time-of-day area split with a foreground subject region",
    "area-composition-square-area-for-2-subjects-first-pass": "two-subject area composition, first pass",
    "area-composition-square-area-for-2-subjects": "two subjects placed in separate square areas",
    "area-composition-square-area-for-subject": "single subject confined to a square area",
    "area-composition-workflow-night-evening-day-morning": "full area-composition workflow over a day cycle",
    "controlnet-2-pass-pose-worship": "pose-guided generation refined in a second pass",
    "controlnet-controlnet-example": "basic ControlNet conditioning from a hint image",
    "controlnet-depth-controlnet": "depth-map guided generation",
    "controlnet-depth-t2i-adapter": "lightweight depth T2I-adapter guidance",
    "controlnet-house-scribble": "scribble-to-image of a house",
    "controlnet-input-scribble-example": "scribble ControlNet from an input sketch",
    "controlnet-mixing-controlnets": "stacking two ControlNets on one generation",
    "controlnet-pose-present": "openpose-guided figure presenting",
    "controlnet-pose-worship": "openpose-guided worship pose",
    "controlnet-shark-depthmap": "depth-guided shark scene",
    "img2img-img2img-workflow": "denoise-from-source img2img",
    "inpaint-inpain-model-cat": "inpaint a cat with a dedicated inpainting model",
    "inpaint-inpain-model-outpainting": "outpainting via the inpaint model + pad",
    "inpaint-inpain-model-woman": "portrait inpaint with the inpainting model",
    "inpaint-inpaint-anythingv3-woman": "anime portrait inpaint",
    "inpaint-inpaint-example": "basic masked inpaint",
    "inpaint-yosemite-inpaint-example": "landscape inpaint over a photo",
    "inpaint-yosemite-outpaint-example": "landscape outpaint extending a photo",
    "lcm-lcm-basic-example": "few-step LCM-LoRA fast sampling",
    "lora-lora-multiple": "stacking multiple LoRAs",
    "lora-lora": "single-LoRA style application",
    "model-merging-model-merging-3-checkpoints": "block-merge of three checkpoints",
    "model-merging-model-merging-basic": "simple weighted two-checkpoint merge",
    "model-merging-model-merging-cosxl": "CosXL add/subtract SDXL merge recipe",
    "model-merging-model-merging-inpaint": "transplant inpainting capability via add/subtract merge",
    "model-merging-model-merging-lora": "bake a LoRA into a merged checkpoint",
    "noisy-latent-composition-noisy-latents-3-subjects": "compose three subjects from noisy latent regions",
    "noisy-latent-composition-noisy-latents-3-subjects-": "noisy-latent 3-subject composition (variant)",
    "sdturbo-sdxlturbo-example": "single-step SDXL-Turbo generation",
    "sdxl-sdxl-refiner-prompt-example": "SDXL base + refiner two-stage prompt",
    "sdxl-sdxl-revision-text-prompts": "SDXL Revision image-prompt + text",
    "sdxl-sdxl-revision-zero-positive": "SDXL Revision with zeroed positive",
    "sdxl-sdxl-simple-example": "minimal SDXL base txt2img",
    "textual-inversion-embeddings-embedding-example": "textual-inversion embedding in the prompt",
    "upscale-models-esrgan-example": "pure ESRGAN model upscale of a generation",
}

def main():
    os.makedirs(ADAPTED, exist_ok=True)
    pngs = sorted(f for f in os.listdir(RAW) if f.endswith(".png"))
    # clear old adapted json
    for f in os.listdir(ADAPTED):
        if f.endswith(".json"):
            os.remove(os.path.join(ADAPTED, f))
    journal = []
    counter = 0
    for fname in pngs:
        path = os.path.join(RAW, fname)
        slug = slug_for(fname)
        meta = png_text_chunks(path)
        if "prompt" not in meta:
            journal.append({"source": fname, "slug": slug, "family": None,
                            "classification": None, "substitutions": [], "dropped": True,
                            "drop_reason": "input/hint asset (scribble/pose/depth/source/reference image) — no embedded ComfyUI prompt graph", "adapted_file": None,
                            "node_count": 0})
            continue
        graph = json.loads(meta["prompt"])
        node_count = len(graph)
        family = family_of(graph)
        classification = classify(graph)
        subs, drop_reason = adapt_graph(graph)
        if drop_reason:
            journal.append({"source": fname, "slug": slug, "family": family,
                            "classification": classification, "substitutions": subs,
                            "dropped": True, "drop_reason": drop_reason,
                            "adapted_file": None, "node_count": node_count})
            continue
        counter += 1
        adapted_file = f"{counter:02d}-{slug}.json"
        with open(os.path.join(ADAPTED, adapted_file), "w") as fh:
            json.dump(graph, fh, indent=2, ensure_ascii=False)
        journal.append({"source": fname, "slug": slug, "family": family,
                        "classification": classification, "substitutions": subs,
                        "dropped": False, "drop_reason": None,
                        "adapted_file": f"adapted/{adapted_file}", "node_count": node_count})

    with open(JOURNAL, "w") as fh:
        for row in journal:
            fh.write(json.dumps(row, ensure_ascii=False) + "\n")

    write_catalog(journal)
    return journal

def write_catalog(journal):
    kept = [r for r in journal if not r["dropped"]]
    dropped = [r for r in journal if r["dropped"]]
    by_class = {}
    for r in kept:
        by_class.setdefault(r["classification"], []).append(r)
    total_subs = sum(len(r["substitutions"]) for r in journal)
    rerunnable = [r for r in kept if r["classification"] == "rerunnable"]

    lines = []
    lines.append("# Adapted ComfyUI workflow catalog\n")
    lines.append("Adaptation pass over the 53 mined community/official workflows: every referenced asset")
    lines.append("remapped to the live rig menus, each graph classified for headless re-run.\n")
    lines.append("## Summary\n")
    lines.append("| Metric | Count |")
    lines.append("| --- | --- |")
    lines.append(f"| Source PNGs | {len(journal)} |")
    lines.append(f"| Adapted (kept) | {len(kept)} |")
    for c in ("rerunnable", "needs-input", "merge"):
        lines.append(f"| &nbsp;&nbsp;{c} | {len(by_class.get(c, []))} |")
    lines.append(f"| Rerunnable (auto) | {len(rerunnable)} |")
    lines.append(f"| Total substitutions | {total_subs} |")
    lines.append(f"| Dropped | {len(dropped)} |")
    lines.append("")

    def subs_str(r):
        if not r["substitutions"]:
            return "—"
        return "; ".join(f"`{s['from']}`→`{s['to']}` ({s['class']})" for s in r["substitutions"])

    # need the graph technique — recompute from adapted file
    def tech_for(r):
        if not r["adapted_file"]:
            return ""
        with open(os.path.join(HERE, r["adapted_file"])) as fh:
            g = json.load(fh)
        return ", ".join(technique_of(g))

    for c in ("rerunnable", "needs-input", "merge"):
        rows = by_class.get(c, [])
        if not rows:
            continue
        lines.append(f"## {c}  ({len(rows)})\n")
        for r in sorted(rows, key=lambda x: x["adapted_file"]):
            num = os.path.basename(r["adapted_file"]).split("-")[0]
            good = GOOD_FOR.get(r["slug"], "")
            lines.append(f"### {num} · `{r['slug']}`")
            lines.append(f"- **family**: {r['family']}  ·  **technique**: {tech_for(r)}")
            lines.append(f"- **file**: `{r['adapted_file']}`  ·  **nodes**: {r['node_count']}")
            lines.append(f"- **substitutions**: {subs_str(r)}")
            if good:
                lines.append(f"- **good for**: {good}")
            lines.append("")

    if dropped:
        lines.append(f"## dropped  ({len(dropped)})\n")
        lines.append("| source | family | reason |")
        lines.append("| --- | --- | --- |")
        for r in dropped:
            lines.append(f"| `{r['source']}` | {r['family'] or '?'} | {r['drop_reason']} |")
        lines.append("")

    with open(CATALOG, "w") as fh:
        fh.write("\n".join(lines))

if __name__ == "__main__":
    j = main()
    kept = [r for r in j if not r["dropped"]]
    print(f"sources={len(j)} kept={len(kept)} dropped={len(j)-len(kept)} "
          f"subs={sum(len(r['substitutions']) for r in j)}")
