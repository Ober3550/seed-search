#!/usr/bin/env python3
"""Live-game oracle for a Space Exploration zone surface.

Boots a headless game with the Space Exploration mod set at the given map
seed, lets SE create the zone's surface the way it does when a player first
reaches it (remote zone_get_make_surface), and dumps

  * the zone as SE sees it (seed, radius, tags, controls)
  * the surface's map_gen_settings (what SE's Zone.create_surface built)
  * every tile of a rectangle (names, row-major) and every entity in it

Usage:
  probe_se_zone.py <seed> <zone name> <x0:x1:y0:y1> <out.json>
                   [--mods-dir DIR] [--names a,b,c]

Without --mods-dir a mod directory is assembled from the Factorio user mod
folder (SE and its required mods, no Krastorio 2). --names adds named noise
expressions sampled on every 8th tile (calculate_tile_properties).

Output JSON: {"zone":{...}, "map_gen_settings":{...}, "rect":[x0,x1,y0,y1],
              "tile_names":[...], "tiles":[index per tile, rows y0..y1-1],
              "entities":[{"n","x","y","a"}], "values":{name:[...]}}
"""
import argparse, json, os, shutil, subprocess, sys, time
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
FACTORIO = os.environ.get("FACTORIO_BIN", "/Applications/factorio.app/Contents/MacOS/factorio")
USER_MODS = Path(os.environ.get("FACTORIO_MODS", Path.home() / "Library/Application Support/factorio/mods"))
RCON_PORT, GAME_PORT = 25733, 34333
PW = "seprobe"
SE_MODS = ["space-exploration", "space-exploration-graphics", "space-exploration-graphics-2",
           "space-exploration-graphics-3", "space-exploration-graphics-4", "space-exploration-graphics-5",
           "space-exploration-menu-simulations", "space-exploration-postprocess", "aai-containers",
           "aai-industry", "aai-signal-transmission", "alien-biomes", "alien-biomes-graphics", "jetpack",
           "robot_attrition", "shield-projector", "informatron", "flib"]

sys.path.insert(0, str(HERE))
from probe_ops import Rcon  # noqa: E402
from probe_surface import sandbox, run  # noqa: E402


def se_mods_dir(dst):
    """A mod directory holding SE and what it needs, linked from the user's."""
    dst.mkdir(parents=True, exist_ok=True)
    mods = [{"name": "base", "enabled": True}] + [
        {"name": n, "enabled": False} for n in ("elevated-rails", "quality", "space-age")]
    for name in SE_MODS:
        hits = sorted(USER_MODS.glob(name + "_*.zip"))
        if not hits:
            if name == "flib":
                continue
            sys.exit(f"mod {name} not found in {USER_MODS}")
        link = dst / hits[-1].name
        if not link.exists():
            os.symlink(hits[-1], link)
        mods.append({"name": name, "enabled": True})
    (dst / "mod-list.json").write_text(json.dumps({"mods": mods}))
    return dst


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("seed", type=int); ap.add_argument("zone")
    ap.add_argument("rect"); ap.add_argument("out")
    ap.add_argument("--mods-dir"); ap.add_argument("--names", default="")
    a = ap.parse_args()
    x0, x1, y0, y1 = (int(v) for v in a.rect.split(":"))
    names = [n for n in a.names.split(",") if n]

    made = None
    if not a.mods_dir:
        made = Path(os.environ.get("TMPDIR", "/tmp")) / f"se-mods-{os.getpid()}"
        a.mods_dir = str(se_mods_dir(made))
    tmp = sandbox(a.mods_dir)
    srv = None
    try:
        # SE's Zone.create_surface copies game.default_map_gen_settings, which
        # has no autoplace_controls when the save is made from a bare seed
        mgs = json.loads((ROOT / "verifier" / "verify" / "se-map-gen-template.json").read_text())
        mgs["seed"] = a.seed
        mgs["autoplace_controls"] = {k: v for k, v in mgs["autoplace_controls"].items() if not k.startswith("kr-")}
        (tmp / "mgs.json").write_text(json.dumps(mgs))
        save = tmp / "probe.zip"
        r = run(tmp, "--create", str(save), "--map-gen-settings", str(tmp / "mgs.json"))
        if not save.exists():
            sys.exit("create failed:\n" + r.stdout[-3000:])
        (tmp / "server-settings.json").write_text((HERE / "server-settings.json").read_text())
        srv = subprocess.Popen([FACTORIO, "--config", str(tmp / "config.ini"),
                                "--mod-directory", str(tmp / "mods"),
                                "--start-server", str(save), "--port", str(GAME_PORT),
                                "--rcon-port", str(RCON_PORT), "--rcon-password", PW,
                                "--server-settings", str(tmp / "server-settings.json")],
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        c = None
        for _ in range(600):
            if srv.poll() is not None:
                sys.exit("server died:\n" + (tmp / "write" / "factorio-current.log").read_text()[-3000:])
            try:
                c = Rcon("127.0.0.1", RCON_PORT, PW, timeout=10); break
            except OSError:
                time.sleep(1)
        if c is None:
            sys.exit("no rcon")
        c.s.settimeout(1800)
        c.cmd('/silent-command rcon.print("warmup")')
        c.cmd('/silent-command rcon.print("warmup")')
        scr = tmp / "write" / "script-output"
        Z = a.zone.replace("'", "\\'")
        resp = c.cmd("/silent-command "
                     f"local z=remote.call('space-exploration','get_zone_from_name',{{zone_name='{Z}'}}) "
                     "if not z then rcon.print('NOZONE') return end "
                     "remote.call('space-exploration','zone_get_make_surface',{zone_index=z.index}) "
                     f"z=remote.call('space-exploration','get_zone_from_name',{{zone_name='{Z}'}}) "
                     "local s=game.surfaces[z.surface_index] "
                     "local o={name=z.name,type=z.type,seed=z.seed,radius=z.radius,tags=z.tags,controls=z.controls,"
                     "primary_resource=z.primary_resource,surface=s.name,index=z.index} "
                     "helpers.write_file('z.json',helpers.table_to_json({zone=o,map_gen_settings=s.map_gen_settings}),false) "
                     "rcon.print('ok '..s.name)").strip()
        if not resp.startswith("ok"):
            sys.exit("zone surface not created: " + resp[:500])
        out = json.loads((scr / "z.json").read_text())
        surf = out["zone"]["surface"].replace("'", "\\'")
        S = f"local s=game.surfaces['{surf}'] "
        cx0, cx1, cy0, cy1 = x0 // 32 - 1, (x1 - 1) // 32 + 1, y0 // 32 - 1, (y1 - 1) // 32 + 1
        c.cmd("/silent-command " + S + f"for cy={cy0},{cy1} do for cx={cx0},{cx1} do "
              "s.request_to_generate_chunks({cx*32+16,cy*32+16},0) end end s.force_generate_chunk_requests() rcon.print('gen')")
        # let SE's own chunk handlers run before freezing the simulation
        time.sleep(5)
        c.cmd('/silent-command game.tick_paused=true rcon.print("paused")')
        out["rect"] = [x0, x1, y0, y1]
        c.cmd("/silent-command " + S + "local ids,names,o={},{},{} "
              f"for y={y0},{y1 - 1} do for x={x0},{x1 - 1} do local n=s.get_tile(x,y).name local i=ids[n] "
              "if not i then names[#names+1]=n i=#names ids[n]=i end o[#o+1]=i-1 end end "
              "helpers.write_file('t.txt',table.concat(names,',')..'\\n'..table.concat(o,','),false) rcon.print('ok')")
        tn, tv = (scr / "t.txt").read_text().split("\n")
        out["tile_names"] = tn.split(",")
        out["tiles"] = [int(v) for v in tv.split(",")]
        c.cmd("/silent-command " + S + "local o={} "
              f"for _,e in pairs(s.find_entities_filtered{{area={{{{{x0},{y0}}},{{{x1},{y1}}}}}}}) do "
              "if e.type~='character' then o[#o+1]=string.format('%s %.4f %.4f %d',e.type=='cliff' and (e.name..'@'..e.cliff_orientation) or e.name,"
              "e.position.x,e.position.y,e.type=='resource' and e.amount or 0) end end "
              "helpers.write_file('e.txt',table.concat(o,'\\n'),false) rcon.print('ok')")
        ents = []
        for l in (scr / "e.txt").read_text().splitlines():
            n, x, y, am = l.rsplit(" ", 3)
            ents.append({"n": n, "x": float(x), "y": float(y), "a": int(am)})
        out["entities"] = ents
        out["values"] = {}
        out["grid"] = [x0, x1 - 1, y0, y1 - 1, 8]
        pre = S + f"local P={{}} for y={y0},{y1 - 1},8 do for x={x0},{x1 - 1},8 do P[#P+1]={{x,y}} end end "
        for nm in names:
            resp = c.cmd("/silent-command " + pre +
                         f"local ok,v=pcall(function() return s.calculate_tile_properties({{'{nm}'}},P) end) "
                         f"if not ok then rcon.print('ERR '..tostring(v)) return end "
                         f"local a=v['{nm}'] local o={{}} for k=1,#a do o[k]=string.format('%.9g',a[k]) end "
                         f"helpers.write_file('v.txt',table.concat(o,','),false) rcon.print('ok '..#a)").strip()
            if resp.startswith("ok"):
                out["values"][nm] = [float(t) for t in (scr / "v.txt").read_text().split(",")]
            else:
                print("  FAILED", nm, resp[:200])
        Path(a.out).write_text(json.dumps(out))
        print(f"wrote {a.out}: zone {out['zone']['name']} seed {out['zone']['seed']} radius {out['zone']['radius']:.1f}, "
              f"{len(out['tiles'])} tiles ({len(out['tile_names'])} kinds), {len(ents)} entities")
    finally:
        if srv and srv.poll() is None:
            srv.terminate()
            try: srv.wait(timeout=20)
            except subprocess.TimeoutExpired: srv.kill()
        shutil.rmtree(tmp, ignore_errors=True)
        if made:
            shutil.rmtree(made, ignore_errors=True)


if __name__ == "__main__":
    main()
