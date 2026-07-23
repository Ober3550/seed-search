#!/usr/bin/env python3
"""Convert chunk-dump .jsonl files to a BMP image using exact Factorio map colors.

Reads a JSONL file where each line is {"x": float, "y": float, "n": "resource-name", "a": amount}.
Writes a BMP with each resource tile colored using the prototype's map_color.
"""

import json, struct, sys, os, math

# ── Map colors from game prototypes (0-255 RGB) ───────────────────────
# Vanilla (from base/prototypes/entity/resources.lua, 0-1 → 0-255)
# SE (from space-exploration/prototypes/phase-1/entity/resources.lua)
# KR2 (from Krastorio2/prototypes/resources/*.lua)
# Core fragments inherit map_color from their base resource.

MAP_COLORS = {
    # ── Vanilla ──
    "iron-ore":     (106, 134, 148),   # {0.415, 0.525, 0.580}
    "copper-ore":   (205,  99,  55),   # {0.803, 0.388, 0.215}
    "coal":         ( 50,  50,  50),   # {0, 0, 0} → bumped for visibility on dark bg
    "stone":        (176, 156, 109),   # {0.690, 0.611, 0.427}
    "uranium-ore":  (  0, 179,   0),   # {0, 0.7, 0}
    "crude-oil":    (199,  51, 196),   # {0.78, 0.2, 0.77}

    # ── Krastorio 2 ──
    "kr-rare-metal-ore":  (153,  77, 255),   # {0.6, 0.3, 1}
    "kr-imersite":        (255, 128, 255),   # {1, 0.5, 1}
    "kr-mineral-water":   ( 89, 128, 191),   # {0.35, 0.5, 0.75}

    # ── Space Exploration ──
    "se-water-ice":       (198, 241, 245),   # {198/255, 241/255, 245/255}
    "se-methane-ice":     (245, 231, 198),   # {245/255, 231/255, 198/255}
    "se-beryllium-ore":   (144, 222, 184),   # {144/255, 222/255, 184/255}
    "se-cryonite":        ( 35, 164, 255),   # {35/255, 164/255, 255/255}
    "se-holmium-ore":     (135,  96, 109),   # {135/255, 96/255, 109/255}
    "se-iridium-ore":     (244, 202,  85),   # {244/255, 202/255, 85/255}
    "se-naquium-ore":     (137, 113, 214),   # {137/255, 113/255, 214/255}
    "se-vulcanite":       (224,  40,  10),   # {224/255, 40/255, 10/255}
    "se-vitamelange":     (173, 206,  54),   # {173/255, 206/255, 54/255}

    # ── SE Core Fragments (inherit from base resource) ──
    # se-core-fragment-se-vitamelange → same as se-vitamelange
}

# Dynamically handle se-core-fragment-* by stripping the prefix
def get_color(name):
    if name in MAP_COLORS:
        return MAP_COLORS[name]
    # Core fragments: "se-core-fragment-se-vitamelange" → "se-vitamelange"
    if name.startswith("se-core-fragment-"):
        base = name[len("se-core-fragment-"):]
        if base in MAP_COLORS:
            return MAP_COLORS[base]
    # Unknown → grey
    return (128, 128, 128)


def parse_jsonl(path):
    """Parse a JSONL file, return dict of (int(x), int(y)) -> resource_name."""
    entities = {}
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line.startswith("{"):
                continue
            e = json.loads(line)
            # Round .5 coordinates to nearest integer tile
            x = int(math.floor(e["x"]))
            y = int(math.floor(e["y"]))
            key = (x, y)
            # Keep highest amount if multiple entries for same tile
            if key not in entities or e.get("a", 0) > entities[key][1]:
                entities[key] = (e["n"], e.get("a", 0))
    return entities


def write_bmp(entities, output_path, radius, scale=1):
    """Write a BMP with ore entities colored by map color."""
    size = radius * 2
    img_size = size * scale

    # Background: dark grey (30, 30, 30)
    pixels = bytearray(b'\x1e' * (img_size * img_size * 3))

    for (x, y), (name, _amount) in entities.items():
        if abs(x) >= radius or abs(y) >= radius:
            continue
        px = x + radius
        py = y + radius
        color = get_color(name)
        for dy in range(scale):
            for dx in range(scale):
                sx = px * scale + dx
                sy = py * scale + dy
                idx = (sy * img_size + sx) * 3
                pixels[idx:idx+3] = bytes(color[::-1])  # BGR

    row_size = ((img_size * 3 + 3) // 4) * 4
    pixel_data_size = row_size * img_size

    with open(output_path, 'wb') as f:
        # BMP file header
        f.write(b'BM')
        f.write(struct.pack('<I', 14 + 40 + pixel_data_size))
        f.write(struct.pack('<HH', 0, 0))
        f.write(struct.pack('<I', 54))
        # DIB header
        f.write(struct.pack('<I', 40))
        f.write(struct.pack('<i', img_size))
        f.write(struct.pack('<i', img_size))
        f.write(struct.pack('<H', 1))
        f.write(struct.pack('<H', 24))
        f.write(struct.pack('<I', 0))
        f.write(struct.pack('<I', pixel_data_size))
        f.write(struct.pack('<i', 2835))
        f.write(struct.pack('<i', 2835))
        f.write(struct.pack('<I', 0))
        f.write(struct.pack('<I', 0))
        pad = row_size - img_size * 3
        for y in range(img_size - 1, -1, -1):
            row = pixels[y * img_size * 3 : (y + 1) * img_size * 3]
            f.write(row)
            f.write(b'\x00' * pad)

    print(f"Wrote {output_path} ({img_size}×{img_size}, scale={scale})")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: convert_jsonl.py <input.jsonl> [output.bmp] [radius] [scale]")
        sys.exit(1)

    input_path = sys.argv[1]
    output_path = sys.argv[2] if len(sys.argv) > 2 else input_path.replace(".jsonl", ".bmp")
    radius = int(sys.argv[3]) if len(sys.argv) > 3 else None
    scale = int(sys.argv[4]) if len(sys.argv) > 4 else 1

    entities = parse_jsonl(input_path)
    print(f"Loaded {len(entities)} entities from {input_path}")

    # Auto-detect radius if not provided
    if radius is None:
        max_abs = max(max(abs(x), abs(y)) for (x, y) in entities)
        radius = math.ceil(max_abs) + 2  # +2 for margin
        print(f"Auto radius: {radius} (max_abs={max_abs})")

    # Count by resource
    counts = {}
    for (_x, _y), (name, _a) in entities.items():
        counts[name] = counts.get(name, 0) + 1
    for name, cnt in sorted(counts.items()):
        color = get_color(name)
        print(f"  {name}: {cnt}  → RGB{color}")

    write_bmp(entities, output_path, radius, scale)
