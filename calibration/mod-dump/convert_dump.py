#!/usr/bin/env python3
"""Convert chunk-dump .json files to a BMP image using Factorio map colors."""

import json, struct, sys, os, glob

MAP_COLORS = {
    "iron-ore":     (106, 134, 148),
    "copper-ore":   (205, 99, 55),
    "coal":         (60, 60, 60),
    "stone":        (176, 156, 109),
    "uranium-ore":  (0, 179, 0),
    "crude-oil":    (199, 51, 196),
}

def parse_chunks(dump_dir):
    """Parse all chunk JSON files, return dict of (x, y) -> entity."""
    entities = {}
    files = glob.glob(os.path.join(dump_dir, "cx*_cy*.json"))
    for fp in files:
        with open(fp) as f:
            obj = json.load(f)
        for e in obj.get("entities", []):
            x, y = e["x"], e["y"]
            key = (x, y)
            if key not in entities or e.get("a", 0) > entities[key].get("a", 0):
                entities[key] = e
    return entities

def write_bmp(entities, output_path, radius=512, scale=2):
    """Write a BMP with ore entities colored by map color."""
    size = radius * 2
    img_size = size * scale
    
    pixels = bytearray(b'\x1e' * (img_size * img_size * 3))
    
    for (x, y), e in entities.items():
        if abs(x) >= radius or abs(y) >= radius:
            continue
        px = x + radius
        py = y + radius
        color = MAP_COLORS.get(e.get("n", ""), (128, 128, 128))
        for dy in range(scale):
            for dx in range(scale):
                sx = px * scale + dx
                sy = py * scale + dy
                idx = (sy * img_size + sx) * 3
                pixels[idx:idx+3] = bytes(color[::-1])  # BGR
    
    row_size = ((img_size * 3 + 3) // 4) * 4
    pixel_data_size = row_size * img_size
    
    with open(output_path, 'wb') as f:
        f.write(b'BM')
        f.write(struct.pack('<I', 14 + 40 + pixel_data_size))
        f.write(struct.pack('<HH', 0, 0))
        f.write(struct.pack('<I', 54))
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
    
    print(f"Wrote {output_path} ({img_size}x{img_size})")

if __name__ == "__main__":
    dump_dir = sys.argv[1] if len(sys.argv) > 1 else "chunk-dump"
    out = sys.argv[2] if len(sys.argv) > 2 else "ground-truth.bmp" 
    radius = int(sys.argv[3]) if len(sys.argv) > 3 else 512
    
    entities = parse_chunks(dump_dir)
    print(f"Loaded {len(entities)} entities from {len(glob.glob(dump_dir + '/cx*_cy*.json'))} chunk files")
    
    # Count by resource
    counts = {}
    for e in entities.values():
        n = e.get("n", "unknown")
        counts[n] = counts.get(n, 0) + 1
    for name, cnt in sorted(counts.items()):
        print(f"  {name}: {cnt}")
    
    write_bmp(entities, out, radius)
