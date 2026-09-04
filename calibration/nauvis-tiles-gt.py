#!/usr/bin/env python3
"""Dump the real base-Nauvis tile grid for a seed/region (ground truth).

Boots a NO-MODS world (mods = base + tile-dump only) at the given seed, then
uses the tile-dump mod's /tile-dump console command to write every tile name
in a radius disk to out.jsonl: {"x":..,"y":..,"t":"grass-2","w":0|1}.

Usage: nauvis-tiles-gt.py <seed> <radius> <out.jsonl>
"""
import json, os, shutil, subprocess, sys, tempfile, time
from pathlib import Path

FACTORIO = "/Applications/factorio.app/Contents/MacOS/factorio"
ROOT = Path(__file__).resolve().parent
VS = ROOT / "vanilla-sweep"
MOD_SRC = ROOT.parent / "calibration" / "saves" / "mods" / "tile-dump_1.0.0"
RCON_PORT, GAME_PORT = 26123, 26124
PW = "naugt"

sys.path.insert(0, str(ROOT / "sa-probe"))
from probe_ops import Rcon  # noqa: E402

seed, radius, out = int(sys.argv[1]), int(sys.argv[2]), sys.argv[3]

tmp = Path(tempfile.mkdtemp(prefix="naugt-"))
try:
    mods = tmp / "mods"; mods.mkdir()
    shutil.copytree(MOD_SRC, mods / MOD_SRC.name)
    # control.lua only — its data.lua registers alien-biomes noise probes that
    # fail without alien-biomes loaded, and we only need the /tile-dump writer.
    (mods / MOD_SRC.name / "data.lua").write_text("-- stripped: control-only for base worlds\n")
    (mods / "mod-list.json").write_text(json.dumps({"mods": [
        {"name": "base", "enabled": True}, {"name": "tile-dump", "enabled": True}]}))
    wd = tmp / "write"; wd.mkdir()
    mgs = json.loads((VS / "mgs-base-341.json").read_text()); mgs["seed"] = seed
    (tmp / "mgs.json").write_text(json.dumps(mgs))
    cfg = tmp / "config.ini"
    cfg.write_text(f"[path]\nread-data=/Applications/factorio.app/Contents/data\nwrite-data={wd}\n")
    save = tmp / "dump.zip"
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
            if srv.poll() is not None:
                print("server died"); sys.exit(1)
            try:
                c = Rcon("127.0.0.1", RCON_PORT, PW, timeout=10); break
            except OSError:
                time.sleep(1)
        c.s.settimeout(300)
        c.cmd(f"/tile-dump nauvis {radius}")
        time.sleep(2)
        gt = wd / "script-output" / "tile-dump-nauvis.jsonl"
        if not gt.exists():
            print("no dump file:", gt); sys.exit(1)
        lines = gt.read_text().strip().splitlines()
        with open(out, "w") as fout:
            for ln in lines:
                fout.write(ln + "\n")
        print(f"wrote {len(lines)} tiles -> {out}")
    finally:
        if srv.poll() is None:
            srv.terminate()
            try: srv.wait(timeout=15)
            except subprocess.TimeoutExpired: srv.kill()
finally:
    shutil.rmtree(tmp, ignore_errors=True)
