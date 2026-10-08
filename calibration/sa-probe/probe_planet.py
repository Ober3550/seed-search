#!/usr/bin/env python3
"""Probe an SA planet property expression via calculate_tile_properties.

The game only honours map_gen_settings.property_expression_names values that
are *registered* noise-expression names. The planet expressions (e.g.
'fulgora_elevation') are registered by the space-age data, so we create a
plain save whose property slot 'aux' (and optionally 'elevation') points at
the target expression, then probe that key over a tile grid. This gives raw
per-tile expression values to compare against the Zig evaluator.

Usage: probe_planet.py <entry-name> <prop-key> <seed> x0 y0 x1 y1 step out
  entry-name: closure entry to evaluate (e.g. fulgora_elevation)
  prop-key  : slot to read back ('aux' avoids terrain-post-processing)
"""
import json, os, subprocess, sys, time
from pathlib import Path

HERE = Path(__file__).resolve().parent
FACTORIO = "/Applications/factorio.app/Contents/MacOS/factorio"
RCON_PORT, GAME_PORT = 25623, 34223
PW = "saprobe"

sys.path.insert(0, str(HERE))
from probe_ops import Rcon


def main():
    entry, key, seed = sys.argv[1], sys.argv[2], int(sys.argv[3])
    x0, y0, x1, y1, step = (int(v) for v in sys.argv[4:9])
    out_path = sys.argv[9]
    mgs = {"seed": seed, "property_expression_names": {key: entry}}
    json.dump(mgs, open(str(HERE / "out" / "mgs-planet.json"), "w"))
    save = str(HERE / "fdata" / "saves" / "planet-probe.zip")
    if os.path.exists(save):
        os.remove(save)
    subprocess.run([FACTORIO, "--config", str(HERE / "config.ini"),
                    "--mod-directory", str(HERE / "mods"),
                    "--create", save, "--map-gen-settings", str(HERE / "out" / "mgs-planet.json")],
                   capture_output=True, text=True, timeout=600)
    if not os.path.exists(save):
        print("create failed"); sys.exit(1)
    srv = subprocess.Popen([FACTORIO, "--config", str(HERE / "config.ini"),
                            "--mod-directory", str(HERE / "mods"),
                            "--start-server", save, "--port", str(GAME_PORT),
                            "--rcon-port", str(RCON_PORT), "--rcon-password", PW,
                            "--server-settings", str(HERE / "server-settings.json")],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        c = None
        for _ in range(240):
            if srv.poll() is not None:
                print("server died"); sys.exit(1)
            try:
                c = Rcon("127.0.0.1", RCON_PORT, PW, timeout=10)
                break
            except OSError:
                time.sleep(1)
        c.s.settimeout(600)
        c.cmd('/silent-command rcon.print("warmup")')
        pts = [(x, y) for y in range(y0, y1 + 1, step) for x in range(x0, x1 + 1, step)]
        n = 0
        with open(out_path, "w") as fout:
            B = 200
            for i in range(0, len(pts), B):
                batch = pts[i:i + B]
                pos = ",".join(f"{{{x},{y}}}" for x, y in batch)
                q = (f"/silent-command local ok,t=pcall(function() return "
                     f"game.surfaces['nauvis'].calculate_tile_properties({{'{key}'}},{{{pos}}}) end) "
                     f"if not ok then rcon.print('ERR:'..t) return end "
                     f"local v=t['{key}'] if not v then rcon.print('NOFIELD') return end "
                     f"local o={{}} for k=1,#v do o[k]=string.format('%.9g',v[k]) end "
                     f"rcon.print(table.concat(o,','))")
                resp = c.cmd(q).strip()
                if resp.startswith("ERR") or resp == "NOFIELD" or not resp:
                    print("probe problem:", resp[:160]); break
                vals = resp.split(",")
                for (x, y), v in zip(batch, vals):
                    try:
                        fv = float(v)
                    except ValueError:
                        continue
                    fout.write(json.dumps({"x": x, "y": y, "v": fv}) + "\n")
                    n += 1
        print(f"wrote {n} -> {out_path}")
    finally:
        if srv.poll() is None:
            srv.terminate()
            try:
                srv.wait(timeout=15)
            except subprocess.TimeoutExpired:
                srv.kill()


if __name__ == "__main__":
    main()
