#!/usr/bin/env python3
"""Build the data file that drives the generic planet surface generator.

Factorio's map generation is data: every planet surface is a
map_gen_settings table naming noise expressions, and every tile / entity
carries an autoplace expression. This script asks the game itself for that
data (`factorio --dump-data`, which runs the real Lua data stage for whatever
mods are enabled) and keeps just the map-generation slice:

  expressions   every named noise-expression, plus one synthesized entry per
                autoplaced prototype using the engine's own property names:
                  tile:<name>:probability
                  entity:<name>:probability / entity:<name>:richness
                  decorative:<name>:probability
  functions     every noise-function
  tiles         layer, map colour and collision layers of each autoplaced tile
  entities      type, autoplace order, map colour, footprint, collision
                layers and tile restriction of each autoplaced entity
  planets       per planet: property_expression_names, autoplace controls,
                cliff settings, its resources, and the tile/entity/decorative lists of its
                autoplace_settings (tiles in prototype order: ties go to the first)

Nothing planet-specific lives in the generator: sa_program.zig compiles
whichever planet it is asked for straight from this file.

Usage: sa-build-data.py [--dump existing-data-raw-dump.json] [--mods a,b,c]
                        [--se-zone-lua scripts/zone.lua] [--out file]
Writes surface_generator/src/sa_noise_data.json (embedded by sa_data.zig).

Space Exploration: its planets and moons are not planet prototypes - the mod
builds each surface's map_gen_settings at runtime (Zone.create_surface). With
--se-zone-lua (the mod's scripts/zone.lua) the lists of what may spawn on a
solid zone are read from Zone.set_autoplace_settings_for_solid and written as
one more planet, "se-zone": Nauvis's wiring with those lists. What varies per
zone (controls, cliff settings, which resources and whether enemies) is
applied by the generator (se_zone.zig). The SE data file is
surface_generator/src/se_noise_data.json:

  sa-build-data.py --dump <SE data-raw-dump.json> --mods <SE mod list> \
      --se-zone-lua <space-exploration>/scripts/zone.lua --no-decoratives \
      --out surface_generator/src/se_noise_data.json
"""
import argparse, json, math, os, re, shutil, subprocess, sys, tempfile, zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "surface_generator" / "src" / "sa_noise_data.json"
FACTORIO = os.environ.get("FACTORIO_BIN", "/Applications/factorio.app/Contents/MacOS/factorio")
DATA = os.environ.get("FACTORIO_DATA", "/Applications/factorio.app/Contents/data")
DEFAULT_MODS = ["base", "quality", "elevated-rails", "space-age"]
AUTOPLACE_KINDS = (("tile", "tile"), ("entity", "entity"), ("decorative", "decorative"))
# the engine's CliffOrientation enum (checked against the game's cliffs)
CLIFF_ORIENTATIONS = [
    "west-to-east", "north-to-south", "east-to-west", "south-to-north",
    "west-to-north", "north-to-east", "east-to-south", "south-to-west",
    "west-to-south", "north-to-west", "east-to-north", "south-to-east",
    "west-to-none", "none-to-east", "east-to-none", "none-to-west",
    "north-to-none", "none-to-south", "south-to-none", "none-to-north",
]


def dump_data(mods):
    tmp = Path(tempfile.mkdtemp(prefix="sa-dump-"))
    try:
        (tmp / "mods").mkdir(); (tmp / "write").mkdir()
        (tmp / "mods" / "mod-list.json").write_text(
            json.dumps({"mods": [{"name": m, "enabled": True} for m in mods]}))
        (tmp / "config.ini").write_text(f"[path]\nread-data={DATA}\nwrite-data={tmp / 'write'}\n")
        r = subprocess.run([FACTORIO, "--config", str(tmp / "config.ini"),
                            "--mod-directory", str(tmp / "mods"), "--dump-data"],
                           capture_output=True, text=True, timeout=900)
        p = tmp / "write" / "script-output" / "data-raw-dump.json"
        if not p.exists():
            sys.exit("factorio --dump-data failed:\n" + r.stdout[-3000:])
        return json.loads(p.read_text())
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def game_version():
    try:
        out = subprocess.run([FACTORIO, "--version"], capture_output=True, text=True, timeout=60).stdout
        return out.split()[1]
    except Exception:
        return "unknown"


def rgb(c):
    """Factorio Color -> [r,g,b] 0..255 (components >1 anywhere = 0..255 scale)."""
    if c is None:
        return [0, 0, 0]
    v = [c.get("r", 0), c.get("g", 0), c.get("b", 0)] if isinstance(c, dict) else list(c)[:3]
    scale = 1 if any(x > 1 for x in v) else 255
    return [max(0, min(255, int(round(x * scale)))) for x in v]


def noise_def(src, expr_key="expression"):
    out = {"expression": src[expr_key]}
    for k in ("parameters", "local_expressions", "local_functions"):
        if src.get(k):
            out[k] = src[k]
    return out


def se_zone_lists(lua_path):
    """What Zone.set_autoplace_settings_for_solid lets spawn on a planet or
    moon: {"tile": [...], "entity": [...], "decorative": [...]}. Everything
    the function can add is included (every resource, the enemies, the water
    tiles); the per-zone conditions are the generator's job."""
    src = Path(lua_path).read_text()
    a = src.index("function Zone.set_autoplace_settings_for_solid")
    body = src[a:src.index("function Zone.create_surface", a)]
    body = re.sub(r"--\[\[.*?\]\]", "", body, flags=re.S)
    body = re.sub(r"--[^\n]*", "", body)
    out = {"decorative": [], "entity": [], "tile": []}
    marks = sorted((body.index(f'["{k}"] = {{'), k) for k in out)
    end = body.index("local resource_names")
    for i, (pos, kind) in enumerate(marks):
        stop = marks[i + 1][0] if i + 1 < len(marks) else end
        out[kind] += re.findall(r'\["([^"]+)"\]\s*=\s*\{\}', body[pos:stop])
    for kind, name in re.findall(r'autoplace_settings\.(\w+)\.settings\["([^"]+)"\]', body[end:]):
        out[kind].append(name)
    m = re.search(r"local resource_names = \{(.*?)\}", body, flags=re.S)
    out["entity"] += re.findall(r'"([^"]+)"', m.group(1))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dump"); ap.add_argument("--mods", default=",".join(DEFAULT_MODS))
    ap.add_argument("--se-zone-lua", help="Space Exploration's scripts/zone.lua: adds the planet 'se-zone'")
    ap.add_argument("--no-decoratives", action="store_true",
                    help="leave the decoratives out (nothing reads them yet; a third of an SE file)")
    ap.add_argument("--out", default=str(OUT), help="output file (default: the embedded Space Age data file)")
    a = ap.parse_args()
    raw = json.loads(Path(a.dump).read_text()) if a.dump else dump_data(a.mods.split(","))

    expressions = {n: noise_def(e) for n, e in raw["noise-expression"].items()}
    functions = {n: noise_def(f) for n, f in raw["noise-function"].items()}

    # name -> (prototype type, prototype) for everything that can be autoplaced
    by_name = {"tile": {}, "entity": {}, "decorative": {}}
    for typ, protos in raw.items():
        if not isinstance(protos, dict):
            continue
        for name, p in protos.items():
            if not (isinstance(p, dict) and isinstance(p.get("autoplace"), dict)):
                continue
            kind = "tile" if typ == "tile" else "decorative" if typ == "optimized-decorative" else "entity"
            by_name[kind][name] = (typ, p)

    tile_order = {n: (t.get("order", ""), n) for n, t in raw["tile"].items()}
    default_masks = raw["utility-constants"]["default"]["default_collision_masks"]
    tiles, entities, planets = {}, {}, {}
    sources = dict(raw["planet"])
    if a.se_zone_lua:
        lists = se_zone_lists(a.se_zone_lua)
        mgs = json.loads(json.dumps(raw["planet"]["nauvis"]["map_gen_settings"]))
        mgs["autoplace_settings"] = {k: {"treat_missing_as_default": False, "settings": {n: {} for n in v}}
                                     for k, v in lists.items()}
        sources["se-zone"] = {"map_gen_settings": mgs, "explicit_lists": True}
    for pname, planet in sources.items():
        mgs = planet.get("map_gen_settings") or {}
        cfg = {
            # a planet's surface seed is map_seed + crc32(planet name); the
            # map's own first surface (nauvis) uses the map seed unchanged.
            # (an SE zone surface is created with its own seed)
            "seed_offset": 0 if pname in ("nauvis", "se-zone") else zlib.crc32(pname.encode()),
            "property_expression_names": mgs.get("property_expression_names") or {},
            "autoplace_controls": sorted((mgs.get("autoplace_controls") or {}).keys()),
            "cliff_settings": mgs.get("cliff_settings") or {},
        }
        for key, kind in AUTOPLACE_KINDS:
            if kind == "decorative" and a.no_decoratives:
                cfg["decoratives"] = []
                continue
            names = list(((mgs.get("autoplace_settings") or {}).get(key) or {}).get("settings") or {})
            if kind == "entity" and not planet.get("explicit_lists"):
                # an autoplace control on the surface also enables every
                # entity tied to it (Nauvis trees via "trees", enemy bases via
                # "enemy-base") without listing them one by one
                controls = mgs.get("autoplace_controls") or {}
                names += [n for n, (_, p) in by_name[kind].items()
                          if n not in names and p["autoplace"].get("control") in controls]
            keep = []
            for n in names:
                if n not in by_name[kind]:
                    continue
                typ, p = by_name[kind][n]
                ap_ = p["autoplace"]
                if "probability_expression" not in ap_:
                    continue
                keep.append(n)
                d = {"expression": ap_["probability_expression"]}
                for k in ("local_expressions", "local_functions"):
                    if ap_.get(k):
                        d[k] = ap_[k]
                expressions.setdefault(f"{kind}:{n}:probability", d)
                if "richness_expression" in ap_:
                    r = dict(d); r["expression"] = ap_["richness_expression"]
                    expressions.setdefault(f"{kind}:{n}:richness", r)
                if kind == "tile":
                    layers = (p.get("collision_mask") or {}).get("layers") or {}
                    tiles[n] = {"layer": p.get("layer", 0), "color": rgb(p.get("map_color")),
                                # resources collide with the "resource" layer
                                # collision layers: an entity cannot stand on a
                                # tile that shares one with its own mask
                                "layers": sorted(k for k, v in layers.items() if v)}
                elif kind == "entity":
                    box = p.get("collision_box") or [[-0.1, -0.1], [0.1, 0.1]]
                    mask = (p.get("collision_mask") or default_masks.get(typ) or {}).get("layers") or {}
                    def xy(v):
                        return [v.get("x", v[0] if isinstance(v, list) else 0), v.get("y", v[1] if isinstance(v, list) else 0)] if isinstance(v, dict) else list(v[:2])
                    lt, rb = xy(box[0] if isinstance(box, list) else box["left_top"]), xy(box[1] if isinstance(box, list) else box["right_bottom"])
                    box = [lt, rb]
                    flags = p.get("flags") or []
                    entities[n] = {"type": typ, "control": ap_.get("control"),
                                   "order": ap_.get("order", ""), "color": rgb(p.get("map_color")),
                                   # footprint in tiles (ore 1, fluid patches 3)
                                   "size": max(1, math.ceil(max(box[1][0] - box[0][0], box[1][1] - box[0][1]))),
                                   # collision box [left, top, right, bottom] in tiles, for
                                   # the entity-against-entity and box-against-tile checks
                                   "box": [lt[0], lt[1], rb[0], rb[1]],
                                   # off-grid entities get a random sub-tile offset
                                   # (two draws); the others snap to the grid
                                   "off_grid": "placeable-off-grid" in flags,
                                   # placement attempts per winning tile
                                   "density": ap_.get("placement_density", 1)}
                    # tiles the entity may stand on (absent = any)
                    entities[n]["layers"] = sorted(k for k, v in mask.items() if v)
                    restr = [t for t in (ap_.get("tile_restriction") or []) if isinstance(t, str)]
                    if restr:
                        entities[n]["tile_restriction"] = restr
            if kind == "entity":
                # entities of one placement group that tie on a tile: the
                # first in prototype order = (order string, name) wins, as
                # with tiles. Seen on alien-biomes' volcanic rocks, where the
                # huge and the big rock saturate at the same probability and
                # the game places the huge one.
                keep.sort(key=lambda n: (by_name[kind][n][1].get("order", ""), n))
            if kind == "tile":
                # equal probabilities are common by design (Gleba's clamped
                # range selectors); the engine then keeps the first tile in
                # prototype order = (order string, name). Verified on Gleba.
                keep.sort(key=lambda n: tile_order[n])
            cfg[{"tile": "tiles", "entity": "entities", "decorative": "decoratives"}[kind]] = keep
            if kind == "entity":
                # resources are placed group by group in autoplace order
                cfg["resources"] = sorted((n for n in keep if entities[n]["type"] == "resource"),
                                          key=lambda n: (entities[n]["order"], n))
        planets[pname] = cfg

    # Cliff prototypes named by a planet's cliff_settings: the grid they sit
    # on, their collision layers and, per orientation (in the engine's
    # CliffOrientation order), the axis-aligned bounds of the rotated
    # collision box [left, top, right, bottom].
    cliffs = {}
    for cfg in planets.values():
        cname = (cfg.get("cliff_settings") or {}).get("name")
        cp = (raw.get("cliff") or {}).get(cname)
        if not cp or cname in cliffs:
            continue
        mask = (cp.get("collision_mask") or default_masks.get("cliff") or {}).get("layers") or {}
        boxes, rects = [], []
        for o in CLIFF_ORIENTATIONS:
            bb = cp["orientations"][o.replace("-", "_")]["collision_bounding_box"]
            (l, t), (r, b) = bb[0], bb[1]
            ang = (bb[2] if len(bb) > 2 else 0) * 2 * math.pi
            pts = [(x * math.cos(ang) - y * math.sin(ang), x * math.sin(ang) + y * math.cos(ang))
                   for x, y in ((l, t), (r, t), (r, b), (l, b))]
            boxes.append([min(q[0] for q in pts), min(q[1] for q in pts), max(q[0] for q in pts), max(q[1] for q in pts)])
            # the box itself: [left, top, right, bottom, turns]
            rects.append([l, t, r, b, bb[2] if len(bb) > 2 else 0])
        cliffs[cname] = {"grid_size": list(cp.get("grid_size", [4, 4])), "grid_offset": list(cp.get("grid_offset", [0, 0])),
                         "color": rgb(cp.get("map_color")), "layers": sorted(k for k, v in mask.items() if v),
                         "orientations": CLIFF_ORIENTATIONS, "boxes": boxes, "rects": rects}

    out = {"game_version": game_version(), "mods": a.mods.split(","),
           "planets": planets, "tiles": tiles, "entities": entities, "cliffs": cliffs,
           "functions": functions, "expressions": expressions}
    out_path = Path(a.out).resolve()
    out_path.write_text(json.dumps(out, indent=1, sort_keys=True) + "\n")
    print(f"wrote {out_path}: {len(expressions)} expressions, {len(functions)} functions, "
          f"{len(tiles)} tiles, {len(planets)} planets ({out_path.stat().st_size // 1024} KB)")
    for n, c in planets.items():
        print(f"  {n:9s} tiles={len(c['tiles']):3d} entities={len(c['entities']):3d} seed_offset={c['seed_offset']}")


if __name__ == "__main__":
    main()
