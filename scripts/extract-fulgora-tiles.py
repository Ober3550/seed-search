#!/usr/bin/env python3
"""Extract Fulgora tile prototypes (space-age/prototypes/tile/tiles-fulgora.lua).

The tile file's data:extend entries carry runtime fields (sounds, trigger
effects, spritesheet variants) that don't run under stock Lua without the
game. Everything the generator needs is literal near the top of each entry:
  name / order / subgroup, layer, map_color, autoplace.probability_expression.
We scan per expected tile name (from biome/planet-tiles.json) and pull those
fields from the entry body. map_color can be an expression (e.g. oil ocean
uses {49*1.15, ...}) — evaluated here, with the palette dump as fallback.

Usage: python3 scripts/extract-fulgora-tiles.py [TILES_LUA] [OUT_JSON]
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = sys.argv[1] if len(sys.argv) > 1 else "/Applications/factorio.app/Contents/data/space-age/prototypes/tile/tiles-fulgora.lua"
OUT = pathlib.Path(sys.argv[2] if len(sys.argv) > 2 else ROOT / "surface_generator/sa-data/surfaces/fulgora-tiles.json")

src = open(SRC, encoding="utf-8").read()
pt = json.load(open(ROOT / "surface_generator" / "biome" / "planet-tiles.json", encoding="utf-8"))
expected = [t["name"] for t in pt.get("fulgora", [])]

layer_re = re.compile(r"\blayer\s*=\s*(\d+)")
color_re = re.compile(r"map_color\s*=\s*\{([^}]*)\}")
prob_re = re.compile(r'probability_expression\s*=\s*"((?:[^"\\]|\\.)*)"')
order_re = re.compile(r'\border\s*=\s*"([^"]*)"')
sub_re = re.compile(r'\bsubgroup\s*=\s*"([^"]*)"')

entries = []
for name in expected:
    i = src.find('name = "' + name + '",')
    if i < 0:
        continue
    body = src[i:i + 4000]
    if 'type = "tile"' not in body:
        continue
    pm = prob_re.search(body)
    if not pm:
        continue  # not an autoplaced map tile
    lm = layer_re.search(body)
    rgb = None
    cm = color_re.search(body)
    if cm:
        try:
            rgb = [int(round(float(eval(t)))) for t in [x.strip() for x in cm.group(1).split(",")][:3]]
        except Exception:
            pass
    if rgb is None:
        pal = next((t["color"] for t in pt["fulgora"] if t["name"] == name), None)
        if pal:
            rgb = list(pal)
    om = order_re.search(body)
    entries.append({
        "name": name,
        "order": om.group(1) if om else None,
        "subgroup": sub_re.search(body).group(1) if sub_re.search(body) else None,
        "layer": int(lm.group(1)) if lm else None,
        "color": rgb,
        "probability": pm.group(1).strip(),
    })

entries.sort(key=lambda e: (e["layer"] or 0, e["name"]))
OUT.write_text(json.dumps({"planet": "fulgora", "source": SRC, "tiles": entries}, indent=1), encoding="utf-8")
print(f"{len(entries)}/{len(expected)} fulgora tiles -> {OUT}")
for e in entries:
    print(f"  L{e['layer']} {e['name']:20s} {e['color']}  {e['probability'][:78]}")
