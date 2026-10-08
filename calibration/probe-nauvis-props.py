#!/usr/bin/env python3
"""Probe real base-Nauvis property values (moisture/aux/temperature/elevation)
at a point grid via calculate_tile_properties — the oracle for the vanilla
field evaluator. Usage: probe-nauvis-props.py <seed> <x0> <y0> <x1> <y1> <step> <out.jsonl>
"""
import json, os, shutil, subprocess, sys, tempfile, time
from pathlib import Path
FACTORIO = "/Applications/factorio.app/Contents/MacOS/factorio"
ROOT = Path(__file__).resolve().parent
VS = ROOT / "vanilla-sweep"
RCON_PORT, GAME_PORT = 26127, 26128
PW = "nauprops"
sys.path.insert(0, str(ROOT / "sa-probe"))
from probe_ops import Rcon  # noqa: E402

seed, x0, y0, x1, y1, step = (int(v) for v in sys.argv[1:7])
out = sys.argv[7]
tmp = Path(tempfile.mkdtemp(prefix="nauprops-"))
KEYS = "moisture"  # unused; single-key queries are built inline
try:
    wd = tmp / "write"; wd.mkdir()
    mgs = json.loads((VS / "mgs-base-341.json").read_text()); mgs["seed"] = seed
    (tmp / "mgs.json").write_text(json.dumps(mgs))
    cfg = tmp / "config.ini"
    cfg.write_text(f"[path]\nread-data=/Applications/factorio.app/Contents/data\nwrite-data={wd}\n")
    save = tmp / "p.zip"
    subprocess.run([FACTORIO, "--config", str(cfg), "--mod-directory", str(VS / "mods-empty"),
                    "--create", str(save), "--map-gen-settings", str(tmp / "mgs.json")],
                   capture_output=True, timeout=300)
    srv = subprocess.Popen([FACTORIO, "--config", str(cfg), "--mod-directory", str(VS / "mods-empty"),
                            "--start-server", str(save), "--port", str(GAME_PORT),
                            "--rcon-port", str(RCON_PORT), "--rcon-password", PW,
                            "--server-settings", str(VS / "server-settings.json")],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        c = None
        for _ in range(300):
            if srv.poll() is not None: print("server died"); sys.exit(1)
            try: c = Rcon("127.0.0.1", RCON_PORT, PW, timeout=10); break
            except OSError: time.sleep(1)
        c.s.settimeout(300)
        c.cmd('/silent-command game.surfaces["nauvis"].force_generate_chunk_requests()')
        pts = [(x, y) for y in range(y0, y1 + 1, step) for x in range(x0, x1 + 1, step)]
        keys = ["moisture", "aux", "temperature", "elevation"]
        handles = {k: open(out + "." + k, "w") for k in keys}
        try:
            n = 0
            B = 100
            for i in range(0, len(pts), B):
                batch = pts[i:i + B]
                pos = ",".join(f"{{{x},{y}}}" for x, y in batch)
                for key in keys:
                    q = (f"/silent-command local ok,t=pcall(function() return "
                         f"game.surfaces['nauvis'].calculate_tile_properties({{'{key}'}},{{{pos}}}) end) "
                         f"if not ok then rcon.print('ERR:'..t) return end "
                         f"local v=t['{key}'] if not v then rcon.print('NOFIELD') return end "
                         f"local o={{}} for k=1,#v do o[k]=string.format('%.9g',v[k]) end "
                         f"rcon.print(table.concat(o,','))")
                    resp = c.cmd(q).strip()
                    if resp.startswith("ERR") or resp == "NOFIELD" or not resp:
                        print("probe problem:", key, resp[:160]); sys.exit(1)
                    vals = resp.split(",")
                    for (px, py), val in zip(batch, vals):
                        try: fv = float(val)
                        except ValueError: continue
                        handles[key].write(json.dumps({"x": px, "y": py, "v": fv}) + "\n")
                        n += 1
        finally:
            for h in handles.values(): h.close()
        print(f"probed {n} values -> {out}.<key>\n")
    finally:
        if srv.poll() is None:
            srv.terminate()
            try: srv.wait(timeout=15)
            except subprocess.TimeoutExpired: srv.kill()
finally:
    shutil.rmtree(tmp, ignore_errors=True)
