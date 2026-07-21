#!/usr/bin/env python3
"""Extract ore dump from Factorio log and write BMP."""
import json, struct, sys, os, re

def extract(log_path):
    with open(log_path) as f:
        lines = f.readlines()
    
    # Collect all JSON fragments after :1: 
    # Find the LAST dump in the log (multiple runs accumulate)
    # Collect fragments from the last occurrence of :1: {"dump"
    last_start = -1
    for i, line in enumerate(lines):
        if ':1: {"dump"' in line:
            last_start = i
    
    if last_start < 0:
        raise ValueError("No dump found")
    
    fragments = []
    for line in lines[last_start:]:
        idx = line.find(':1: ')
        if idx < 0: continue
        fragments.append(line[idx+4:].strip())
        if fragments[-1] == ']}':
            break
    
    # The first fragment is the header, then entity objects separated by commas, then ]}
    # Join them into a complete JSON document
    combined = ''.join(fragments)
    
    try:
        data = json.loads(combined)
    except json.JSONDecodeError as e:
        # Try without the trailing comma on entity lines
        print(f"JSON error: {e}")
        print(f"First 200 chars: {combined[:200]}")
        print(f"Last 200 chars: {combined[-200:]}")
        raise
    
    return data["dump"]["entities"], data["dump"]["radius"], data["dump"]["seed"]

if __name__ == "__main__":
    log = os.path.expanduser(sys.argv[1] if len(sys.argv) > 1 else "~/Library/Application Support/factorio/factorio-current.log")
    out = sys.argv[2] if len(sys.argv) > 2 else "ground-truth.bmp"
    
    entities, radius, seed = extract(log)
    print(f"Seed: {seed}, Radius: {radius}, Count: {len(entities)}")
    
    counts = {}
    for e in entities:
        n = e["n"]
        counts[n] = counts.get(n, 0) + 1
    for n, c in sorted(counts.items()):
        print(f"  {n}: {c}")
    
    MAP_COLORS = {
        "iron-ore":(106,134,148),"copper-ore":(205,99,55),"coal":(60,60,60),
        "stone":(176,156,109),"uranium-ore":(0,179,0),"crude-oil":(199,51,196)
    }
    entity_map = {(e["x"], e["y"]): e for e in entities}
    scale = 1
    size = radius * 2 * scale
    pixels = bytearray(b'\x1e' * (size * size * 3))
    
    for (x, y), e in entity_map.items():
        if abs(x) >= radius or abs(y) >= radius: continue
        c = MAP_COLORS.get(e["n"], (128, 128, 128))
        px, py = x + radius, y + radius
        for dy in range(scale):
            for dx in range(scale):
                sx, sy = px * scale + dx, py * scale + dy
                i = (sy * size + sx) * 3
                pixels[i:i+3] = bytes(c[::-1])
    
    rs = ((size * 3 + 3) // 4) * 4
    ps = rs * size
    with open(out, 'wb') as f:
        f.write(b'BM' + struct.pack('<IHHI', 14+40+ps, 0, 0, 54))
        f.write(struct.pack('<IiiHHIIiiII', 40, size, size, 1, 24, 0, ps, 2835, 2835, 0, 0))
        pad = rs - size * 3
        for y in range(size - 1, -1, -1):
            f.write(pixels[y*size*3:(y+1)*size*3] + b'\x00' * pad)
    
    print(f"Wrote {out} ({size}x{size})")
