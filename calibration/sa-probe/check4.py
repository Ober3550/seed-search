import json, math, struct, functools, zlib, sys
import numpy as np

M32 = 0xFFFFFFFF
C, C3, W21, Dv, C2 = 0x7ed55d16, 0xc761c23c, 0x165667b1, 0xd3a2646c, 0xfd7046c5
XS, YS, IDS = 0x7ed55d16, 0x7ed56d17, 0x7ed57d18

def mix(v):
    v &= M32
    x = (v + C + ((v << 12) & M32)) & M32
    r1 = (x ^ (x >> 19) ^ C3) & M32
    a = (r1 + W21 + ((r1 << 5) & M32)) & M32
    y = ((a + Dv) ^ ((a << 9) & M32)) & M32
    return (y + C2 + ((y << 3) & M32)) & M32

def ror16(v): return ((v & M32) >> 16 | (v & M32) << 16) & M32

def salt_out(m, salt):
    v = (m * 0x1001 + salt) & M32
    r1 = (v ^ (v >> 19) ^ C3) & M32
    a = (r1 + W21 + ((r1 << 5) & M32)) & M32
    y = ((a + Dv) ^ ((a << 9) & M32)) & M32
    h = (y + C2 + ((y << 3) & M32)) & M32
    return (h ^ (h >> 16) ^ 0xb55a4f09) & M32

def cell_m(cx, cy, seed):
    hx = mix(cx); hy = mix(ror16(cy))
    return seed ^ (hy >> 16) ^ (hx >> 16) ^ hy ^ hx

def f32(v): return np.float32(v)
def tof(v): return struct.unpack('<f', struct.pack('<f', v))[0]

@functools.lru_cache(maxsize=None)
def pt(cx, cy, seed, jit):
    m = cell_m(cx, cy, seed)
    px = f32(tof(np.float64(salt_out(m, XS)) / 2**32))
    py = f32(tof(np.float64(salt_out(m, YS)) / 2**32))
    idf = f32(tof(np.float64(salt_out(m, IDS)) / 2**32))
    j = f32(jit)
    one = f32(1.0); half = f32(0.5)
    # engine NEON: v = px*j + (1-j)*0.5  (f32 chain)
    t1 = f32(px * j)
    t2 = f32(one - j)
    x = f32(f32(f32(cx) + t1) + f32(t2 * half))  # absolute for backward-compat callers? keep rel
    # return RELATIVE positions (as the ctor stores) + id
    relx = f32(t1 + f32(t2 * half))
    rely = f32(f32(py * j) + f32(t2 * half))
    return relx, rely, idf

def exp2f_approx(x32):
    # Math::exp2f (fast approx, f32 arithmetic)
    x = np.float32(x32)
    f = np.float32(1.0) if x < np.float32(0.0) else np.float32(0.0)
    if x <= np.float32(-126.0):
        x = np.float32(-126.0)
    f = f + np.float32(x - np.float32(int(x)))
    v = np.float32(x + np.float32(121.274055))
    v = v + np.float32(np.float32(27.728024) / np.float32(np.float32(4.8425255) - f))
    v = v + np.float32(f * np.float32(-1.4901291))
    v = v * np.float32(8388608.0)
    bits = int(v)  # (long)(...) — truncation? use int(v) cast
    return struct.unpack('<f', struct.pack('<I', bits & 0xFFFFFFFF))[0]

def log2f(x32):
    # Math::log2 fast float approx: s0=bits*2^-23+(-124.22552); +f*(-1.4980303); +(-1.72588/(f+0.35208872))
    b = int(np.float32(x32).view(np.uint32))
    f = f32(struct.unpack('<f', struct.pack('<I', (b & 0x7fffff) | 0x3f000000))[0])
    s0 = f32(f32(b * f32(1.1920929e-07)) + f32(-124.22552))
    s0 = f32(s0 + f32(f * f32(-1.4980303)))
    s0 = f32(s0 + f32(f32(-1.72588) / f32(f + f32(0.35208872))))
    return s0

def fadd(a, b): return f32(a + b)
def fsub(a, b): return f32(a - b)
def fmul(a, b): return f32(a * b)

def dist_eval(metric, xfrac, yfrac, px, py, dxoff, dyoff):
    # engine op order: (px + dxoff) - xfrac  etc
    dx = fsub(fadd(px, f32(dxoff)), xfrac)
    dy = fsub(fadd(py, f32(dyoff)), yfrac)
    if metric == 'euclidean':
        return f32(np.sqrt(fadd(fmul(dx, dx), fmul(dy, dy)), dtype=np.float32))
    if metric == 'manhattan':
        return fadd(np.abs(dx), np.abs(dy))
    if metric == 'chebyshev':
        return np.maximum(np.abs(dx), np.abs(dy))
    if metric == 'minkowski3':
        s = fadd(fmul(fmul(dx, dx), dx), fmul(fmul(dy, dy), dy))
        # careful: engine computes fVar*fVar*fVar: (a*a)*a per op with ABS
        ax = np.abs(dx); ay = np.abs(dy)
        s = fadd(f32(f32(ax * ax) * ax), f32(f32(ay * ay) * ay))
        if s == np.float32(0.0):
            return np.float32(0.0)
        l = log2f(s)
        return exp2f_approx(f32(l * np.float32(0.33333334)))
    raise ValueError(metric)

def evaluate(x, y, seed, jitter, g, metric, win=1):
    sx = int(math.floor(x / g)); sy = int(math.floor(y / g))
    xg = f32(np.float64(x) / g)
    yg = f32(np.float64(y) / g)
    xfrac = fsub(xg, f32(sx))
    yfrac = fsub(yg, f32(sy))
    d0 = None; d1 = None; wid = None; wcell = None
    for dy in range(-win, win + 1):
        for dx in range(-win, win + 1):
            q = pt(sx + dx, sy + dy, seed, jitter)
            # q = (px_rel, py_rel, id)
            d = dist_eval(metric, xfrac, yfrac, q[0], q[1], dx, dy)
            if d0 is None or d < d0:
                d1 = d0; d0 = d; wid = q[2]; wcell = (sx + dx, sy + dy)
            elif d1 is None or d < d1:
                d1 = d
    return d0, d1, wid, wcell

def seed_of(seed1):
    if isinstance(seed1, int):
        return seed1
    return zlib.crc32(seed1.encode())

CONFIGS = {
    'a': (42, 32, 0.0, 'euclidean'),
    'b': (42, 32, 0.5, 'euclidean'),
    'c': (42, 32, 1.0, 'euclidean'),
    'd': (42, 24, 0.25, 'manhattan'),
    'e': (42, 24, 0.5, 'chebyshev'),
    'f': (42, 16, 0.5, 'minkowski3'),
    'g': ('hxprobe', 32, 0.5, 'euclidean'),
    'h': ('aquilo-cracks', 10, 0.5, 'euclidean'),
    'i': ('fulgora_cells', 64, 0.35, 'manhattan'),
}
FILES = ['out/probe-run0.jsonl', 'out/probe-run1.jsonl', 'out/probe-run2.jsonl', 'out/probe-run3.jsonl', 'out/probe-run4.jsonl', 'out/i-spot.jsonl']

def main():
    tag, kind = sys.argv[1], sys.argv[2]
    s1, grid, jit, metric = CONFIGS[tag]
    seed = seed_of(s1) + 341
    expr = f'vp_{tag}_{kind}'
    meas = {}
    for fn in FILES:
        for l in open(fn):
            r = json.loads(l)
            if r['p'] == expr:
                meas[(r['x'], r['y'])] = r['v']
    ok = tot = 0
    bad = []
    for (x, y), v in meas.items():
        d0, d1, wid, wcell = evaluate(x, y, seed, jit, grid, metric)
        pred = {'cid': wid, 'spot': d0, 'facet': d1 - d0, 'pyr': None}[kind]
        if pred is None:
            continue
        tot += 1
        p = float(pred)
        if abs(p - v) <= 1e-7 or (np.issubdtype(type(p), np.floating) and abs(np.float32(p) - np.float32(v)) < 1e-7):
            ok += 1
        elif len(bad) < 4:
            bad.append(((x, y), repr(p), v, wcell))
    print(f"tag={tag} kind={kind} ({metric} g{grid} j{jit}): {ok}/{tot}")
    for b in bad:
        print("   ", b)

if __name__ == '__main__':
    main()
