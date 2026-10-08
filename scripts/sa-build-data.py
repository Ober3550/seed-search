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
  tiles         layer + map colour of each autoplaced tile
  planets       per planet: property_expression_names, autoplace controls,
                cliff settings, and the tile/entity/decorative lists of its
                autoplace_settings (tiles in prototype order: ties go to the first)

Nothing planet-specific lives in the generator: sa_program.zig compiles
whichever planet it is asked for straight from this file.

Usage: sa-build-data.py [--dump existing-data-raw-dump.json] [--mods a,b,c]
Writes surface_generator/src/sa_noise_data.json (embedded by sa_data.zig).
"""
import argparse, json, os, shutil, subprocess, sys, tempfile, zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "surface_generator" / "src" / "sa_noise_data.json"
FACTORIO = os.environ.get("FACTORIO_BIN", "/Applications/factorio.app/Contents/MacOS/factorio")
DATA = os.environ.get("FACTORIO_DATA", "/Applications/factorio.app/Contents/data")
DEFAULT_MODS = ["base", "quality", "elevated-rails", "space-age"]
AUTOPLACE_KINDS = (("tile", "tile"), ("entity", "entity"), ("decorative", "decorative"))


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


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dump"); ap.add_argument("--mods", default=",".join(DEFAULT_MODS))
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
    tiles, entities, planets = {}, {}, {}
    for pname, planet in raw["planet"].items():
        mgs = planet.get("map_gen_settings") or {}
        cfg = {
            # a planet's surface seed is map_seed + crc32(planet name); the
            # map's own first surface (nauvis) uses the map seed unchanged.
            "seed_offset": 0 if pname == "nauvis" else zlib.crc32(pname.encode()),
            "property_expression_names": mgs.get("property_expression_names") or {},
            "autoplace_controls": sorted((mgs.get("autoplace_controls") or {}).keys()),
            "cliff_settings": mgs.get("cliff_settings") or {},
        }
        for key, kind in AUTOPLACE_KINDS:
            names = list(((mgs.get("autoplace_settings") or {}).get(key) or {}).get("settings") or {})
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
                    tiles[n] = {"layer": p.get("layer", 0), "color": rgb(p.get("map_color"))}
                elif kind == "entity":
                    entities[n] = {"type": typ, "control": ap_.get("control"),
                                   "order": ap_.get("order", ""), "color": rgb(p.get("map_color"))}
            if kind == "tile":
                # equal probabilities are common by design (Gleba's clamped
                # range selectors); the engine then keeps the first tile in
                # prototype order = (order string, name). Verified on Gleba.
                keep.sort(key=lambda n: tile_order[n])
            cfg[{"tile": "tiles", "entity": "entities", "decorative": "decoratives"}[kind]] = keep
        planets[pname] = cfg

    out = {"game_version": game_version(), "mods": a.mods.split(","),
           "planets": planets, "tiles": tiles, "entities": entities,
           "functions": functions, "expressions": expressions}
    OUT.write_text(json.dumps(out, indent=1, sort_keys=True) + "\n")
    print(f"wrote {OUT.relative_to(ROOT)}: {len(expressions)} expressions, {len(functions)} functions, "
          f"{len(tiles)} tiles, {len(planets)} planets ({OUT.stat().st_size // 1024} KB)")
    for n, c in planets.items():
        print(f"  {n:9s} tiles={len(c['tiles']):3d} entities={len(c['entities']):3d} seed_offset={c['seed_offset']}")


if __name__ == "__main__":
    main()
