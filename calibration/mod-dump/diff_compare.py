#!/usr/bin/env python3
"""Side-by-side + diff visualization of generator output vs in-game ground truth.

Reads two JSONL files ({"x","y","n","a"} per line), renders three panels at the
same scale into one PNG:
  1. Ground truth   (all resources, map palette)
  2. Generated      (map palette)
  3. Diff (over resources present in BOTH files):
       green  = tile matches (same resource in both)
       red    = ground-truth only (generator missed it)
       blue   = generator only (generator placed extra)
       grey   = tile present in both but DIFFERENT resource

Usage: diff_compare.py <ground_truth.jsonl> <generated.jsonl> <out.png> [radius]
"""

import json, math, sys, os, zlib, struct

# Ground-truth palette (from convert_jsonl.py).
MAP_COLORS = {
    "iron-ore": (106, 134, 148), "copper-ore": (205, 99, 55), "coal": (50, 50, 50),
    "stone": (176, 156, 109), "uranium-ore": (0, 179, 0), "crude-oil": (199, 51, 196),
    "kr-rare-metal-ore": (153, 77, 255), "kr-imersite": (255, 128, 255),
    "kr-mineral-water": (89, 128, 191), "se-water-ice": (198, 241, 245),
    "se-methane-ice": (245, 231, 198), "se-beryllium-ore": (144, 222, 184),
    "se-cryonite": (35, 164, 255), "se-holmium-ore": (135, 96, 109),
    "se-iridium-ore": (244, 202, 85), "se-naquium-ore": (137, 113, 214),
    "se-vulcanite": (224, 40, 10), "se-vitamelange": (173, 206, 54),
}
BG = (30, 30, 30)


def color(name):
    if name in MAP_COLORS:
        return MAP_COLORS[name]
    if name.startswith("se-core-fragment-"):
        return MAP_COLORS.get(name[len("se-core-fragment-"):], (128, 128, 128))
    return (128, 128, 128)


def load(path):
    """(int x, int y) -> resource name, keeping highest amount per tile."""
    best, ents = {}, {}
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line.startswith("{"):
                continue
            e = json.loads(line)
            k = (int(math.floor(e["x"])), int(math.floor(e["y"])))
            a = e.get("a", 0)
            if k not in best or a > best[k]:
                best[k] = a
                ents[k] = e["n"]
    return ents


def write_png(pixels, w, h, path):
    raw = bytearray()
    for y in range(h):
        raw.append(0)
        raw.extend(pixels[y * w * 3:(y + 1) * w * 3])

    def chunk(t, d):
        c = t + d
        return struct.pack(">I", len(d)) + c + struct.pack(">I", zlib.crc32(c) & 0xffffffff)

    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        f.write(chunk(b"IEND", b""))


def main():
    gt_path, gen_path, out = sys.argv[1], sys.argv[2], sys.argv[3]
    gt, gen = load(gt_path), load(gen_path)
    radius = int(sys.argv[4]) if len(sys.argv) > 4 else \
        max(max(abs(x), abs(y)) for x, y in list(gt) + list(gen)) + 2
    size = radius * 2

    common = set(gt.values()) & set(gen.values())  # resources in both files
    gap = 8
    W = size * 3 + gap * 2
    px = bytearray(bytes(BG) * (W * size))

    def put(panel, x, y, rgb):
        sx = panel * (size + gap) + x + radius
        sy = y + radius
        if 0 <= sx < W and 0 <= sy < size:
            i = (sy * W + sx) * 3
            px[i:i + 3] = bytes(rgb)

    # Panels 1 & 2: ground truth and generated (map palette).
    for (x, y), n in gt.items():
        put(0, x, y, color(n))
    for (x, y), n in gen.items():
        put(1, x, y, color(n))

    # Panel 3: diff over resources present in both files.
    match = miss = extra = wrong = 0
    keys = set(k for k, n in gt.items() if n in common) | \
        set(k for k, n in gen.items() if n in common)
    for k in keys:
        a, b = gt.get(k), gen.get(k)
        ga, gb = a in common, b in common
        if ga and gb:
            if a == b:
                put(2, k[0], k[1], (60, 220, 60)); match += 1
            else:
                put(2, k[0], k[1], (110, 110, 110)); wrong += 1
        elif ga:
            put(2, k[0], k[1], (220, 50, 50)); miss += 1
        elif gb:
            put(2, k[0], k[1], (60, 120, 235)); extra += 1

    write_png(px, W, size, out)
    tot = match + miss + wrong
    print(f"radius={radius}  panels: GT | Generated | Diff   -> {out}")
    print(f"common resources: {sorted(common)}")
    print(f"DIFF over common resources:")
    print(f"  green  match (same resource, same tile): {match}")
    print(f"  red    ground-truth only (missed):       {miss}")
    print(f"  blue   generator only (extra):           {extra}")
    print(f"  grey   present in both, wrong resource:  {wrong}")
    if tot:
        print(f"  match / (match+miss+wrong) = {100*match/tot:.1f}% of GT common tiles")


if __name__ == "__main__":
    main()
