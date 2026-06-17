#!/usr/bin/env python3
"""build_graph.py — emit a ComfyUI txt2img API graph (deterministic, no model tokens).

Node ids match comfyui-mcp/workflows/txt2img-basic.json plus two extra nodes that move the
catalog-thumbnail RESIZE onto the GPU box (10 ImageScaleBy -> 11 SaveImage), so no local image
tooling is needed. With --no-thumb (validation) those two nodes are omitted.

Outputs a {"prompt": <graph>, "client_id": "..."} JSON object on stdout.
"""
import argparse, json, sys


def build(a):
    g = {
        "3": {"class_type": "KSampler", "inputs": {
            "seed": a.seed, "steps": a.steps, "cfg": a.cfg,
            "sampler_name": a.sampler, "scheduler": a.scheduler, "denoise": 1.0,
            "model": ["4", 0], "positive": ["6", 0], "negative": ["7", 0], "latent_image": ["5", 0]}},
        "4": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": a.ckpt}},
        "5": {"class_type": "EmptyLatentImage", "inputs": {"width": a.width, "height": a.height, "batch_size": 1}},
        "6": {"class_type": "CLIPTextEncode", "inputs": {"text": a.pos, "clip": ["4", 1]}},
        "7": {"class_type": "CLIPTextEncode", "inputs": {"text": a.neg, "clip": ["4", 1]}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["3", 0], "vae": ["4", 2]}},
        "9": {"class_type": "SaveImage", "inputs": {"filename_prefix": a.prefix + "-full", "images": ["8", 0]}},
    }
    if not a.no_thumb:
        # GPU-side downscale -> a small catalog thumbnail. ImageScaleBy preserves aspect.
        g["10"] = {"class_type": "ImageScaleBy", "inputs": {
            "image": ["8", 0], "upscale_method": "lanczos", "scale_by": a.thumb_scale}}
        g["11"] = {"class_type": "SaveImage", "inputs": {"filename_prefix": a.prefix + "-thumb", "images": ["10", 0]}}
    return {"prompt": g, "client_id": a.client_id}


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--ckpt", required=True)
    p.add_argument("--pos", required=True)
    p.add_argument("--neg", default="")
    p.add_argument("--seed", type=int, default=1)
    p.add_argument("--steps", type=int, default=25)
    p.add_argument("--cfg", type=float, default=7.0)
    p.add_argument("--sampler", default="dpmpp_2m")
    p.add_argument("--scheduler", default="karras")
    p.add_argument("--width", type=int, default=768)
    p.add_argument("--height", type=int, default=512)
    p.add_argument("--prefix", default="survey")
    p.add_argument("--client-id", default="model-survey")
    p.add_argument("--thumb-scale", type=float, default=0.4)
    p.add_argument("--no-thumb", action="store_true")
    a = p.parse_args()
    json.dump(build(a), sys.stdout)


if __name__ == "__main__":
    main()
