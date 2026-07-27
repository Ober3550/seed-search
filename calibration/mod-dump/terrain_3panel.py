#!/usr/bin/env python3
"""Terrain-only 3-panel: GT | GEN | tile-diff. NO ore — for iterating biome noise.

Compares the alien-biomes tile render (segen --horaerratum-biome) against the
live SE ground truth (tile-bmp-Horaerratum.bmp), tile colour for tile colour.
The GEN patch may be smaller than the GT (render a small radius for a fast
loop); the GT is centre-cropped to the GEN window since world (x,y) -> raw-BMP
pixel (x+r, y+r) for every BMP in this pipeline (both centred on world 0,0).

Panel 3 (diff): matching tiles shown dimmed in their GT colour, mismatches in
magenta, background near-black. Prints overall + in-disk match %, and the tiles
most responsible for the mismatch.

Usage: terrain_3panel.py <gen.bmp> [out.png] [gt.bmp]
"""
import struct, sys, zlib
from collections import Counter

GEN_TILES = sys.argv[1]
OUT = sys.argv[2] if len(sys.argv) > 2 else "terrain-3panel-Horaerratum.png"
GT_TILES = sys.argv[3] if len(sys.argv) > 3 else "tile-bmp-Horaerratum.bmp"
BG = (20, 20, 20)


def read_rgb(p):
    d = open(p, "rb").read()
    off = struct.unpack("<I", d[10:14])[0]
    w = struct.unpack("<i", d[18:22])[0]
    h = struct.unpack("<i", d[22:26])[0]
    avail = len(d) - off
    padded = ((w * 3 + 3) // 4) * 4
    stride = padded if avail >= padded * h else w * 3
    return w, h, [bytearray(d[off + y * stride: off + y * stride + w * 3]) for y in range(h)]


def px(rows, X, Y):
    i = X * 3
    return (rows[Y][i + 2], rows[Y][i + 1], rows[Y][i])  # BGR -> RGB


gw, gh, GN = read_rgb(GEN_TILES)
tw, th, GT = read_rgb(GT_TILES)
rg = gw // 2           # gen radius
rt = tw // 2           # gt radius
off = rt - rg          # gen pixel (X,Y) -> gt pixel (X+off, Y+off)
assert off >= 0, "GEN patch larger than GT; render radius <= GT radius"

gap = 24
W = gw * 3 + gap * 2
out = bytearray(W * gh * 3)


def setp(x0, X, Y, rgb):
    o = (Y * W + x0 + X) * 3
    out[o], out[o + 1], out[o + 2] = rgb


NEAR = 45  # max per-channel RGB distance to call a miss an adjacent-shade near-miss

match = miss = near = 0
miss_pairs = Counter()   # (gt_color, gen_color) -> count, the confusions
samples = {}             # (gt,gen) -> a few (world_x, world_y) example points
for Y in range(gh):
    for X in range(gw):
        tn = px(GN, X, Y)
        tg = px(GT, X + off, Y + off)
        setp(0, X, Y, tg)                 # panel 1: GT
        setp(gw + gap, X, Y, tn)          # panel 2: GEN
        if tn == BG:
            d = (10, 10, 10)              # GEN background = outside its disk; skip
        elif tn == tg:
            d = (tg[0] // 5, tg[1] // 5, tg[2] // 5); match += 1
        else:
            miss += 1
            miss_pairs[(tg, tn)] += 1
            s = samples.setdefault((tg, tn), [])
            if len(s) < 5:
                s.append((X - rg, Y - rg))   # world coords (raw pixel - radius)
            cd = max(abs(tn[0] - tg[0]), abs(tn[1] - tg[1]), abs(tn[2] - tg[2]))
            if cd <= NEAR:
                near += 1
                d = (90, 70, 30)          # near-miss: adjacent shade (orange)
            else:
                d = (200, 40, 200)        # structural miss (magenta)
        setp(2 * gw + 2 * gap, X, Y, d)   # panel 3: diff
    for gx in range(gap):
        for k in (gw, 2 * gw + gap):
            o = (Y * W + k + gx) * 3
            out[o], out[o + 1], out[o + 2] = (40, 40, 40)


def chunk(t, dat):
    c = t + dat
    return struct.pack(">I", len(dat)) + c + struct.pack(">I", zlib.crc32(c) & 0xffffffff)


raw = b"".join(b"\x00" + bytes(out[y * W * 3:(y + 1) * W * 3]) for y in range(gh))
open(OUT, "wb").write(
    b"\x89PNG\r\n\x1a\n"
    + chunk(b"IHDR", struct.pack(">IIBBBBB", W, gh, 8, 2, 0, 0, 0))
    + chunk(b"IDAT", zlib.compress(raw, 6))
    + chunk(b"IEND", b""))

tot = match + miss
print(f"tiles in-disk: exact {match}/{tot} = {match / tot * 100:.2f}%   (radius {rg})")
if miss:
    far = miss - near
    print(f"misses: {miss}  ·  near (≤{NEAR}/chan, adjacent shade) {near} = {near / miss * 100:.1f}%"
          f"  ·  structural {far} = {far / miss * 100:.1f}%")
    print(f"exact+near (base biome right) = {(match + near) / tot * 100:.2f}%")
    print("top tile confusions (GT rgb -> GEN rgb : count : sample world pts):")
    for (g, n), c in miss_pairs.most_common(8):
        pts = " ".join(f"{x},{y}" for x, y in samples.get((g, n), [])[:3])
        print(f"  {g} -> {n} : {c}  ({c / miss * 100:.1f}%)  @ {pts}")
print(f"wrote {OUT}")
