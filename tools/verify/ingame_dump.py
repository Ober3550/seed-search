#!/usr/bin/env python3
"""Generate a real Space Exploration map for a seed and dump its universe.

Native macOS path (no docker): launches the installed Factorio app the same way
the factorio-ai bridge does — `--create` a save with the seed injected into
map-gen-settings (which runs SE's on_init universe generation), then
`--start-server` headless with RCON, and read SE's get_zone_index over RCON.

It uses Factorio's DEFAULT local mod directory
(~/Library/Application Support/factorio/mods), so whatever mods are enabled there
(SE, and here Krastorio2) determine the map. Run the finder side with a matching
mode (e.g. SE_ENABLE_K2=1 when K2 is enabled).

Prerequisites (override via flags/env):
  FACTORIO_BIN  path to the factorio executable
                (default: /Applications/factorio.app/Contents/MacOS/factorio)

Usage:
  tools/verify/ingame_dump.py <seed> [-o out.json]
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
REPO = HERE.parent.parent
HOME = Path.home()
DEFAULT_BIN = Path("/Applications/factorio.app/Contents/MacOS/factorio")
FACTORIO_DATA = HOME / "Library" / "Application Support" / "factorio"

# SE universe dump run via `/silent-command ... rcon.print(...)`. Mirrors
# tools/ingame-dump.lua but returns the JSON directly over RCON. Also captures
# each zone's resource controls (frequency/richness/size) for resource-data
# verification.
DUMP_LUA = (
    'local RES={"coal","stone","iron-ore","copper-ore","crude-oil","uranium-ore",'
    '"se-vulcanite","se-cryonite","se-vitamelange","se-holmium-ore","se-beryllium-ore","se-iridium-ore",'
    '"se-water-ice","se-methane-ice","se-naquium-ore","kr-imersite","kr-rare-metal-ore","kr-mineral-water"};'
    'local zones=remote.call("space-exploration","get_zone_index",{});'
    "local p={};for _,z in pairs(zones) do if z.child_indexes then "
    "for _,ci in pairs(z.child_indexes) do p[ci]=z.name end end end;"
    'local out={map_seed=game.surfaces["nauvis"].map_gen_settings.seed,zones={}};'
    "for _,z in pairs(zones) do "
    "local ctrls={}; if z.controls then for _,rn in pairs(RES) do local c=z.controls[rn]; "
    "if type(c)=='table' then ctrls[rn]={f=c.frequency,r=c.richness,s=c.size} end end end;"
    "out.zones[#out.zones+1]="
    "{name=z.name,type=z.type,index=z.index,radius=z.radius,seed=z.seed,parent=p[z.index],controls=ctrls} end;"
    "rcon.print(helpers.table_to_json(out))"
)

# A minimal map-gen-settings; only `seed` matters for SE's universe RNG. SE sizes
# Nauvis itself, so width/height are left at defaults.
MAP_GEN_TEMPLATE = {"seed": None}


def log(msg):
    print(f"[ingame_dump] {msg}", file=sys.stderr, flush=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("seed", type=int)
    ap.add_argument("-o", "--out")
    ap.add_argument("--factorio-bin", default=os.environ.get("FACTORIO_BIN", str(DEFAULT_BIN)))
    ap.add_argument("--rcon-port", type=int, default=int(os.environ.get("RCON_PORT", "27717")))
    ap.add_argument("--game-port", type=int, default=int(os.environ.get("GAME_PORT", "34717")))
    ap.add_argument("--rcon-password", default=os.environ.get("RCON_PASSWORD", "seedsearch"))
    ap.add_argument("--keep-workdir", action="store_true")
    args = ap.parse_args()

    factorio_bin = Path(args.factorio_bin)
    out_path = Path(args.out or (REPO / f"universe-ingame-{args.seed}.json"))

    if not factorio_bin.exists():
        log(f"Factorio binary not found: {factorio_bin} (set FACTORIO_BIN)")
        return 2
    mods_dir = FACTORIO_DATA / "mods"
    if not any(mods_dir.glob("space-exploration_*")):
        log(f"Space Exploration not found in the local mod dir {mods_dir}")
        return 2

    sys.path.insert(0, str(HERE))
    from rcon import wait_for_rcon, RconError  # noqa: E402

    workdir = Path(tempfile.mkdtemp(prefix="se-verify-"))
    save_file = workdir / "verify.zip"
    mapgen_file = workdir / "map-gen-settings.json"
    mapgen = dict(MAP_GEN_TEMPLATE)
    mapgen["seed"] = args.seed
    mapgen_file.write_text(json.dumps(mapgen))

    server = None
    try:
        log(f"Creating save for seed {args.seed} (runs SE universe generation; loads all mods)...")
        subprocess.run(
            [str(factorio_bin), "--create", str(save_file), "--map-gen-settings", str(mapgen_file)],
            check=True, timeout=600,
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
        client = wait_for_rcon("127.0.0.1", args.rcon_port, args.rcon_password, deadline_s=240)

        active = client.command('/silent-command rcon.print(table.concat({"K2="..tostring(script.active_mods["Krastorio2"] or "no"),"SA="..tostring(script.active_mods["space-age"] or "no")}, " "))').strip()
        seed_back = client.command('/silent-command rcon.print(game.surfaces["nauvis"].map_gen_settings.seed)').strip()
        log(f"Server: map seed={seed_back}, mods: {active}")

        log("Dumping SE universe via remote interface...")
        payload = client.command("/silent-command " + DUMP_LUA).strip()
        client.close()

        if not payload or payload[0] != "{":
            log("Unexpected RCON response (is Space Exploration active?):")
            log(payload[:500])
            return 1
        data = json.loads(payload)
        out_path.write_text(json.dumps(data))
        log(f"Wrote {len(data.get('zones', []))} zones to {out_path}")
        print(out_path)
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
