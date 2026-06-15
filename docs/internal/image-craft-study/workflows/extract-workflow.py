#!/usr/bin/env python3
"""Extract the embedded ComfyUI workflow/prompt JSON from a PNG (tEXt/iTXt/zTXt chunks).

ComfyUI bakes two keys into its PNG output: "prompt" (the API graph it executed) and
"workflow" (the editor graph). A1111-style images carry "parameters" instead. This reader
uses only the Python stdlib (struct + zlib) so it runs anywhere — no PIL.

Usage:
  python3 extract-workflow.py <image.png>                 # print keys + sizes
  python3 extract-workflow.py <image.png> prompt          # dump the 'prompt' JSON
  python3 extract-workflow.py <image.png> workflow out.json   # save the 'workflow' JSON
"""
import struct, zlib, sys, json


def extract_png_text_chunks(path):
    """Return {keyword: value} for every tEXt/iTXt/zTXt chunk in a PNG."""
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
            f.read(4)  # CRC
            if ctype == b"tEXt":
                k, _, v = data.partition(b"\x00")
                meta[k.decode("latin-1")] = v.decode("utf-8", "ignore")
            elif ctype == b"zTXt":
                k, _, rest = data.partition(b"\x00")
                # rest[0] = compression method (0 = zlib)
                try:
                    meta[k.decode("latin-1")] = zlib.decompress(rest[1:]).decode("utf-8", "ignore")
                except Exception:
                    pass
            elif ctype == b"iTXt":
                k, _, rest = data.partition(b"\x00")
                comp_flag = rest[0] if rest else 0
                # rest: comp_flag(1) comp_method(1) lang\0 transkey\0 text
                body = rest[2:]
                _, _, body = body.partition(b"\x00")  # language tag
                _, _, body = body.partition(b"\x00")  # translated keyword
                if comp_flag == 1:
                    try:
                        body = zlib.decompress(body)
                    except Exception:
                        pass
                meta[k.decode("latin-1")] = body.decode("utf-8", "ignore")
            elif ctype == b"IEND":
                break
    return meta


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 1
    meta = extract_png_text_chunks(argv[1])
    if len(argv) == 2:
        for k, v in meta.items():
            tag = "JSON" if v.strip()[:1] in "{[" else "text"
            print(f"{k}\t{tag}\t{len(v)} bytes")
        return 0
    key = argv[2]
    if key not in meta:
        print(f"key '{key}' not present; have: {list(meta)}", file=sys.stderr)
        return 2
    val = meta[key]
    try:
        val = json.dumps(json.loads(val), ensure_ascii=False, indent=2)
    except Exception:
        pass
    if len(argv) >= 4:
        open(argv[3], "w").write(val)
        print(f"wrote {argv[3]} ({len(val)} bytes)")
    else:
        print(val)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
