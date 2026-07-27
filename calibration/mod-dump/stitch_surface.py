#!/usr/bin/env python3
"""Stitch tiled surface cells into one north-up PNG.

segen --render-surface --surface-grid N --surface-cell i writes each cell as
<zone_dir>/surface_<N>_<i>.bmp covering tiles [x0,x1)×[y0,y1) of the 2r×2r
bounds, rendered top-down (row 0 = y0). This composes every present cell into a
2r×2r canvas and flips vertically so the result is north-up (matching ore.png).

Usage: stitch_surface.py <zone_dir> <grid_n> <radius> [out.png]
Cells that are missing (skipped as outside the disk) stay background.
"""
import sys, os, struct, zlib, glob, re

zone_dir = sys.argv[1]
grid = int(sys.argv[2])
radius = int(sys.argv[3])
# layer prefix: surface (combined), terrain, or oremap. Defaults to surface.
prefix = sys.argv[4] if len(sys.argv) > 4 else "surface"
out = sys.argv[5] if len(sys.argv) > 5 else os.path.join(zone_dir, prefix + ".png")

full = radius * 2
cellW = (full + grid - 1) // grid
# ore layer sits on black so it composites over the dimmed terrain.
BG = (0, 0, 0) if prefix == "oremap" else (20, 20, 20)


def read_bmp(p):
    d = open(p, "rb").read()
    off = struct.unpack("<I", d[10:14])[0]
    w = struct.unpack("<i", d[18:22])[0]
    h = struct.unpack("<i", d[22:26])[0]
    avail = len(d) - off
    padded = ((w * 3 + 3) // 4) * 4
    stride = padded if avail >= padded * h else w * 3
    # BMP with positive height is bottom-up; reverse to top-down (row 0 = y0,
    # matching the generator's input pixel order).
    rows = [d[off + y * stride: off + y * stride + w * 3] for y in range(h - 1, -1, -1)]
    return w, h, rows


# canvas[y][x] as (r,g,b), y is world-down (row 0 = y=-radius)
canvas = bytearray(full * full * 3)
for i in range(full * full):
    canvas[i * 3], canvas[i * 3 + 1], canvas[i * 3 + 2] = BG

cells = glob.glob(os.path.join(zone_dir, f"{prefix}_{grid}_*.bmp"))
# also accept a single whole-surface bmp (grid==1)
if grid == 1 and os.path.exists(os.path.join(zone_dir, prefix + ".bmp")):
    cells = [os.path.join(zone_dir, prefix + ".bmp")]

placed = 0
for cf in cells:
    m = re.search(rf"{prefix}_{grid}_(\d+)\.bmp$", os.path.basename(cf))
    cell = int(m.group(1)) if m else 0
    gx, gy = cell % grid, cell // grid
    x0, y0 = gx * cellW, gy * cellW  # offset within the 2r canvas (world+radius)
    w, h, rows = read_bmp(cf)
    for py in range(h):
        cy = y0 + py
        if cy >= full:
            break
        row = rows[py]
        base = (cy * full + x0) * 3
        # row is BGR; canvas we keep as RGB → swap
        for px in range(w):
            if x0 + px >= full:
                break
            b, g, r = row[px * 3], row[px * 3 + 1], row[px * 3 + 2]
            o = base + px * 3
            canvas[o], canvas[o + 1], canvas[o + 2] = r, g, b
    placed += 1

# flip vertically → north-up
def chunk(t, dat):
    c = t + dat
    return struct.pack(">I", len(dat)) + c + struct.pack(">I", zlib.crc32(c) & 0xffffffff)

# The ore layer is emitted RGBA with black transparent so terrain shows through.
alpha = prefix == "oremap"
raw = bytearray()
for y in range(full - 1, -1, -1):
    raw.append(0)
    if alpha:
        base = y * full * 3
        for x in range(full):
            o = base + x * 3
            r, g, b = canvas[o], canvas[o + 1], canvas[o + 2]
            raw.extend((r, g, b, 0 if (r == 0 and g == 0 and b == 0) else 255))
    else:
        raw += canvas[y * full * 3:(y + 1) * full * 3]
color_type = 6 if alpha else 2  # 6 = RGBA, 2 = RGB
png = (b"\x89PNG\r\n\x1a\n"
       + chunk(b"IHDR", struct.pack(">IIBBBBB", full, full, 8, color_type, 0, 0, 0))
       + chunk(b"IDAT", zlib.compress(bytes(raw), 6))
       + chunk(b"IEND", b""))
open(out, "wb").write(png)
print(f"stitched {placed} cell(s) → {out} ({full}x{full}{' RGBA' if alpha else ''})")
