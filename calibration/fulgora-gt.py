#!/usr/bin/env python3
"""Dump the real Fulgora (Space Age) tile grid for a seed/region (ground truth).

Boots a headless world with Space Age enabled (base + space-age + quality +
tile-dump) whose map-gen-settings are FULGORA's planet map_gen_settings, so
the engine generates the actual fulgora surface (fulgora_elevation, oil
oceans, fulgora tiles) on the starting surface. Then /tile-dump writes every
tile name in a radius disk to out.jsonl:
   {"x":..,"y":..,"t":"<tile-name>","w":0|1}
The surface is called "nauvis" (map starts on the first surface) but its
map-gen settings + registered fulgora_* expressions are Fulgora's.

Usage: fulgora-gt.py <seed> <radius> <out.jsonl>
"""
import json, os, shutil, subprocess, sys, tempfile, time
from pathlib import Path

FACTORIO = os.environ.get("FACTORIO_BIN", "/Applications/factorio.app/Contents/MacOS/factorio")
DATA = os.environ.get("FACTORIO_DATA", "/Applications/factorio.app/Contents/data")
ROOT = Path(__file__).resolve().parent
SA_DATA = ROOT.parent / "surface_generator" / "sa-data" / "planets.json"
MOD_SRC = ROOT.parent / "calibration" / "saves" / "mods" / "tile-dump_1.0.0"
RCON_PORT, GAME_PORT = 26143, 26144
PW = "fg gt"

sys.path.insert(0, str(ROOT / "sa-probe"))
from probe_ops import Rcon  # noqa: E402

seed, radius, out = int(sys.argv[1]), int(sys.argv[2]), sys.argv[3]
planets = json.loads(SA_DATA.read_text())
mgs = planets["fulgora"]
mgs = json.loads(json.dumps(mgs))  # deep copy
mgs["seed"] = seed

tmp = Path(tempfile.mkdtemp(prefix="fulgora-gt-"))
try:
    mods = tmp / "mods"; mods.mkdir()
    shutil.copytree(MOD_SRC, mods / MOD_SRC.name)
    (mods / MOD_SRC.name / "data.lua").write_text("-- stripped: control-only\n")
    # Space Age ships as an expansion in the data dir; enable it (and its
    # dependencies quality/elevated-rails) by copying them into the sandbox.
    for exp in ("quality", "elevated-rails", "space-age"):
        src = Path(DATA) / exp
        dst = mods / exp
        if not dst.exists():
            shutil.copytree(src, dst, ignore=shutil.ignore_patterns("*.zip"))
    (mods / "mod-list.json").write_text(json.dumps({"mods": [
        {"name": "base", "enabled": True},
        {"name": "quality", "enabled": True},
        {"name": "elevated-rails", "enabled": True},
        {"name": "space-age", "enabled": True},
        {"name": "tile-dump", "enabled": True}]}))
    wd = tmp / "write"; wd.mkdir()
    (tmp / "mgs.json").write_text(json.dumps(mgs))
    cfg = tmp / "config.ini"
    cfg.write_text(f"[path]\nread-data={DATA}\nwrite-data={wd}\n")
    save = tmp / "dump.zip"
    r = subprocess.run([FACTORIO, "--config", str(cfg), "--mod-directory", str(mods),
                        "--create", str(save), "--map-gen-settings", str(tmp / "mgs.json")],
                       capture_output=True, text=True, timeout=600)
    if r.returncode != 0:
        print("create failed:\n", r.stderr[-3000:]); sys.exit(1)
    srv = subprocess.Popen([FACTORIO, "--config", str(cfg), "--mod-directory", str(mods),
                            "--start-server", str(save), "--port", str(GAME_PORT),
                            "--rcon-port", str(RCON_PORT), "--rcon-password", PW,
                            "--server-settings", str(ROOT.parent / "calibration" / "vanilla-sweep" / "server-settings.json")],
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
        if c is None:
            print("no rcon"); sys.exit(1)
        c.s.settimeout(600)
        print(c.cmd(f"/tile-dump nauvis {radius}"))
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
