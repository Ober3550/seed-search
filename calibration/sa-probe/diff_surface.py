#!/usr/bin/env python3
"""Diff the generator against the live game, expression by expression.

  diff_surface.py <game.json> <ours.json> [--all]

Both files use the layout written by probe_surface.py (game) and
`sa_main <planet> probe` (ours) over the same grid. For every named expression
present in both: how many samples are bit-identical as f32, and the worst
absolute error. Then the tile agreement with a confusion summary, and for
resource entities the per-resource counts, positional overlap and amounts.
"""
import collections, json, struct, sys


def f32(v):
    try:
        return struct.unpack("<f", struct.pack("<f", v))[0]
    except (OverflowError, struct.error):
        return float("inf") if v > 0 else float("-inf")


def main():
    game, ours = json.load(open(sys.argv[1])), json.load(open(sys.argv[2]))
    show_all = "--all" in sys.argv
    if game["grid"] != ours["grid"]:
        sys.exit(f"grid mismatch: {game['grid']} vs {ours['grid']}")
    rows = []
    for name, gv in game["values"].items():
        ov = ours["values"].get(name)
        if ov is None:
            rows.append((2, name, "missing: " + ours.get("errors", {}).get(name, "not probed")))
            continue
        exact, worst, wi = 0, 0.0, 0
        for i, (g, o) in enumerate(zip(gv, ov)):
            o = float("nan") if o is None else o
            if f32(g) == f32(o):
                exact += 1
                continue
            err = abs(g - o) if g == g and o == o and abs(g) != float("inf") and abs(o) != float("inf") else float("inf")
            if err > worst:
                worst, wi = err, i
        if exact == len(gv):
            rows.append((0, name, f"exact ({exact})"))
        else:
            rows.append((1, name, f"{exact}/{len(gv)} exact, max err {worst:.6g} "
                                  f"(game {gv[wi]:.9g} ours {ov[wi]})"))
    rows.sort()
    n_ok = sum(1 for r in rows if r[0] == 0)
    print(f"expressions: {n_ok}/{len(rows)} exact")
    for st, name, msg in rows:
        if st or show_all:
            print(f"  {'ok  ' if st == 0 else 'DIFF' if st == 1 else 'MISS'} {name}: {msg}")
    if "tiles" in game and "tiles" in ours:
        gt, ot = game["tiles"], ours["tiles"]
        ok = sum(1 for g, o in zip(gt, ot) if g == o)
        print(f"tiles: {ok}/{len(gt)} agree ({100 * ok / len(gt):.2f}%)")
        conf = collections.Counter((g, o) for g, o in zip(gt, ot) if g != o)
        for (g, o), c in conf.most_common(12):
            print(f"  game {g} -> ours {o}: {c}")
    elif "tiles" in game:
        print("tiles: not produced by ours:", ours.get("errors", {}).get("tiles"))
    if "entities" in game and "entities" in ours:
        # resources only (the game dump also lists rocks, ruins, ... with a=0)
        def by_name(ents):
            out = collections.defaultdict(dict)
            for e in ents:
                if e["a"] > 0:
                    out[e["n"]][(int(e["x"] // 1), int(e["y"] // 1))] = e["a"]
            return out
        g, o = by_name(game["entities"]), by_name(ours["entities"])
        print("resources (entities: game / ours / same tile; amount ours/game):")
        for name in sorted(set(g) | set(o)):
            gp, op = g.get(name, {}), o.get(name, {})
            both = len(set(gp) & set(op))
            ga, oa = sum(gp.values()), sum(op.values())
            print(f"  {name}: {len(gp)} / {len(op)} / {both} "
                  f"({100 * both / max(len(gp), 1):.1f}% of game found, "
                  f"{100 * both / max(len(op), 1):.1f}% of ours real); "
                  f"amount x{oa / ga if ga else float('nan'):.3f}")


if __name__ == "__main__":
    main()
