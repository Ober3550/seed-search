#!/usr/bin/env python3
"""Calibrate with full SE zone.controls dump + ore count.
Usage: python3 calibration/run-with-controls.py <surface_seed> <radius> <water>"""
import argparse, json, os, subprocess, sys, tempfile, time
from pathlib import Path

HERE = Path(__file__).resolve().parent; REPO = HERE.parent; HOME = Path.home()
DEFAULT_BIN = Path(os.environ.get("FACTORIO_BIN", "/Applications/factorio.app/Contents/MacOS/factorio"))
RESULTS_DIR = HERE / "results"

LUA_TEMPLATE = (
    'local ok,err=pcall(function()'
    'local R={"coal","stone","iron-ore","copper-ore","crude-oil","uranium-ore",'
    '"se-vulcanite","se-cryonite","se-vitamelange","se-holmium-ore",'
    '"se-beryllium-ore","se-iridium-ore","se-water-ice","se-methane-ice",'
    '"se-naquium-ore","kr-imersite","kr-rare-metal-ore","kr-mineral-water"};'
    'local k=%d;local s=game.surfaces["nauvis"];'
    'local a={{-k,-k},{k,k}};local wt=s.count_tiles_filtered{area=a,name="water"};'
    'local tt=(2*k)*(2*k);local lt=tt-wt;local c={};'
    'for _,e in pairs(s.find_entities_filtered{type="resource",area=a}) do '
    'local n=e.name;if not c[n] then c[n]={total=0,patches=0} end;'
    'c[n].total=c[n].total+e.amount;c[n].patches=c[n].patches+1 end;'
    'local zi=remote.call("space-exploration","get_zone_index",{});'
    'local pr={};for _,z in pairs(zi) do if z.child_indexes then '
    'for _,ci in pairs(z.child_indexes) do pr[ci]=z.name end end end;'
    'local zd={};for _,z in pairs(zi) do '
    'if z.controls and z.type~="star" and z.type~="orbit" then '
    'local ct={};for _,rn in pairs(R) do '
    'local x=z.controls[rn];'
    'if type(x)=="table" and x.frequency and x.size and x.richness then '
    'local fsr=x.frequency*x.size*x.richness;'
    'if fsr>0.001 then ct[rn]={f=x.frequency,s=x.size,r=x.richness,fsr=fsr} end end end;'
    'if next(ct) then zd[#zd+1]={name=z.name,type=z.type,index=z.index,'
    'radius=z.radius,seed=z.seed,parent_name=pr[z.index],controls=ct} end end end;'
    'local o={surface_seed=s.map_gen_settings.seed,radius=%d,water="%s",'
    'freq=%s,size=%s,rich=%s,total_tiles=tt,water_tiles=wt,land_tiles=lt,'
    'resources=c,zones_with_controls=zd};'
    'rcon.print(helpers.table_to_json(o))'
    'end);if not ok then rcon.print("ERROR: "..tostring(err)) end'
)

def log(msg): print(f"[calib-ctrl] {msg}", file=sys.stderr, flush=True)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("surface_seed", type=int)
    ap.add_argument("radius", type=int)
    ap.add_argument("water", choices=["none","low","med","high","max"])
    ap.add_argument("freq", nargs="?", type=float, default=1.0)
    ap.add_argument("size", nargs="?", type=float, default=1.0)
    ap.add_argument("rich", nargs="?", type=float, default=1.0)
    ap.add_argument("--factorio-bin", default=str(DEFAULT_BIN))
    ap.add_argument("--rcon-port", type=int, default=27717)
    ap.add_argument("--game-port", type=int, default=34717)
    ap.add_argument("--rcon-password", default="seedsearch")
    ap.add_argument("--keep-workdir", action="store_true")
    args = ap.parse_args()

    factorio_bin = Path(args.factorio_bin)
    if not factorio_bin.exists():
        log(f"Factorio not found: {factorio_bin}")
        return 2

    moisture_map = {"none": 1.0, "low": 0.5, "med": 0.0, "high": -0.5, "max": -1.0}
    mapgen = {
        "width": 0, "height": 0, "starting_area": 1, "peaceful_mode": True,
        "autoplace_controls": {
            "coal": {"frequency": str(args.freq), "size": str(args.size), "richness": str(args.rich)},
            "stone": {"frequency": str(args.freq), "size": str(args.size), "richness": str(args.rich)},
            "copper-ore": {"frequency": str(args.freq), "size": str(args.size), "richness": str(args.rich)},
            "iron-ore": {"frequency": str(args.freq), "size": str(args.size), "richness": str(args.rich)},
            "uranium-ore": {"frequency": "0.0", "size": "0.0", "richness": "0.0"},
            "crude-oil": {"frequency": "0.0", "size": "0.0", "richness": "0.0"},
        },
        "cliff_settings": {"name":"cliff","cliff_elevation_0":10,"cliff_elevation_interval":40,"richness":0},
        "property_expression_names": {"control:moisture:frequency":"1","control:moisture:bias":str(moisture_map[args.water])},
        "starting_points": [{"x":0,"y":0}],
        "seed": args.surface_seed,
    }

    workdir = Path(tempfile.mkdtemp(prefix="se-ctrl-"))
    (workdir / "map-gen-settings.json").write_text(json.dumps(mapgen))
    save_file = workdir / "calib.zip"

    sys.path.insert(0, str(REPO / "verifier" / "verify"))
    from rcon import wait_for_rcon, RconError

    server = None
    try:
        log(f"Creating save: seed={args.surface_seed} r={args.radius} w={args.water}")
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

        lua_code = LUA_TEMPLATE % (args.radius, args.radius, args.water, args.freq, args.size, args.rich)
        log("Dumping controls + counting...")
        response = client.command("/silent-command " + lua_code).strip()

        for _ in range(30):
            if response and response.startswith("{"):
                break
            time.sleep(0.5)
            response = client.command("/silent-command " + lua_code).strip()

        client.close()

        if not response or not response.startswith("{"):
            log(f"Bad RCON response: {response[:300]}")
            return 1

        data = json.loads(response)
        RESULTS_DIR.mkdir(parents=True, exist_ok=True)
        out_path = RESULTS_DIR / f"seed-{args.surface_seed}-r{args.radius}-controls.json"
        out_path.write_text(json.dumps(data, indent=2))
        log(f"Saved: {out_path}")

        res = data.get("resources", {})
        log(f"Land tiles: {data.get('land_tiles', 0):,}")
        for n, i in sorted(res.items(), key=lambda x: -x[1].get("total", 0)):
            log(f"  {n}: {i['total']:,} ({i['patches']} patches)")

        log("\nZone matching surface seed:")
        for z in data.get("zones_with_controls", []):
            if z["seed"] == args.surface_seed:
                log(f"  {z['name']} (type={z['type']}, r={z.get('radius','?')})")
                for rn, ctrl in sorted(z["controls"].items(), key=lambda x: -x[1].get("fsr",0)):
                    log(f"    {rn}: FSR={ctrl['fsr']:.3f} f={ctrl['f']:.3f} s={ctrl['s']:.3f} r={ctrl['r']:.3f}")
                break
        else:
            log("  (no zone matched surface seed - showing all zones)")
            for z in data.get("zones_with_controls", [])[:3]:
                log(f"  {z['name']}: seed={z['seed']}, radius={z.get('radius','?')}")

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
