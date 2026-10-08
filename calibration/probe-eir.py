#!/usr/bin/env python3
"""Probe expression_in_range over a (aux, moisture) point cloud from the live
game: registers the given expression on the elevation slot (aux/moisture keep
their engine defaults) and reads all three per point.

Usage: probe-eir.py '<expression_in_range(...)>' <out.jsonl> [ring step]
"""
import json, math, subprocess, sys, tempfile, time, shutil
from pathlib import Path
import sys as _sys
_sys.path.insert(0, str(Path(__file__).resolve().parent / "sa-probe"))
from probe_ops import Rcon  # noqa

FACTORIO = "/Applications/factorio.app/Contents/MacOS/factorio"
VS = Path(__file__).resolve().parent / "vanilla-sweep"
expr, out = sys.argv[1], sys.argv[2]
step = int(sys.argv[3]) if len(sys.argv) > 3 else 6
seed = 341
tmp = Path(tempfile.mkdtemp(prefix="eir-"))
try:
    wd = tmp / "write"; wd.mkdir(); mods = tmp / "mods"; mods.mkdir()
    M = "probe-eir_1.0.0"; (mods / M).mkdir()
    (mods / M / "info.json").write_text(json.dumps(
        {"name": "probe-eir", "version": "1.0.0", "title": "eir", "author": "c",
         "factorio_version": "2.0", "dependencies": ["base >= 2.0"]}))
    (mods / M / "data.lua").write_text(
        'data:extend({ { type="noise-expression", name="eir_probe", expression=' +
        json.dumps(expr) + " } })\n")
    (mods / "mod-list.json").write_text(json.dumps(
        {"mods": [{"name": "base", "enabled": True}, {"name": M, "enabled": True}]}))
    mgs = json.loads((VS / "mgs-base-341.json").read_text()); mgs["seed"] = seed
    mgs["property_expression_names"] = {"elevation": "eir_probe"}
    (tmp / "mgs.json").write_text(json.dumps(mgs))
    cfg = tmp / "config.ini"
    cfg.write_text(f"[path]\nread-data=/Applications/factorio.app/Contents/data\nwrite-data={wd}\n")
    save = tmp / "n.zip"
    subprocess.run([FACTORIO, "--config", str(cfg), "--mod-directory", str(mods),
                    "--create", str(save), "--map-gen-settings", str(tmp / "mgs.json")],
                   capture_output=True, timeout=300)
    srv = subprocess.Popen([FACTORIO, "--config", str(cfg), "--mod-directory", str(mods),
                            "--start-server", str(save), "--port", "26175", "--rcon-port", "26176",
                            "--rcon-password", "eir", "--server-settings", str(VS / "server-settings.json")],
                           stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
    c = None
    for _ in range(200):
        if srv.poll() is not None:
            print("server died"); sys.exit(1)
        try:
            c = Rcon("127.0.0.1", 26176, "eir", timeout=10); break
        except OSError:
            time.sleep(1)
    pts = []
    for d in range(30, 270, step):
        for k in range(0, 360, 10):
            pts.append((round(d * math.cos(math.radians(k))), round(d * math.sin(math.radians(k)))))
    data = {k: [] for k in ["aux", "moisture", "elevation"]}
    for key in data:
        for i in range(0, len(pts), 90):
            batch = pts[i:i + 90]
            pos = ",".join(f"{{{x},{y}}}" for x, y in batch)
            q = (f"/silent-command local ok,t=pcall(function() return "
                 f"game.surfaces['nauvis'].calculate_tile_properties({{'{key}'}},{{{pos}}}) end) "
                 f"if not ok then rcon.print('ERR:'..t) return end local v=t['{key}'] "
                 f"if not v then rcon.print('NOFIELD') return end "
                 f"local o={{}} for k=1,#v do o[k]=string.format('%.6g',v[k]) end rcon.print(table.concat(o,','))")
            resp = c.cmd(q).strip()
            if not resp or resp.startswith("ERR") or resp == "NOFIELD":
                print("bad", key, repr(resp[:60])); sys.exit(1)
            data[key] += [float(x) for x in resp.split(",")]
    with open(out, "w") as f:
        for n, (x, y) in enumerate(pts):
            f.write(json.dumps({"x": x, "y": y, "aux": data["aux"][n],
                                "moisture": data["moisture"][n], "eir": data["elevation"][n]}) + "\n")
    print("wrote", len(pts), "->", out)
    if srv.poll() is None:
        srv.terminate()
finally:
    shutil.rmtree(tmp, ignore_errors=True)
