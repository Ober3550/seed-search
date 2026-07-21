#!/usr/bin/env python3
"""Convert chunk-dump JSONL to a BMP image using Factorio map colors."""

import json, struct, sys, os
from collections import defaultdict

MAP_COLORS = {
    "iron-ore": (106, 134, 148),
    "copper-ore": (205, 99, 55),
    "coal": (60, 60, 60),
    "stone": (176, 156, 109),
    "uranium-ore": (0, 179, 0),
    "crude-oil": (199, 51, 196),
}

def parse_dump(jsonl_path):
    """Parse chunk-dump.jsonl, return dict of (x, y) -> entity with max amount."""
    entities = {}
    with open(jsonl_path) as f:
        for line in f:
            line = line.strip()
            if not line: continue
            obj = json.loads(line)
            for e in obj.get("entities", []):
                x = int(round(e["x"]))
                y = int(round(e["y"]))
                key = (x, y)
                # keep entity with largest amount if multiple at same pos
                if key not in entities or e["a"] > entities[key]["a"]:
                    entities[key] = e
    return entities

def write_bmp(entities, output_path, radius=320, scale=3):
    """Write a BMP with ore entities colored by map color."""
    size = radius * 2
    img_size = size * scale
    
    # Build pixel grid
    pixels = bytearray([30] * (img_size * img_size * 3))  # dark gray bg
    
    for (x, y), e in entities.items():
        if abs(x) >= radius or abs(y) >= radius:
            continue
        px = x + radius
        py = y + radius
        color = MAP_COLORS.get(e["n"], (128, 128, 128))
        for dy in range(scale):
            for dx in range(scale):
                sx = px * scale + dx
                sy = py * scale + dy
                idx = (sy * img_size + sx) * 3
                pixels[idx] = color[2]      # B
                pixels[idx + 1] = color[1]  # G
                pixels[idx + 2] = color[0]  # R
    
    # BMP header
    row_size = ((img_size * 3 + 3) // 4) * 4
    pixel_data_size = row_size * img_size
    file_size = 14 + 40 + pixel_data_size
    
    with open(output_path, 'wb') as f:
        # File header
        f.write(b'BM')
        f.write(struct.pack('<I', file_size))
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
        # Pixel data (bottom-up)
        pad = row_size - img_size * 3
        for y in range(img_size - 1, -1, -1):
            row = pixels[y * img_size * 3 : (y + 1) * img_size * 3]
            f.write(row)
            f.write(b'\x00' * pad)
    
    print(f"Wrote {output_path} ({img_size}x{img_size})")

if __name__ == "__main__":
    jsonl = sys.argv[1] if len(sys.argv) > 1 else "chunk-dump.jsonl"
    out = sys.argv[2] if len(sys.argv) > 2 else "chunk-dump.bmp"
    radius = int(sys.argv[3]) if len(sys.argv) > 3 else 320
    
    entities = parse_dump(jsonl)
    print(f"Loaded {len(entities)} entities from {jsonl}")
    write_bmp(entities, out, radius)
