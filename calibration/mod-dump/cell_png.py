#!/usr/bin/env python3
"""Convert ONE tiled surface cell BMP → a final-oriented PNG for the live grid.

segen writes each cell as surface_<N>_<i>.bmp covering canvas offset
(gx*cellW, gy*cellW), rendered top-down (BMP row order is bottom-up on disk).
stitch_surface.py composes all cells into a 2r×2r canvas (north-down) and flips
it vertically for the final north-up surface.png.

For the browser "watch" grid we position each cell by percentage and do NOT flip
in CSS, so each per-cell PNG must already carry that final vertical flip. This
emits exactly that: read_bmp (→ top-down, row0 = y0), flip vertically, BGR→RGB.
Placing the result at top% = (full - y0 - ch)/full reproduces surface.png.

Usage: cell_png.py <cell.bmp> [out.png]   (default out = <cell>.png)
"""
import sys, os, struct, zlib

src = sys.argv[1]
out = sys.argv[2] if len(sys.argv) > 2 else os.path.splitext(src)[0] + ".png"


def read_bmp(p):
    d = open(p, "rb").read()
    off = struct.unpack("<I", d[10:14])[0]
    w = struct.unpack("<i", d[18:22])[0]
    h = struct.unpack("<i", d[22:26])[0]
    avail = len(d) - off
    padded = ((w * 3 + 3) // 4) * 4
    stride = padded if avail >= padded * h else w * 3
    # BMP positive height is bottom-up; reverse → top-down (row0 = y0 = north).
    rows = [d[off + y * stride: off + y * stride + w * 3] for y in range(h - 1, -1, -1)]
    return w, h, rows


def chunk(t, dat):
    c = t + dat
    return struct.pack(">I", len(dat)) + c + struct.pack(">I", zlib.crc32(c) & 0xffffffff)


# The ore layer (oremap_*) is drawn on black; emit it as RGBA with the black
# pixels transparent so the terrain shows through underneath.
alpha = "oremap" in os.path.basename(src)

w, h, rows = read_bmp(src)
raw = bytearray()
# flip vertically (final orientation) + BGR→RGB (+ alpha for the ore layer)
for y in range(h - 1, -1, -1):
    raw.append(0)
    row = rows[y]
    for x in range(w):
        r, g, b = row[x * 3 + 2], row[x * 3 + 1], row[x * 3]
        if alpha:
            raw.extend((r, g, b, 0 if (r == 0 and g == 0 and b == 0) else 255))
        else:
            raw.extend((r, g, b))

color_type = 6 if alpha else 2  # 6 = RGBA, 2 = RGB
png = (b"\x89PNG\r\n\x1a\n"
       + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, color_type, 0, 0, 0))
       + chunk(b"IDAT", zlib.compress(bytes(raw), 6))
       + chunk(b"IEND", b""))
open(out, "wb").write(png)
print(f"cell → {out} ({w}x{h}{' RGBA' if alpha else ''})")
