#!/usr/bin/env python3
"""Find a seed's starting-lake centre by probing elevation (the lake is the
only negative-elevation feature within ~140 of spawn). Two-stage: coarse rings
at r~68..84 find the deepest direction, then a fine 31x31 grid refines.

Usage: discover-lake.py <seed>
"""
import json, os, shutil, subprocess, sys, tempfile, time, math
from pathlib import Path
FACTORIO = "/Applications/factorio.app/Contents/MacOS/factorio"
ROOT = Path(__file__).resolve().parent
VS = ROOT / "vanilla-sweep"
RCON_PORT, GAME_PORT = 26131, 26132
PW = "lakedisc"
sys.path.insert(0, str(ROOT / "sa-probe"))
from probe_ops import Rcon  # noqa: E402

seed = int(sys.argv[1])
tmp = Path(tempfile.mkdtemp(prefix="lake-"))
def probe_elev(c, pts):
    out = []
    B = 120
    for i in range(0, len(pts), B):
        batch = pts[i:i + B]
        pos = ",".join(f"{{{x},{y}}}" for x, y in batch)
        q = (f"/silent-command local ok,t=pcall(function() return "
             f"game.surfaces['nauvis'].calculate_tile_properties({{'elevation'}},{{{pos}}}) end) "
             f"if not ok then rcon.print('ERR:'..t) return end "
             f"local v=t['elevation'] local o={{}} for k=1,#v do o[k]=string.format('%.6g',v[k]) end "
             f"rcon.print(table.concat(o,','))")
        resp = c.cmd(q).strip()
        if resp.startswith("ERR") or not resp:
            print("probe problem:", resp[:120]); sys.exit(1)
        for (x, y), val in zip(batch, resp.split(",")):
            try: out.append(((x, y), float(val)))
            except ValueError: pass
    return out

try:
    wd = tmp / "write"; wd.mkdir()
    mgs = json.loads((VS / "mgs-base-341.json").read_text()); mgs["seed"] = seed
    (tmp / "mgs.json").write_text(json.dumps(mgs))
    cfg = tmp / "config.ini"
    cfg.write_text(f"[path]\nread-data=/Applications/factorio.app/Contents/data\nwrite-data={wd}\n")
    save = tmp / "l.zip"
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
        c.s.settimeout(600)
        # coarse rings at several radii
        pts = []
        for r in (60, 66, 72, 78, 84, 90):
            for k in range(180):
                th = 2 * math.pi * k / 180
                pts.append((round(r * math.cos(th)), round(r * math.sin(th))))
        ring = probe_elev(c, pts)
        ring.sort(key=lambda kv: kv[1])
        cx, cy = ring[0][0]
        # fine grid around the deepest point
        pts = [(cx + dx, cy + dy) for dy in range(-15, 16) for dx in range(-15, 16)]
        fine = probe_elev(c, pts)
        neg = [(xy, v) for xy, v in fine if v < -2]
        if not neg:
            neg = fine[:80]
        cx2 = sum(x for (x, _), _ in neg) / len(neg)
        cy2 = sum(y for (_, y), _ in neg) / len(neg)
        best = min(fine, key=lambda kv: kv[1])
        print(f"seed {seed}: coarse min {ring[0]} | deepest {best} | centroid {cx2:.1f},{cy2:.1f} | r={math.hypot(cx2, cy2):.1f}")
    finally:
        if srv.poll() is None:
            srv.terminate()
            try: srv.wait(timeout=15)
            except subprocess.TimeoutExpired: srv.kill()
finally:
    shutil.rmtree(tmp, ignore_errors=True)
