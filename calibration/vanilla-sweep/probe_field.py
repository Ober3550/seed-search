#!/usr/bin/env python3
"""Probe the game's exact `default-<resource>-patches` noise field (the
all_patches value: spot_noise + blob, max with starting) at grid positions via
surface.calculate_tile_properties on a headless vanilla server.

Usage:
  python3 probe_field.py --save base-341 --resource iron-ore \
      --grids "-496:-416:104:184:2,82:162:-342:-262:2" --out out/probe-iron.jsonl

Each grid is x0:x1:y0:y1:step (inclusive start, exclusive end).
Output lines: {"x":..,"y":..,"v":..}
"""
import argparse, json, os, subprocess, time, sys
from run_case import Rcon, FACTORIO, CONFIG, MODS, FDATA, OUT, RCON_PORT, RCON_PW


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--save", required=True)
    ap.add_argument("--resource", default="iron-ore")
    ap.add_argument("--grids", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    save = os.path.join(FDATA, "saves", f"{args.save}.zip")
    assert os.path.exists(save), save
    prop = f"default-{args.resource}-patches"

    pts = []
    for g in args.grids.split(","):
        x0, x1, y0, y1, st = (int(v) for v in g.split(":"))
        for y in range(y0, y1, st):
            for x in range(x0, x1, st):
                pts.append((x, y))
    print(f"probing {len(pts)} positions of {prop}")

    srv = subprocess.Popen([FACTORIO, "--config", CONFIG, "--mod-directory", MODS,
                            "--start-server", save, "--port", "34199",
                            "--rcon-port", str(RCON_PORT), "--rcon-password", RCON_PW,
                            "--server-settings", os.path.join(os.path.dirname(CONFIG), "server-settings.json")],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        rcon = None
        for _ in range(120):
            time.sleep(1)
            try:
                rcon = Rcon("127.0.0.1", RCON_PORT, RCON_PW)
                break
            except OSError:
                continue
        assert rcon, "no RCON"
        rcon.cmd("/sc rcon.print('warmup')")

        with open(args.out, "w") as f:
            B = 400
            for i in range(0, len(pts), B):
                batch = pts[i:i + B]
                pos = ",".join(f"{{{x},{y}}}" for x, y in batch)
                lua = (f"/sc local t=game.surfaces[1].calculate_tile_properties({{'{prop}'}},{{{pos}}}) "
                       f"local v=t['{prop}'] local o={{}} for k=1,#v do o[k]=string.format('%.9g',v[k]) end "
                       f"rcon.print(table.concat(o,','))")
                resp = rcon.cmd(lua).strip()
                vals = resp.split(",")
                assert len(vals) == len(batch), f"batch {i}: {len(vals)} vs {len(batch)}: {resp[:200]}"
                for (x, y), v in zip(batch, vals):
                    f.write(json.dumps({"x": x, "y": y, "v": float(v)}) + "\n")
                if i % 4000 == 0:
                    print(f"  {i}/{len(pts)}")
    finally:
        srv.terminate()
        try:
            srv.wait(timeout=15)
        except subprocess.TimeoutExpired:
            srv.kill()
    print(f"wrote {args.out}")


if __name__ == "__main__":
    main()
