#!/usr/bin/env python3
"""Ground truth + comparison for the vanilla (base) Nauvis surface generator.

- tile-dump-nauvis-341-r500.jsonl.gz — the LIVE GAME's tiles for seed 341,
  radius 500 (1000x1000 = 785,456 tiles), dumped with the tile-dump mod
  (calibration/saves/mods/tile-dump_1.0.0 control /tile-dump nauvis 500).
  Format per line: {"x":..,"y":..,"t":"<tile-name>","w":0|1}
  This is the oracle the BaseNauvis competition is tuned against.

- Regenerate (about a minute; boots the headless game):
    python3 ../nauvis-tiles-gt.py 341 500 /tmp/gt.jsonl
    gzip -c /tmp/gt.jsonl > tile-dump-nauvis-341-r500.jsonl.gz

- Compare our renderer (see /tmp compare flow in this session): render the
  vanilla Nauvis rect {-500,-500,500,500} (layer 1, palette vanilla) via
  surface.wasm, decode pixels -> palette tile name, and diff per tile here.
  gunzip -c tile-dump-nauvis-341-r500.jsonl.gz > /tmp/gt.jsonl
"""
import gzip, json, sys
from collections import Counter

def load():
    path = sys.argv[1] if len(sys.argv) > 1 else __file__.rsplit("/", 1)[0] + "/tile-dump-nauvis-341-r500.jsonl.gz"
    if path.endswith(".gz"):
        f = gzip.open(path, "rt")
    else:
        f = open(path)
    with f:
        return [json.loads(ln) for ln in f]

if __name__ == "__main__":
    rows = load()
    print("tiles:", len(rows))
    c = Counter(r["t"] for r in rows)
    for k, v in c.most_common():
        print(f"  {k:16s} {v}")
