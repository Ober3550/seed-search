#!/usr/bin/env python3
"""Live-game oracle for a whole Space Age planet surface.

Boots a headless 2.0 game (base + space-age) at the
given seed, creates the planet's surface from its prototype
(game.planets[p].create_surface()), then over a tile grid dumps

  * any set of named noise expressions via calculate_tile_properties (every
    registered noise-expression name is accepted, not just the property slots)
  * the generated tile names (get_tile), optionally

so the Zig generator can be diffed expression by expression against the game.

Usage:
  probe_surface.py <planet> <seed> <x0:x1:y0:y1:step> <out.json>
                   [--names a,b,c | --names-file f] [--tiles] [--entities]
                   [--mods-dir DIR] [--surface NAME]

Output JSON: {"planet","seed","grid":[x0,x1,y0,y1,step],
              "values":{name:[...row-major (y outer, x inner)...]},
              "tiles":[...names, same order...],
              "entities":[{"n":name,"x":..,"y":..,"a":amount}, ...]}
Probe positions are the integer tile coordinates (x, y): tile generation
evaluates each tile at its top-left corner, not its centre.
"""
import argparse, json, os, shutil, subprocess, sys, tempfile, time, zlib
from pathlib import Path

HERE = Path(__file__).resolve().parent
FACTORIO = os.environ.get("FACTORIO_BIN", "/Applications/factorio.app/Contents/MacOS/factorio")
DATA = os.environ.get("FACTORIO_DATA", "/Applications/factorio.app/Contents/data")
RCON_PORT, GAME_PORT = 25731, 34331
PW = "saprobe"
MODLIST = {"mods": [{"name": n, "enabled": True} for n in ("base", "quality", "elevated-rails", "space-age")]}

sys.path.insert(0, str(HERE))
from probe_ops import Rcon  # noqa: E402


def sandbox(mods_dir=None):
    """Throwaway config + mod directory. `mods_dir`: an existing mod directory
    (zips + mod-list.json, e.g. a Space Exploration set) to use instead of the
    base + Space Age list; its files are linked, never modified."""
    tmp = Path(tempfile.mkdtemp(prefix="sa-surface-"))
    (tmp / "mods").mkdir()
    (tmp / "write").mkdir()
    if mods_dir:
        for f in Path(mods_dir).iterdir():
            if f.name == "mod-list.json":
                shutil.copy(f, tmp / "mods" / f.name)
            elif f.suffix == ".zip" or f.is_dir():
                os.symlink(f.resolve(), tmp / "mods" / f.name)
    else:
        (tmp / "mods" / "mod-list.json").write_text(json.dumps(MODLIST))
    (tmp / "config.ini").write_text(f"[path]\nread-data={DATA}\nwrite-data={tmp / 'write'}\n")
    return tmp


def run(tmp, *args, **kw):
    return subprocess.run([FACTORIO, "--config", str(tmp / "config.ini"),
                           "--mod-directory", str(tmp / "mods"), *args],
                          capture_output=True, text=True, timeout=900, **kw)


def dump_data(tmp):
    r = run(tmp, "--dump-data")
    p = tmp / "write" / "script-output" / "data-raw-dump.json"
    if not p.exists():
        sys.exit("dump-data failed:\n" + r.stdout[-2000:])
    return json.loads(p.read_text())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("planet"); ap.add_argument("seed", type=int)
    ap.add_argument("grid"); ap.add_argument("out")
    ap.add_argument("--names", default=""); ap.add_argument("--names-file")
    ap.add_argument("--tiles", action="store_true")
    ap.add_argument("--entities", action="store_true")
    ap.add_argument("--mods-dir", help="mod directory to run with (default: base + Space Age)")
    ap.add_argument("--surface", help="existing surface name to probe instead of creating the planet's")
    a = ap.parse_args()
    x0, x1, y0, y1, step = (int(v) for v in a.grid.split(":"))
    names = [n for n in a.names.split(",") if n]
    if a.names_file:
        names += [l.strip() for l in open(a.names_file) if l.strip()]

    tmp = sandbox(a.mods_dir)
    srv = None
    try:
        # the map itself is plain Nauvis at this seed; the planet surface is
        # created at runtime from the planet prototype (--map-gen-settings
        # ignores autoplace_settings, so it cannot stand in for a planet).
        mgs = {"seed": a.seed}
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
        for _ in range(300):
            if srv.poll() is not None:
                sys.exit("server died")
            try:
                c = Rcon("127.0.0.1", RCON_PORT, PW, timeout=10); break
            except OSError:
                time.sleep(1)
        if c is None:
            sys.exit("no rcon")
        c.s.settimeout(900)
        c.cmd('/silent-command rcon.print("warmup")')
        if a.surface:
            resp = c.cmd(f"/silent-command local s=game.surfaces['{a.surface}'] "
                         f"rcon.print(s.name..' seed='..s.map_gen_settings.seed)").strip()
            print("surface:", resp)
            a.planet = a.surface
        else:
            resp = c.cmd(f"/silent-command local p=game.planets['{a.planet}'] local s=p.surface or p.create_surface() "
                         f"rcon.print(s.name..' seed='..s.map_gen_settings.seed)").strip()
            print("surface:", resp)
            # a planet surface's seed is the map seed + crc32(planet name)
            want = a.seed if a.planet == "nauvis" else (a.seed + zlib.crc32(a.planet.encode())) & 0xFFFFFFFF
            if not resp.endswith(f"seed={want}"):
                sys.exit(f"unexpected planet surface seed (expected {want})")
        pre = (f"local s=game.surfaces['{a.planet}'] local P={{}} "
               f"for y={y0},{y1},{step} do for x={x0},{x1},{step} do P[#P+1]={{x,y}} end end ")
        out = {"planet": a.planet, "seed": a.seed, "grid": [x0, x1, y0, y1, step], "values": {}}
        scr = tmp / "write" / "script-output"
        bad = []
        for i in range(0, len(names), 8):
            chunk = names[i:i + 8]
            for nm in chunk:
                lua = ("/silent-command " + pre +
                       f"local ok,v=pcall(function() return s.calculate_tile_properties({{'{nm}'}},P) end) "
                       f"if not ok then rcon.print('ERR '..tostring(v)) return end "
                       f"local a=v['{nm}'] local o={{}} for k=1,#a do o[k]=string.format('%.9g',a[k]) end "
                       f"helpers.write_file('v.txt',table.concat(o,','),false) rcon.print('ok '..#a)")
                resp = c.cmd(lua).strip()
                if not resp.startswith("ok"):
                    bad.append((nm, resp[:200])); continue
                txt = (scr / "v.txt").read_text()
                out["values"][nm] = [float(t) for t in txt.split(",")]
        if a.tiles or a.entities:
            cx0, cx1, cy0, cy1 = x0 // 32 - 1, x1 // 32 + 1, y0 // 32 - 1, y1 // 32 + 1
            c.cmd(f"/silent-command local s=game.surfaces['{a.planet}'] for cy={cy0},{cy1} do for cx={cx0},{cx1} do "
                  f"s.request_to_generate_chunks({{cx*32+16,cy*32+16}},0) end end s.force_generate_chunk_requests() rcon.print('gen')")
        if a.tiles:
            c.cmd("/silent-command " + pre +
                  "local o={} for k=1,#P do o[k]=s.get_tile(P[k][1],P[k][2]).name end "
                  "helpers.write_file('t.txt',table.concat(o,','),false) rcon.print('ok')")
            out["tiles"] = (scr / "t.txt").read_text().split(",")
        if a.entities:
            c.cmd(f"/silent-command local s=game.surfaces['{a.planet}'] local o={{}} "
                  f"for _,e in pairs(s.find_entities_filtered{{area={{{{{x0},{y0}}},{{{x1 + 1},{y1 + 1}}}}}}}) do "
                  f"if e.type~='character' then o[#o+1]=string.format('%s %.2f %.2f %d',e.name,e.position.x,e.position.y,e.type=='resource' and e.amount or 0) end end "
                  f"helpers.write_file('e.txt',table.concat(o,'\\n'),false) rcon.print('ok')")
            ents = []
            for l in (scr / "e.txt").read_text().splitlines():
                n, x, y, am = l.rsplit(" ", 3)
                ents.append({"n": n, "x": float(x), "y": float(y), "a": int(am)})
            out["entities"] = ents
        Path(a.out).write_text(json.dumps(out))
        print(f"wrote {a.out}: {len(out['values'])} expressions, "
              f"{len(out.get('tiles', []))} tiles, {len(out.get('entities', []))} entities")
        for nm, why in bad:
            print("  FAILED", nm, why)
    finally:
        if srv and srv.poll() is None:
            srv.terminate()
            try: srv.wait(timeout=15)
            except subprocess.TimeoutExpired: srv.kill()
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    main()
