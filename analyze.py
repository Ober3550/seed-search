#!/usr/bin/env python3
"""SE seed analyzer — direct port of the old space-exploration-seedfinder.

Reads our JSONL format, converts internally to the old format, and
applies the exact same filters and display logic.

Usage:
  python3 analyze.py show output/seeds_0.jsonl      # display matching seeds
  python3 analyze.py best output/seeds_0.jsonl       # same, with loot filter
"""

import json, sys, os, re

# ── color / naming (from old JS) ──────────────────────────────────────

COLOR = {
    "R": "\033[0m",
    "bl": "\033[30m", "w": "\033[37m",
    "r": "\033[31m", "g": "\033[32m",
    "b": "\033[34m", "y": "\033[33m",
    "c": "\033[36m", "m": "\033[35m",
}

RESOURCE_COLOR = {
    "se-cryonite": "b", "se-vulcanite": "r", "se-vitamelange": "g",
    "se-iridium-ore": "y", "se-holmium-ore": "m", "se-beryllium-ore": "c",
}

NAME_MAP = {
    "iron-ore": "iron", "copper-ore": "copper", "crude-oil": "oil",
    "uranium-ore": "uranium", "stone": "stone", "coal": "coal",
    **{k: f"{COLOR[RESOURCE_COLOR[k]]}{v}{COLOR['R']}"
       for k, v in {
           "se-cryonite": "cryonite", "se-vulcanite": "vulcanite",
           "se-vitamelange": "vitamelange", "se-iridium-ore": "iridium",
           "se-holmium-ore": "holmium", "se-beryllium-ore": "beryl",
       }.items()},
}

SPECIAL_RESOURCES = set(RESOURCE_COLOR.keys())


# ── format conversion ────────────────────────────────────────────────

def our_to_old(seed):
    """Convert our flat format to the old seedfinder format."""
    zones = seed["z"]
    out = {
        "seed": seed["s"],
        "loot": list(seed.get("l", "")),
        "planets": [], "moons": [], "fields": [],
    }
    for z in zones:
        t = z["t"]
        entry = {
            "name": z["n"],
            "zone_type": [t],
            "delta_v": z.get("dv", 0),
        }
        if "r" in z:
            entry["radius"] = z["r"]
        if "rs" in z:
            entry["resource"] = z["rs"]
        tags = {}
        for sk, lk in [("g","temperature"),("w","water"),("m","moisture"),
                        ("tr","trees"),("a","aux"),("c","cliff"),("e","enemy")]:
            if sk in z: tags[lk] = z[sk]
        if tags: entry["tags"] = tags

        if t in ("planet", "moon"):
            out[t + "s"].append(entry)
        elif t == "asteroid-field":
            entry["cannonable"] = z.get("dv", 0) <= 20000
            out["fields"].append(entry)
    return out


# ── old JS logic (exact port) ─────────────────────────────────────────

def resources_array(resources):
    """Sorted list of [name, score, name, score, ...] top 6, rounded to 4dp."""
    items = sorted(resources.items(), key=lambda x: -x[1])
    result = []
    for name, score in items[:6]:
        result.append(name)
        result.append(round(score, 4))
    return result

def surface_info(surface):
    """Return array of [name, type, dv, r, enemy, water, ...resources]."""
    r = resources_array(surface.get("resource", {}))
    tags = surface.get("tags", {})
    enemy = tags.get("enemy", "enemy_none").replace("enemy_", "e ").replace("very_", "v")
    water = tags.get("water", "water_none").replace("water_", "w ")
    return [
        surface["name"],
        surface["zone_type"][0],
        "dv", surface["delta_v"],
        "r", surface.get("radius", 0),
        enemy, water,
        *[NAME_MAP.get(x, x) for x in r],
    ]

def no_color(s):
    return re.sub(r'\x1b\[[0-9;]*m', '', str(s))

def print_table(table):
    if not table: return
    widths = [0] * max(len(row) for row in table)
    for row in table:
        for j, cell in enumerate(row):
            widths[j] = max(widths[j], len(no_color(cell)))
    for row in table:
        print(" ".join(str(cell).ljust(widths[j] + len(str(cell)) - len(no_color(cell)))
                       for j, cell in enumerate(row)))

def print_planets_and_moons(items):
    table = [surface_info(s) for s in items]
    print_table(table)

def eval_seed(seed_old):
    """Exact port of old JS evalSeed. Returns True if seed matches."""
    planets = sorted(seed_old["planets"], key=lambda s: s["delta_v"])
    moons = sorted(seed_old["moons"], key=lambda s: s["delta_v"])
    all_bodies = sorted(planets + moons, key=lambda s: s["delta_v"])

    # Filter: water != none, primary is special, radius > 2000
    viable = []
    for s in all_bodies:
        r = resources_array(s.get("resource", {}))
        tags = s.get("tags", {})
        if (tags.get("water", "water_none") != "water_none"
                and r and r[0] in SPECIAL_RESOURCES
                and s.get("radius", 0) > 2000):
            viable.append(s)

    # Special holmium filter
    special_holm = [s for s in viable
                    if "se-cryonite" in s.get("resource", {})
                    and "se-vulcanite" in s.get("resource", {})
                    and "se-holmium-ore" in s.get("resource", {})]

    if special_holm:
        print(f"seed: {seed_old['seed']} loot: {''.join(seed_old['loot'])}")
        print_planets_and_moons(viable)
        print()
        return True
    return False


# ── CLI ───────────────────────────────────────────────────────────────

def cmd_best():
    """Filter by loot regex, then eval each seed."""
    loot_re = re.compile(r'^PPSS')
    files = sys.argv[2:] if len(sys.argv) > 2 else None
    if not files:
        print("usage: python3 analyze.py best <files...>")
        return

    matched = 0
    for fname in files:
        with open(fname) as f:
            for line in f:
                line = line.strip()
                if not line.startswith("{"): continue
                seed = json.loads(line)
                loot = "".join(seed.get("l", ""))
                if loot_re.match(loot):
                    if eval_seed(our_to_old(seed)):
                        matched += 1
    if matched == 0:
        print("No seeds matched loot filter ^PPSS with special holmium surfaces.")

def cmd_show():
    """Show all seeds (no loot filter)."""
    files = sys.argv[2:] if len(sys.argv) > 2 else None
    if not files:
        print("usage: python3 analyze.py show <files...>")
        return
    for fname in files:
        with open(fname) as f:
            for line in f:
                line = line.strip()
                if not line.startswith("{"): continue
                seed = json.loads(line)
                eval_seed(our_to_old(seed))

if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "show"
    {"best": cmd_best, "show": cmd_show}[cmd]()
