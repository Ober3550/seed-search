#!/usr/bin/env python3
"""Calibrate on a specific SE zone surface (not Nauvis).

Finds a zone by name, creates its surface via SE's Zone.get_make_surface(),
generates the area, and counts all resource entities.

Usage:
  python3 calibration/run-zone.py <zone_name> <universe_seed> <radius>
"""
import argparse, json, os, subprocess, sys, tempfile, time
from pathlib import Path

HERE = Path(__file__).resolve().parent; REPO = HERE.parent; HOME = Path.home()
DEFAULT_BIN = Path(os.environ.get("FACTORIO_BIN", "/Applications/factorio.app/Contents/MacOS/factorio"))
RESULTS_DIR = HERE / "results"

LUA = (
    'local function doit()'
    'local zone=remote.call("space-exploration","get_zone_from_name",{zone_name="%s"});'
    'if not zone then rcon.print("ZONE_NOT_FOUND");return end;'
    # Create surface manually (bypass buggy Zone.create_surface on Factorio 2.0)
    'local s=nil;'
    'if zone.surface_index then s=game.get_surface(zone.surface_index) end;'
    'if not s then '
    'local mgs=game.default_map_gen_settings or {};'
    'mgs.seed=zone.seed or %d;'
    'mgs.width=0;mgs.height=0;'
    'mgs.autoplace_controls=mgs.autoplace_controls or {};'
    'if zone.radius then mgs.width=zone.radius*2+32;mgs.height=zone.radius*2+32 end;'
    'game.create_surface(zone.name,mgs);'
    's=game.get_surface(zone.name);'
    'if s then zone.surface_index=s.index end;'
    'end;'
    'if not s then rcon.print("NO_SURFACE");return end;'
    'local r=%d;'
    's.request_to_generate_chunks({0,0},math.ceil(r/32)+1);'
    's.force_generate_chunk_requests();'
    'local a={{-r,-r},{r,r}};'
    'local wt=s.count_tiles_filtered{area=a,name="water"};'
    'local tt=(2*r)*(2*r);local lt=tt-wt;local c={};'
    'for _,e in pairs(s.find_entities_filtered{type="resource",area=a}) do '
    'local n=e.name;if not c[n] then c[n]={total=0,patches=0} end;'
    'c[n].total=c[n].total+e.amount;c[n].patches=c[n].patches+1 end;'
    'local o={zone_name="%s",universe_seed=%d,surface_seed=zone.seed,radius=r,'
    'surface_name=s.name,total_tiles=tt,water_tiles=wt,land_tiles=lt,resources=c};'
    'rcon.print(helpers.table_to_json(o))'
    'end;local ok,err=pcall(doit);if not ok then rcon.print("ERROR: "..tostring(err)) end'
)

def log(msg): print(f"[calib-zone] {msg}", file=sys.stderr, flush=True)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("zone_name")
    ap.add_argument("universe_seed", type=int)
    ap.add_argument("radius", type=int)
    ap.add_argument("--factorio-bin", default=str(DEFAULT_BIN))
    ap.add_argument("--rcon-port", type=int, default=27717)
    ap.add_argument("--game-port", type=int, default=34717)
    ap.add_argument("--rcon-password", default="seedsearch")
    ap.add_argument("--keep-workdir", action="store_true")
    args = ap.parse_args()

    factorio_bin = Path(args.factorio_bin)
    if not factorio_bin.exists():
        log(f"Factorio not found: {factorio_bin}"); return 2

    mapgen = {"seed": args.universe_seed}

    workdir = Path(tempfile.mkdtemp(prefix="se-zone-"))
    (workdir / "map-gen-settings.json").write_text(json.dumps(mapgen))
    save_file = workdir / "calib.zip"

    sys.path.insert(0, str(REPO / "verifier" / "verify"))
    from rcon import wait_for_rcon, RconError

    server = None
    try:
        log(f"Creating SE universe for seed {args.universe_seed}...")
        subprocess.run(
            [str(factorio_bin), "--create", str(save_file), "--map-gen-settings", str(workdir / "map-gen-settings.json")],
            check=True, timeout=300, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )

        log("Starting headless server...")
        server = subprocess.Popen(
            [str(factorio_bin), "--start-server", str(save_file),
             "--port", str(args.game_port), "--rcon-port", str(args.rcon_port),
             "--rcon-password", args.rcon_password],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )

        log("Waiting for RCON...")
        client = wait_for_rcon("127.0.0.1", args.rcon_port, args.rcon_password)

        lua_code = LUA % (args.zone_name, args.universe_seed, args.radius, args.zone_name, args.universe_seed)
        log(f"Creating surface for zone '{args.zone_name}' r={args.radius}...")
        response = client.command("/silent-command " + lua_code).strip()

        for _ in range(60):  # surface generation can take a while
            if response and response.startswith("{"):
                break
            if response and "ZONE_NOT_FOUND" in response:
                log(f"Zone '{args.zone_name}' not found in universe")
                client.close(); return 1
            if response and "SURFACE_FAILED" in response:
                log("Surface creation failed")
                client.close(); return 1
            if response and "ERROR:" in response:
                log(f"Lua error: {response}")
                client.close(); return 1
            time.sleep(1)
            response = client.command("/silent-command " + lua_code).strip()

        client.close()

        if not response or not response.startswith("{"):
            log(f"Bad response: {response[:300]}")
            return 1

        data = json.loads(response)
        RESULTS_DIR.mkdir(parents=True, exist_ok=True)
        out_path = RESULTS_DIR / f"zone-{args.zone_name}-r{args.radius}.json"
        out_path.write_text(json.dumps(data, indent=2))
        log(f"Saved: {out_path}")

        res = data.get("resources", {})
        log(f"Land tiles: {data.get('land_tiles', 0):,}")
        for n, i in sorted(res.items(), key=lambda x: -x[1].get("total", 0)):
            log(f"  {n}: {i['total']:,} ({i['patches']} patches)")

        print(str(out_path))
        return 0
    except Exception as e:
        log(f"FAILED: {e}")
        import traceback; traceback.print_exc()
        return 1
    finally:
        if server and server.poll() is None:
            server.terminate()
            try: server.wait(timeout=15)
            except: server.kill()
        if not args.keep_workdir:
            import shutil; shutil.rmtree(workdir, ignore_errors=True)

if __name__ == "__main__":
    sys.exit(main())
