#!/usr/bin/env python3
"""Extract the authoritative tile palettes from a tile-palette-dump run.

Reads the factorio log produced by calibration/tile-palette-dump and writes:
  surface_generator/biome/tiles-dump.json   every tile: name/color/layer/subgroup
  surface_generator/biome/planet-tiles.json per planet (from sa-data/planets.json
                                            autoplace_settings.tile.settings)
                                            -> [{name, color:[r,g,b], layer}]

Usage: extract-tile-palettes.py <factorio-current.log>
"""
import json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
log = Path(sys.argv[1]).read_text()
rows = {}
for m in re.finditer(r": TPD\t([^\t]+)\t(-?\d+)\t(-?\d+)\t(-?\d+)\t(\d+)\t(.*)", log):
    name, r, g, b, layer, sub = m.groups()
    rows[name] = {"name": name, "color": [int(r), int(g), int(b)], "layer": int(layer), "subgroup": sub}

done = re.search(r"TPD\t__DONE__\t(\d+)", log)
print(f"parsed {len(rows)} tiles (game reported {done.group(1) if done else '?'})")

out = Path(ROOT, "surface_generator", "biome", "tiles-dump.json")
out.write_text(json.dumps(rows, indent=1) + "\n")
print("wrote", out)

# per-planet palettes from sa-data/planets.json autoplace_settings.tile.settings
planets = json.loads(Path(ROOT, "surface_generator", "sa-data", "planets.json").read_text())
planets_tiles = {}
for pname in ["nauvis", "vulcanus", "fulgora", "gleba", "aquilo"]:
    names = planets.get(pname, {}).get("autoplace_settings", {}).get("tile", {}).get("settings", {})
    entries, missing = [], []
    for n in names:
        if n in rows:
            entries.append(rows[n])
        else:
            missing.append(n)
    planets_tiles[pname] = entries
    print(f"{pname}: {len(entries)} tiles mapped, missing {missing}")

Path(ROOT, "surface_generator", "biome", "planet-tiles.json").write_text(
    json.dumps(planets_tiles, indent=1) + "\n")
print("wrote planet-tiles.json")
