#!/usr/bin/env python3
"""Calibrate resource estimates by counting ores on a locally-running Factorio.

Creates a save with the given surface seed + water setting, starts a headless
server, and counts all resource entities via RCON. Uses the user's local mod
directory (SE + optionally K2 already installed).

Usage:
  calibration/run-local.sh <surface_seed> <radius> <water> [freq] [size] [rich] [--k2]

Or directly:
  python3 calibration/run-local.py <surface_seed> <radius> <water> [freq] [size] [rich] [--k2]
"""
import argparse
import json
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parent
HOME = Path.home()
DEFAULT_BIN = Path(os.environ.get("FACTORIO_BIN", "/Applications/factorio.app/Contents/MacOS/factorio"))
FACTORIO_DATA = HOME / "Library" / "Application Support" / "factorio"
RESULTS_DIR = HERE / "results"

# Lua to count all resource entities in a square area and write JSON
COUNT_LUA_TEMPLATE = """\
local RADIUS = {radius}
local WATER = "{water}"
local FREQ = {freq}
local SIZE = {size}
local RICH = {rich}

if not global then global = {{}} end
if global.done then rcon.print("ALREADY_DONE") return end

local surface = game.surfaces["nauvis"]
local half = RADIUS
local area = {{{{-half, -half}}, {{half, half}}}}

local water_tiles = surface.count_tiles_filtered{{area=area, name="water"}}
local total_tiles = (2 * half) * (2 * half)
local land_tiles = total_tiles - water_tiles

local counts = {{}}
local entities = surface.find_entities_filtered{{type="resource", area=area}}
for _, e in pairs(entities) do
    local n = e.name
    if not counts[n] then counts[n] = {{total = 0, patches = 0}} end
    counts[n].total = counts[n].total + e.amount
    counts[n].patches = counts[n].patches + 1
end

local result = {{
    seed = surface.map_gen_settings.seed,
    radius = RADIUS,
    water = WATER,
    freq = FREQ,
    size = SIZE,
    rich = RICH,
    total_tiles = total_tiles,
    water_tiles = water_tiles,
    land_tiles = land_tiles,
    resources = counts
}}

rcon.print(helpers.table_to_json(result))
global.done = true
"""


def log(msg):
    print(f"[calibrate] {msg}", file=sys.stderr, flush=True)


def wait_for_rcon(host, port, password, deadline_s=240.0, poll_s=3.0):
    """Poll until authenticated RCON connection succeeds."""
    sys.path.insert(0, str(REPO / "verifier" / "verify"))
    from rcon import RconClient, RconError
    start = time.time()
    last_err = None
    while time.time() - start < deadline_s:
        try:
            c = RconClient(host, port, password, timeout=10.0)
            c.connect()
            return c
        except (OSError, RconError) as e:
            last_err = e
            time.sleep(poll_s)
    raise RuntimeError(f"RCON not ready after {deadline_s}s: {last_err}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("surface_seed", type=int)
    ap.add_argument("radius", type=int)
    ap.add_argument("water", choices=["none", "low", "med", "high", "max"])
    ap.add_argument("freq", nargs="?", type=float, default=1.0)
    ap.add_argument("size", nargs="?", type=float, default=1.0)
    ap.add_argument("rich", nargs="?", type=float, default=1.0)
    ap.add_argument("--k2", action="store_true")
    ap.add_argument("--factorio-bin", default=str(DEFAULT_BIN))
    ap.add_argument("--rcon-port", type=int, default=27717)
    ap.add_argument("--game-port", type=int, default=34717)
    ap.add_argument("--rcon-password", default="seedsearch")
    ap.add_argument("--keep-workdir", action="store_true")
    args = ap.parse_args()

    factorio_bin = Path(args.factorio_bin)
    if not factorio_bin.exists():
        log(f"Factorio binary not found: {factorio_bin} (set FACTORIO_BIN)")
        return 2

    mods_dir = FACTORIO_DATA / "mods"
    if not any(mods_dir.glob("space-exploration_*")):
        log(f"Space Exploration not found in {mods_dir}")
        return 2

    # Moisture bias mapping
    moisture_map = {"none": 1.0, "low": 0.5, "med": 0.0, "high": -0.5, "max": -1.0}
    moisture_bias = moisture_map[args.water]

    # Build map-gen-settings
    mapgen = {
        "width": 0,
        "height": 0,
        "starting_area": 1,
        "peaceful_mode": True,
        "autoplace_controls": {
            "coal": {"frequency": str(args.freq), "size": str(args.size), "richness": str(args.rich)},
            "stone": {"frequency": str(args.freq), "size": str(args.size), "richness": str(args.rich)},
            "copper-ore": {"frequency": str(args.freq), "size": str(args.size), "richness": str(args.rich)},
            "iron-ore": {"frequency": str(args.freq), "size": str(args.size), "richness": str(args.rich)},
            "uranium-ore": {"frequency": "0.0", "size": "0.0", "richness": "0.0"},
            "crude-oil": {"frequency": "0.0", "size": "0.0", "richness": "0.0"},
            "water": {"frequency": 1, "size": "0.0"},
            "trees": {"frequency": 1, "size": 1},
            "enemy-base": {"frequency": 0, "size": 0},
        },
        "cliff_settings": {"name": "cliff", "cliff_elevation_0": 10, "cliff_elevation_interval": 40, "richness": 0},
        "property_expression_names": {
            "control:moisture:frequency": "1",
            "control:moisture:bias": str(moisture_bias),
        },
        "starting_points": [{"x": 0, "y": 0}],
        "seed": args.surface_seed,
    }

    workdir = Path(tempfile.mkdtemp(prefix="se-calib-"))
    save_file = workdir / "calib.zip"
    mapgen_file = workdir / "map-gen-settings.json"
    mapgen_file.write_text(json.dumps(mapgen))

    sys.path.insert(0, str(REPO / "verifier" / "verify"))
    from rcon import RconError

    server = None
    try:
        log(f"Creating save: seed={args.surface_seed} r={args.radius} water={args.water}")
        subprocess.run(
            [str(factorio_bin), "--create", str(save_file), "--map-gen-settings", str(mapgen_file)],
            check=True, timeout=300,
        )

        log(f"Starting headless server (game :{args.game_port}, RCON :{args.rcon_port})...")
        server = subprocess.Popen(
            [str(factorio_bin), "--start-server", str(save_file),
             "--port", str(args.game_port),
             "--rcon-port", str(args.rcon_port),
             "--rcon-password", args.rcon_password],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )

        log("Waiting for RCON...")
        client = wait_for_rcon("127.0.0.1", args.rcon_port, args.rcon_password)

        # Verify SE is loaded
        active = client.command(
            '/silent-command rcon.print(table.concat({"SE="..tostring(script.active_mods["space-exploration"] or "no"),'
            '"K2="..tostring(script.active_mods["Krastorio2"] or "no")}, " "))'
        ).strip()
        log(f"Mods active: {active}")

        # Count resources
        lua_code = COUNT_LUA_TEMPLATE.format(
            radius=args.radius,
            water=args.water,
            freq=args.freq,
            size=args.size,
            rich=args.rich,
        )
        log("Counting resources...")
        response = client.command("/silent-command " + lua_code).strip()

        # Factorio RCON may need a few ticks to process
        for attempt in range(30):
            if response and response.startswith("{"):
                break
            time.sleep(0.5)
            response = client.command("/silent-command " + lua_code).strip()

        client.close()

        if not response or not response.startswith("{"):
            log(f"Unexpected response: {response[:200]}")
            return 1

        data = json.loads(response)
        RESULTS_DIR.mkdir(parents=True, exist_ok=True)

        # Save with FSR tag
        fsr_tag = f"f{args.freq}-s{args.size}-r{args.rich}"
        out_path = RESULTS_DIR / f"seed-{args.surface_seed}-r{args.radius}-{fsr_tag}.json"
        out_path.write_text(json.dumps(data, indent=2))
        log(f"Saved: {out_path}")

        # Print summary
        resources = data.get("resources", {})
        log(f"Land tiles: {data.get('land_tiles', 0):,}")
        if resources:
            for name, info in sorted(resources.items(), key=lambda x: -x[1].get("total", 0)):
                log(f"  {name}: {info['total']:,} ({info['patches']} patches)")
        else:
            log("No resources found!")

        print(str(out_path))
        return 0

    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, RconError, json.JSONDecodeError) as e:
        log(f"FAILED: {e}")
        return 1
    finally:
        if server and server.poll() is None:
            server.terminate()
            try:
                server.wait(timeout=15)
            except subprocess.TimeoutExpired:
                server.kill()
        if args.keep_workdir:
            log(f"workdir kept: {workdir}")
        else:
            import shutil
            shutil.rmtree(workdir, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
