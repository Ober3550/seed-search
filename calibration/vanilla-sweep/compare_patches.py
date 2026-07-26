#!/usr/bin/env python3
"""Per-patch size comparison between a ground-truth dump and a generator dump.

Clusters each resource's tiles into patches (8-connectivity), matches GT->GEN
patches by centroid distance (<25 tiles), and reports per-patch size ratios.
Score = RMS of log2(size ratio) over matched patches — 0 is perfect.
"""
import json, sys, math
from collections import deque


def load(p):
    d = {}
    for l in open(p):
        o = json.loads(l)
        d.setdefault(o['n'], set()).add((o['x'], o['y']))
    return d


def clusters(pts, min_sz=8):
    pts = set(pts); seen = set(); out = []
    for p in list(pts):
        if p in seen:
            continue
        q = deque([p]); seen.add(p); comp = []
        while q:
            c = q.popleft(); comp.append(c)
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    n = (c[0] + dx, c[1] + dy)
                    if n in pts and n not in seen:
                        seen.add(n); q.append(n)
        if len(comp) >= min_sz:
            cx = sum(a for a, b in comp) / len(comp)
            cy = sum(b for a, b in comp) / len(comp)
            out.append((len(comp), cx, cy))
    return sorted(out, reverse=True)


def main():
    gt = load(sys.argv[1]); gn = load(sys.argv[2])
    verbose = "-v" in sys.argv
    ratios = []
    matched = unmatched_gt = extra_gen = 0
    for r in ['iron-ore', 'copper-ore', 'coal', 'stone', 'uranium-ore']:
        cg = clusters(gt.get(r, ())); cn = clusters(gn.get(r, ()))
        used = set()
        for sz, cx, cy in cg:
            best = None; bd = 1e9
            for i, (sz2, cx2, cy2) in enumerate(cn):
                if i in used:
                    continue
                d = math.hypot(cx - cx2, cy - cy2)
                if d < bd:
                    bd = d; best = (i, sz2)
            if best and bd < 25:
                used.add(best[0])
                ratios.append(math.log2(best[1] / sz))
                matched += 1
                if verbose:
                    print(f"  {r:<12} GT {sz:5d} @({cx:6.0f},{cy:6.0f}) -> GEN {best[1]:5d}  ratio {best[1]/sz:5.2f}")
            else:
                unmatched_gt += 1
                if verbose:
                    print(f"  {r:<12} GT {sz:5d} @({cx:6.0f},{cy:6.0f}) -> UNMATCHED")
        extra_gen += sum(1 for i in range(len(cn)) if i not in used)
    if ratios:
        rms = math.sqrt(sum(x * x for x in ratios) / len(ratios))
        mean = sum(ratios) / len(ratios)
        print(f"matched={matched} unmatched_gt={unmatched_gt} extra_gen={extra_gen}  "
              f"RMS-log2-ratio={rms:.3f}  mean-log2={mean:+.3f}")
    else:
        print("no matched patches")


if __name__ == "__main__":
    main()
