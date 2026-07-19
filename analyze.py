#!/usr/bin/env python3
"""Converter: our JSONL format ↔ old seedfinder format, plus pretty printer.

Usage:
  python3 analyze.py convert < ours.jsonl > old_format.jsonl
  python3 analyze.py show < ours.jsonl          # pretty print to terminal
  python3 analyze.py best < ours.jsonl          # top 10 by soft-min score
  python3 analyze.py best --min-prod 4 --max-dv 20000 < ours.jsonl
"""

import json, sys, os, math
from collections import defaultdict

# ── format conversion ────────────────────────────────────────────────

def tag_short_to_long(s):
    """Convert our short tag keys to old long keys."""
    return {
        "g": "temperature", "w": "water", "m": "moisture",
        "tr": "trees", "a": "aux", "c": "cliff", "e": "enemy",
    }.get(s, s)

def our_to_old(seed):
    """Convert our flat format to the old seedfinder format."""
    zones = seed["z"]
    out = {
        "seed": seed["s"],
        "loot": list(seed.get("l", "")),
        "planets": [],
        "moons": [],
        "fields": [],
    }
    for z in zones:
        t = z["t"]
        entry = {
            "name": z["n"],
            "zone_type": [t],  # old format wraps in array
            "delta_v": z.get("dv", 0),
        }
        if "r" in z:
            entry["radius"] = z["r"]
        if "rs" in z:
            entry["resource"] = z["rs"]
        tags = {}
        for sk, lk in [("g","temperature"),("w","water"),("m","moisture"),
                        ("tr","trees"),("a","aux"),("c","cliff"),("e","enemy")]:
            if sk in z:
                tags[lk] = z[sk]
        if tags:
            entry["tags"] = tags

        if t in ("planet", "moon"):
            out[t + "s"].append(entry)
        elif t == "asteroid-field":
            entry["cannonable"] = z.get("dv", 0) <= 20000
            out["fields"].append(entry)
    return out


# ── pretty printer ────────────────────────────────────────────────────

COLOR = {
    "R": "\033[0m",
    "b": "\033[34m",  # blue = cryonite
    "r": "\033[31m",  # red = vulcanite
    "g": "\033[32m",  # green = vitamelange
    "y": "\033[33m",  # yellow = iridium
    "m": "\033[35m",  # magenta = holmium
    "c": "\033[36m",  # cyan = beryllium
    "w": "\033[37m",  # white
    "D": "\033[2m",   # dim
}

RESOURCE_COLORS = {
    "se-cryonite": "b", "se-vulcanite": "r", "se-vitamelange": "g",
    "se-iridium-ore": "y", "se-holmium-ore": "m", "se-beryllium-ore": "c",
}

RESOURCE_SHORT = {
    "iron-ore": "iron", "copper-ore": "cu", "crude-oil": "oil",
    "uranium-ore": "U", "stone": "stone", "coal": "coal",
    "se-cryonite": "cryo", "se-vulcanite": "vulc", "se-vitamelange": "vita",
    "se-iridium-ore": "irid", "se-holmium-ore": "holm", "se-beryllium-ore": "beryl",
    "se-naquium-ore": "naq", "se-methane-ice": "CH4", "se-water-ice": "H2O",
    "kr-imersite": "imer", "kr-mineral-water": "minW", "kr-rare-metal-ore": "rare",
}

def c(name):
    """Color a resource name."""
    cc = RESOURCE_COLORS.get(name, "w")
    short = RESOURCE_SHORT.get(name, name)
    return f"{COLOR[cc]}{short}{COLOR['R']}"

def format_score(s):
    if s >= 0.9999:
        return f"{COLOR['r']}★{COLOR['R']}"
    elif s > 0.5:
        return f"{COLOR['y']}{s:.2f}{COLOR['R']}"
    elif s > 0.1:
        return f"{s:.2f}"
    elif s > 0.01:
        return f"{COLOR['D']}{s:.3f}{COLOR['R']}"
    else:
        return f"{COLOR['D']}.{COLOR['R']}"

def show_seed(seed, max_bodies=20):
    """Pretty print a seed to the terminal."""
    s = seed["s"]
    loot = seed.get("l", "")
    k2 = seed.get("k", False)
    fields = [z for z in seed["z"] if z["t"] == "asteroid-field" and z.get("dv", 0) > 0]
    bodies = [z for z in seed["z"] if z["t"] in ("planet", "moon") and z.get("dv", 0) > 0]
    bodies.sort(key=lambda z: z.get("dv", 0))

    min_naq = min((z["dv"] for z in fields), default=0)
    print(f"\n{COLOR['w']}═══ seed {s}  loot: {loot}  K2: {k2}  naq: {min_naq}dv ═══{COLOR['R']}")

    for z in bodies[:max_bodies]:
        t = z["t"][0]
        r = z.get("r", 0)
        dv = z.get("dv", 0)
        water = z.get("w", "?")
        enemy = z.get("e", "?")
        rs = z.get("rs", {})

        # Top resources
        top = sorted(rs.items(), key=lambda x: -x[1])[:5]
        res_str = " ".join(f"{c(rn)}:{format_score(sc)}" for rn, sc in top)

        w_icon = {"water_none": "·", "water_low": "▁", "water_med": "▂", "water_high": "▃", "water_max": "█"}.get(water, "?")
        e_icon = {"enemy_none": "·", "enemy_very_low": "▁", "enemy_low": "▂", "enemy_med": "▃", "enemy_high": "▄", "enemy_very_high": "▅", "enemy_max": "█"}.get(enemy, "?")

        print(f"  {t} {z['n']:<20s} dv={dv:>5d} r={r:>4d} w={w_icon} e={e_icon}  {res_str}")

    if len(bodies) > max_bodies:
        print(f"  ... and {len(bodies) - max_bodies} more")

    # Asteroid fields
    if fields:
        field_strs = []
        for f in fields[:5]:
            naq = f.get("rs", {}).get("se-naquium-ore", 0)
            field_strs.append(f"{f['n']} dv={f['dv']} naq={naq:.3f}")
        print(f"  fields: {', '.join(field_strs)}")


# ── scoring ───────────────────────────────────────────────────────────

SPECIAL = {
    "se-vulcanite", "se-cryonite", "se-holmium-ore",
    "se-beryllium-ore", "se-iridium-ore", "se-vitamelange",
}

def score_seed(seed):
    """Compute a soft-min score across special resources."""
    bodies = [z for z in seed["z"] if z["t"] in ("planet", "moon")
              and z.get("dv", 0) > 0
              and z.get("w", "water_none") != "water_none"
              and z.get("r", 0) > 2000]
    scores = {}
    for r in SPECIAL:
        scores[r] = max((z["rs"].get(r, 0) for z in bodies if "rs" in z), default=0)
    vals = [v for v in scores.values() if v > 0]
    if not vals:
        return 0, {}
    total = sum(v ** -4 for v in vals)
    soft_min = (total / len(vals)) ** -0.25
    return soft_min, {r: scores[r] for r in scores if scores[r] > 0}


# ── CLI ───────────────────────────────────────────────────────────────

def cmd_convert():
    for line in sys.stdin:
        line = line.strip()
        if not line.startswith("{"): continue
        seed = json.loads(line)
        old = our_to_old(seed)
        print(json.dumps(old))

def cmd_show():
    files = sys.argv[2:] if len(sys.argv) > 2 else [sys.stdin.fileno()]
    for fname in files:
        f = sys.stdin if fname == 0 else open(fname)
        for line in f:
            line = line.strip()
            if not line.startswith("{"): continue
            seed = json.loads(line)
            show_seed(seed)
        if fname != 0: f.close()

def cmd_best():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--min-prod", type=int, default=4)
    ap.add_argument("--max-dv", type=int, default=20000)
    ap.add_argument("--min-score", type=float, default=0)
    ap.add_argument("--top", type=int, default=10)
    ap.add_argument("files", nargs="*")
    args, _ = ap.parse_known_args()

    results = []
    for fname in args.files or [sys.stdin.fileno()]:
        if fname == 0:
            f = sys.stdin
        else:
            f = open(fname)
        for line in f:
            line = line.strip()
            if not line.startswith("{"): continue
            seed = json.loads(line)
            loot = seed.get("l", "")
            if loot.count("P") < args.min_prod: continue
            fields = [z for z in seed["z"] if z["t"] == "asteroid-field" and z.get("dv", 0) > 0]
            min_naq = min((z["dv"] for z in fields), default=999999)
            if min_naq > args.max_dv: continue
            score, scores = score_seed(seed)
            if score >= args.min_score:
                results.append((score, scores, seed))
        if fname != 0: f.close()

    results.sort(key=lambda x: -x[0])
    for score, scores, seed in results[:args.top]:
        show_seed(seed)
        print(f"  score: {score:.4f}")
        for r, s in sorted(scores.items(), key=lambda x: -x[1]):
            print(f"    {c(r)}: {s:.4f}")
        print()

if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "show"
    {"convert": cmd_convert, "show": cmd_show, "best": cmd_best}[cmd]()
