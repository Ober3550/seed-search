#!/usr/bin/env python3
"""Controlled expression_in_range probes. One variable is pinned to a constant
(registered noise-expression), the other sweeps spatially; reads both + the
probe values from the 'elevation'/'temperature' property slots.

Usage: probe-eir2.py <spec.json> <out.jsonl>
spec: { "pin": {"aux": 0.95},                      # optional constant pins
        "slots": {"elevation": "<expr>", "temperature": "<expr>"} }
"""
import json, math, subprocess, sys, tempfile, time, shutil
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent / "sa-probe"))
from probe_ops import Rcon  # noqa

FACTORIO = "/Applications/factorio.app/Contents/MacOS/factorio"
VS = Path(__file__).resolve().parent / "vanilla-sweep"
spec = json.load(open(sys.argv[1]))
out = sys.argv[2]
seed = 341
tmp = Path(tempfile.mkdtemp(prefix="eir2-"))
try:
    wd = tmp / "write"; wd.mkdir(); mods = tmp / "mods"; mods.mkdir()
    M = "probe-eir2_1.0.0"; (mods / M).mkdir()
    (mods / M / "info.json").write_text(json.dumps(
        {"name": "probe-eir2", "version": "1.0.0", "title": "e2", "author": "c",
         "factorio_version": "2.0", "dependencies": ["base >= 2.0"]}))
    lua = ["data:extend({"]
    for k, v in spec.get("pin", {}).items():
        lua.append(f' {{ type="noise-expression", name="pin_{k}", expression={json.dumps(str(v))} }},')
    for slot, expr in spec["slots"].items():
        lua.append(f' {{ type="noise-expression", name="slot_{slot}", expression={json.dumps(expr)} }},')
    lua.append("})\n")
    (mods / M / "data.lua").write_text("".join(lua))
    (mods / "mod-list.json").write_text(json.dumps(
        {"mods": [{"name": "base", "enabled": True}, {"name": M, "enabled": True}]}))
    pen = {slot: f"slot_{slot}" for slot in spec["slots"]}
    for k in spec.get("pin", {}):
        pen[k] = f"pin_{k}"
    mgs = json.loads((VS / "mgs-base-341.json").read_text()); mgs["seed"] = seed
    mgs["property_expression_names"] = pen
    # climate control forces aux/moisture from the climate even when pinned:
    mgs["aux_climate_control"] = False
    mgs["moisture_climate_control"] = False
    (tmp / "mgs.json").write_text(json.dumps(mgs))
    cfg = tmp / "config.ini"
    cfg.write_text(f"[path]\nread-data=/Applications/factorio.app/Contents/data\nwrite-data={wd}\n")
    save = tmp / "n.zip"
    subprocess.run([FACTORIO, "--config", str(cfg), "--mod-directory", str(mods),
                    "--create", str(save), "--map-gen-settings", str(tmp / "mgs.json")],
                   capture_output=True, timeout=300)
    srv = subprocess.Popen([FACTORIO, "--config", str(cfg), "--mod-directory", str(mods),
                            "--start-server", str(save), "--port", "26185", "--rcon-port", "26186",
                            "--rcon-password", "e2", "--server-settings", str(VS / "server-settings.json")],
                           stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
    c = None
    for _ in range(200):
        if srv.poll() is not None:
            print("server died"); sys.exit(1)
        try:
            c = Rcon("127.0.0.1", 26186, "e2", timeout=10); break
        except OSError:
            time.sleep(1)
    pts = []
    step = int(sys.argv[3]) if len(sys.argv) > 3 else 6
    for d in range(20, 280, step):
        for k in range(0, 360, 9):
            pts.append((round(d * math.cos(math.radians(k))), round(d * math.sin(math.radians(k)))))
    keys = []
    for k in pen:
        keys.append(k)
    for k in ("aux", "moisture"):
        if k not in pen:
            keys.append(k)
    data = {k: [] for k in keys}
    for key in keys:
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
            row = {"x": x, "y": y}
            for key in keys:
                row[key] = data[key][n]
            f.write(json.dumps(row) + "\n")
    print("wrote", len(pts), "->", out)
    if srv.poll() is None:
        srv.terminate()
finally:
    shutil.rmtree(tmp, ignore_errors=True)
