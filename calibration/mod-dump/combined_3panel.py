#!/usr/bin/env python3
"""Combined water+terrain+ore 3-panel: GT | GEN | diff.

Panels 1/2: full biome+water tile render with ore tiles overlaid in map colors.
Panel 3: tile-layer agreement as a dim background (dim GT color where the tile
color matches, dark magenta where it differs, near-black outside the disk) with
the ore diff on top: green = same resource both, orange = ore in both but
different resource, red = generated-only, blue = ground-truth-only.

World (x,y) -> raw-BMP pixel (x+r, y+r) for every BMP in this pipeline
(verified 50/50 against the GT ore render).
"""
import json, struct, sys, zlib

GT_TILES = 'tile-bmp-Horaerratum.bmp'
GEN_TILES = sys.argv[1] if len(sys.argv) > 1 else '/tmp/hora-biome-gen.bmp'
GT_ORE = 'Horaerratum.jsonl'
GEN_ORE = sys.argv[2] if len(sys.argv) > 2 else '/tmp/hora-final.jsonl'
OUT = sys.argv[3] if len(sys.argv) > 3 else 'combined-3panel-Horaerratum.png'

COLORS = {
    'iron-ore': (105, 133, 147), 'copper-ore': (204, 98, 54), 'coal': (0, 0, 0),
    'stone': (175, 155, 108), 'uranium-ore': (0, 178, 0), 'crude-oil': (255, 153, 0),
    'kr-rare-metal-ore': (153, 76, 255), 'kr-imersite': (255, 127, 255),
    'kr-mineral-water': (89, 127, 191), 'se-cryonite': (35, 164, 255),
    'se-vulcanite': (224, 40, 10), 'se-vitamelange': (173, 206, 54),
}
BG = (20, 20, 20)


def read_rgb(p):
    d = open(p, 'rb').read()
    off = struct.unpack('<I', d[10:14])[0]
    w = struct.unpack('<i', d[18:22])[0]
    h = struct.unpack('<i', d[22:26])[0]
    avail = len(d) - off
    padded = ((w * 3 + 3) // 4) * 4
    stride = padded if avail >= padded * h else w * 3
    return w, h, [bytearray(d[off + y * stride: off + y * stride + w * 3]) for y in range(h)]


def load_ore(p):
    d = {}
    for l in open(p):
        o = json.loads(l)
        n = o['n']
        if n.startswith('se-core-fragment-'):
            n = n[len('se-core-fragment-'):]
        if n not in COLORS:
            COLORS[n] = (128, 128, 128)
        d[(int(o['x']), int(o['y']))] = n
    return d


w, h, GT = read_rgb(GT_TILES)
w2, h2, GN = read_rgb(GEN_TILES)
assert (w, h) == (w2, h2), (w, h, w2, h2)
r = w // 2
gt_ore = load_ore(GT_ORE)
gn_ore = load_ore(GEN_ORE)


def px(rows, X, Y):
    i = X * 3
    return (rows[Y][i + 2], rows[Y][i + 1], rows[Y][i])  # BGR -> RGB


gap = 24
W = w * 3 + gap * 2
out = bytearray(W * h * 3)


def setp(x0, X, Y, rgb):
    o = (Y * W + x0 + X) * 3
    out[o], out[o + 1], out[o + 2] = rgb


stats = {'same': 0, 'diffres': 0, 'gen': 0, 'gt': 0, 'tile_match': 0, 'tile_diff': 0}
for Y in range(h):
    for X in range(w):
        tg = px(GT, X, Y)
        tn = px(GN, X, Y)
        wx, wy = X - r, Y - r
        og = gt_ore.get((wx, wy))
        on = gn_ore.get((wx, wy))
        # panel 1: GT tiles + GT ore
        setp(0, X, Y, COLORS[og] if og else tg)
        # panel 2: GEN tiles + GEN ore
        setp(w + gap, X, Y, COLORS[on] if on else tn)
        # panel 3: diff
        if tg == BG and tn == BG:
            d = (10, 10, 10)
        elif og and on and og == on:
            d = (60, 190, 60); stats['same'] += 1
        elif og and on:
            d = (235, 160, 40); stats['diffres'] += 1
        elif on:
            d = (225, 50, 50); stats['gen'] += 1
        elif og:
            d = (60, 120, 235); stats['gt'] += 1
        elif tg == tn:
            d = (tg[0] // 5, tg[1] // 5, tg[2] // 5); stats['tile_match'] += 1
        else:
            d = (55, 25, 55); stats['tile_diff'] += 1
        setp(2 * w + 2 * gap, X, Y, d)
    for gx in range(gap):
        for k in (w, 2 * w + gap):
            o = (Y * W + k + gx) * 3
            out[o], out[o + 1], out[o + 2] = (40, 40, 40)


def chunk(t, dat):
    c = t + dat
    return struct.pack('>I', len(dat)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)


raw = b''.join(b'\x00' + bytes(out[y * W * 3:(y + 1) * W * 3]) for y in range(h))
open(OUT, 'wb').write(
    b'\x89PNG\r\n\x1a\n'
    + chunk(b'IHDR', struct.pack('>IIBBBBB', W, h, 8, 2, 0, 0, 0))
    + chunk(b'IDAT', zlib.compress(raw, 6))
    + chunk(b'IEND', b''))
tm = stats['tile_match'] + stats['tile_diff']
print(f"ore: same {stats['same']}  diff-resource {stats['diffres']}  gen-only {stats['gen']}  gt-only {stats['gt']}")
print(f"tiles (non-ore): match {stats['tile_match']}/{tm} = {stats['tile_match']/tm*100:.1f}%")
print(f"wrote {OUT}")
