#!/usr/bin/env python3
"""Find the Nauvis starting lake in the live game for a seed: force-generate a
small area around spawn, flood-find the nearest water body to (0,0), and report
its centroid + size, plus any starting-lake fields in map_gen_settings.
Usage: starting_lake_game.py <map_seed>
"""
import json, os, shutil, subprocess, sys, tempfile, time
from pathlib import Path

HERE = Path(__file__).resolve().parent
HOME = Path.home()
DEFAULT_BIN = Path("/Applications/factorio.app/Contents/MacOS/factorio")
FACTORIO_DATA = HOME / "Library" / "Application Support" / "factorio"


def log(m): print(f"[start-lake] {m}", file=sys.stderr, flush=True)


def main():
    seed = int(sys.argv[1])
    rcon_port, game_port, pw = 27723, 34723, "seedsearch"
    bin_ = Path(os.environ.get("FACTORIO_BIN", str(DEFAULT_BIN)))
    sys.path.insert(0, str(HERE))
    from rcon import wait_for_rcon, RconError
    wd = Path(tempfile.mkdtemp(prefix="se-slake-"))
    save = wd / "v.zip"; mg = wd / "mgs.json"
    t = json.loads((HERE / "se-map-gen-template.json").read_text()); t["seed"] = seed
    for k in ("autoplace_controls", "autoplace_settings"):
        d = t.get(k)
        if isinstance(d, dict):
            t[k] = {kk: v for kk, v in d.items() if not kk.startswith("kr-")}
    mg.write_text(json.dumps(t))
    srv = None
    try:
        subprocess.run([str(bin_), "--create", str(save), "--map-gen-settings", str(mg)], check=True, timeout=600)
        srv = subprocess.Popen([str(bin_), "--start-server", str(save), "--port", str(game_port),
                                "--rcon-port", str(rcon_port), "--rcon-password", pw],
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        c = wait_for_rcon("127.0.0.1", rcon_port, pw, deadline_s=240)
        c.command('/silent-command rcon.print("warmup")'); c.command('/silent-command rcon.print("ready")')
        try: c._sock.settimeout(900)
        except Exception: pass
        # generate a 400-tile radius around spawn, then aggregate water tiles.
        c.command('/silent-command local s=game.surfaces["nauvis"];for cx=-13,13 do for cy=-13,13 do s.request_to_generate_chunks({cx*32,cy*32},0) end end;s.force_generate_chunk_requests();rcon.print("GEN")')
        lua = (
            'local s=game.surfaces["nauvis"];local R=400;'
            'local ts=s.find_tiles_filtered{area={{-R,-R},{R,R}},limit=4000000};'
            'local wx,wy,wn=0,0,0; local minx,maxx,miny,maxy=1e9,-1e9,1e9,-1e9;'
            'local nearest,nd=nil,1e9;'
            'for _,t in pairs(ts) do local n=t.name; if n:find("water") or n:find("deepwater") then '
            '  local x=t.position.x; local y=t.position.y; wn=wn+1; wx=wx+x; wy=wy+y;'
            '  if x<minx then minx=x end; if x>maxx then maxx=x end; if y<miny then miny=y end; if y>maxy then maxy=y end;'
            '  local d=x*x+y*y; if d<nd then nd=d; nearest={x,y} end end end;'
            'local mgs=s.map_gen_settings;'
            'rcon.print(string.format("WATER n=%d centroid=%.1f,%.1f bbox=%.0f,%.0f..%.0f,%.0f nearest_to_spawn=%s dist=%.1f water_scale=%s water_level=%s",'
            '  wn, (wn>0 and wx/wn or 0),(wn>0 and wy/wn or 0), minx,miny,maxx,maxy,'
            '  nearest and (nearest[1]..","..nearest[2]) or "none", math.sqrt(nd),'
            '  tostring(mgs.water and mgs.water or "?"), tostring(mgs.property_expression_names and mgs.property_expression_names["elevation"] or "")))'
        )
        r = c.command("/silent-command " + lua).strip()
        log(r)
        c.close()
        print(r)
        return 0
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, RconError) as e:
        log(f"FAILED: {e}"); return 1
    finally:
        if srv and srv.poll() is None:
            srv.terminate()
            try: srv.wait(timeout=15)
            except subprocess.TimeoutExpired: srv.kill()
        shutil.rmtree(wd, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
