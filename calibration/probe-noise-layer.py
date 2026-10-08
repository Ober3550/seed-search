#!/usr/bin/env python3
"""Probe the game's noise_layer_noise(seed=19) values (the per-tile noise that
drives grass/dirt speckle) at a point grid — the oracle for the multioctave
amplitude scheme. Usage: probe-noise-layer.py <seed> <x0> <y0> <x1> <y1> <step> <out>
"""
import json, os, shutil, subprocess, sys, tempfile, time
from pathlib import Path
FACTORIO = "/Applications/factorio.app/Contents/MacOS/factorio"
ROOT = Path(__file__).resolve().parent
VS = ROOT / "vanilla-sweep"
RCON_PORT, GAME_PORT = 26151, 26152
PW = "nlprobe"
sys.path.insert(0, str(ROOT / "sa-probe"))
from probe_ops import Rcon  # noqa: E402

seed, x0, y0, x1, y1, step = (int(v) for v in sys.argv[1:7])
out = sys.argv[7]
tmp = Path(tempfile.mkdtemp(prefix="nlprobe-"))
MODS = "probe-noise-layer_1.0.0"
try:
    wd = tmp / "write"; wd.mkdir()
    mods = tmp / "mods"; mods.mkdir()
    (mods / MODS).mkdir()
    (mods / MODS / "info.json").write_text(json.dumps(
        {"name": "probe-noise-layer", "version": "1.0.0", "title": "nl", "author": "cal",
         "factorio_version": "2.0", "dependencies": ["base >= 2.0"]}))
    (mods / MODS / "data.lua").write_text(
        'data:extend({{ {{ type="noise-expression", name="probe_nl19",\n'
        '  expression="noise_layer_noise{{seed=19}}" }} }})\n')
    (mods / "mod-list.json").write_text(json.dumps({"mods": [
        {"name": "base", "enabled": True}, {"name": MODS, "enabled": True}]}))
    mgs = json.loads((VS / "mgs-base-341.json").read_text()); mgs["seed"] = seed
    (tmp / "mgs.json").write_text(json.dumps(mgs))
    cfg = tmp / "config.ini"
    cfg.write_text(f"[path]\nread-data=/Applications/factorio.app/Contents/data\nwrite-data={wd}\n")
    save = tmp / "n.zip"
    subprocess.run([FACTORIO, "--config", str(cfg), "--mod-directory", str(mods),
                    "--create", str(save), "--map-gen-settings", str(tmp / "mgs.json")],
                   capture_output=True, timeout=300)
    srv = subprocess.Popen([FACTORIO, "--config", str(cfg), "--mod-directory", str(mods),
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
        pts = [(x, y) for y in range(y0, y1 + 1, step) for x in range(x0, x1 + 1, step)]
        n = 0
        with open(out, "w") as fout:
            B = 60
            for i in range(0, len(pts), B):
                batch = pts[i:i + B]
                pos = ",".join(f"{{{x},{y}}}" for x, y in batch)
                q = (f"/silent-command local ok,t=pcall(function() return "
                     f"game.surfaces['nauvis'].calculate_tile_properties({{'probe_nl19'}},{{{pos}}}) end) "
                     f"if not ok then rcon.print('ERR:'..t) return end "
                     f"local v=t['probe_nl19'] local o={{}} for k=1,#v do o[k]=string.format('%.9g',v[k]) end "
                     f"rcon.print(table.concat(o,','))")
                resp = c.cmd(q).strip()
                if resp.startswith("ERR") or not resp:
                    print("probe problem:", resp[:160]); sys.exit(1)
                vals = resp.split(",")
                for (px, py), val in zip(batch, vals):
                    try: fout.write(json.dumps({"x": px, "y": py, "v": float(val)}) + "\n"); n += 1
                    except ValueError: pass
        print(f"probed {n} -> {out}")
    finally:
        if srv.poll() is None:
            srv.terminate()
            try: srv.wait(timeout=15)
            except subprocess.TimeoutExpired: srv.kill()
finally:
    shutil.rmtree(tmp, ignore_errors=True)
