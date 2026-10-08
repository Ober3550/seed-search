#!/usr/bin/env python3
"""Emit the alien-biomes tile table from surface_generator/src/biome_table.zig
(the CPU Classifier's data) as a canonical JSON, so se_zone.wgsl / JS can build
its rules buffer from the same source the wasm renderer uses.

Output: surface_generator/biome/biomes-table.json
  [{name, group, variant, beach_weight, tv_seed, water_coef, crater, restrict,
    t:[lo,hi]|null, m:[lo,hi]|null, a:[lo,hi]|null, e:[lo,hi]|null, color:[r,g,b]}]
"""
import json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
src = Path(ROOT, "surface_generator", "src", "biome_table.zig").read_text()

# Grab the `pub const biomes = [_]Biome{ ... };` block
m = re.search(r"pub const biomes = \[_\]Biome\{(.*?)\n\};", src, re.S)
assert m, "biomes block not found"
body = m.group(1)

KEY = re.compile(r'\.(\w+)\s*=\s*((?:null)|(?:\.\{[^}]*\})|(?:true|false)|(?:"[^"]*")|(?:-?[\d.]+))')
entries = []
for line in body.splitlines():
    line = line.strip()
    if not line or line.startswith("},") and not line.startswith(".{"):
        continue
    if not line.startswith(".{"):
        continue
    fields = {}
    for k, v in KEY.findall(line):
        fields[k] = v
    def rang(k):
        if k not in fields or fields[k] == "null":
            return None
        nums = [float(x) for x in re.findall(r"-?\d+(?:\.\d+)?", fields[k])]
        return [nums[0], nums[1]] if len(nums) == 2 else nums
    def num(k, default):
        return float(fields[k]) if k in fields and fields[k] not in ("null", "true", "false") else default
    def flag(k):
        return fields.get(k) == "true"
    def color():
        nums = [int(float(x)) for x in re.findall(r"-?\d+(?:\.\d+)?", fields.get("color", "{}"))]
        return nums
    entries.append({
        "name": fields.get("name", "").strip('"'),
        "group": fields.get("group", "").strip('"'),
        "variant": fields.get("variant", "").strip('"'),
        "beach_weight": num("beach_weight", None) if "beach_weight" in fields and fields["beach_weight"] != "null" else None,
        "tv_seed": int(num("tv_seed", 0)),
        "water_coef": num("water_coef", 0.0),
        "crater": flag("crater"),
        "restrict": int(num("restrict", 0)),
        "t": rang("t"), "m": rang("m"), "a": rang("a"), "e": rang("e"),
        "color": color(),
    })

out = Path(ROOT, "surface_generator", "biome", "biomes-table.json")
out.write_text(json.dumps(entries, indent=1) + "\n")
print("wrote", out, f"({len(entries)} biomes)")

# Overview: where each group sits in noise space
from collections import defaultdict, Counter
grp = defaultdict(list)
for e in entries:
    grp[e["group"]].append(e)
for g in sorted(grp):
    es = grp[g]
    def span(k):
        vals = [e[k] for e in es if e[k]]
        if not vals:
            return "–"
        return f"[{min(v[0] for v in vals):g},{max(v[1] for v in vals):g}]"
    seas = Counter(e["tv_seed"] // 100 for e in es)
    craters = sum(1 for e in es if e["crater"])
    wc = sum(1 for e in es if e["water_coef"])
    print(f"{g:22s} n={len(es):3d}  t{span('t'):14s} m{span('m'):12s} a{span('a'):12s} crater={craters} water={wc} tv(seed/100)={dict(seas)}")
