#!/usr/bin/env python3
"""Dump the REAL Nauvis ore (under Space Exploration) for a map seed, via RCON.

Nauvis is surface 1 of any SE save, so no zone travel is needed. Creates an SE
save with the seed injected, starts a headless server, force-generates Nauvis
chunks within a radius, then scans resource entities and writes them as JSONL
({x,y,n,a}) to script-output via game.write_file. Copies the file out.

Usage: nauvis_ore_dump.py <map_seed> [--radius R] [-o out.jsonl]
"""
import argparse, json, os, shutil, subprocess, sys, tempfile, time
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
HOME = Path.home()
DEFAULT_BIN = Path("/Applications/factorio.app/Contents/MacOS/factorio")
FACTORIO_DATA = HOME / "Library" / "Application Support" / "factorio"
SCRIPT_OUTPUT = FACTORIO_DATA / "script-output"


def log(m): print(f"[nauvis-ore] {m}", file=sys.stderr, flush=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("map_seed", type=int)
    ap.add_argument("zone_name", help="SE zone name (e.g. a moon/planet) — its surface is created on demand")
    ap.add_argument("--radius", type=int, default=420)
    ap.add_argument("-o", "--out", default=None)
    ap.add_argument("--rcon-port", type=int, default=27720)
    ap.add_argument("--game-port", type=int, default=34720)
    ap.add_argument("--rcon-password", default="seedsearch")
    args = ap.parse_args()

    Z = args.zone_name
    out_path = Path(args.out) if args.out else (REPO / "verifier" / "fixtures" / f"zone-ore-game-{args.map_seed}-{Z}.jsonl")
    out_path.parent.mkdir(parents=True, exist_ok=True)

    bin_ = Path(os.environ.get("FACTORIO_BIN", str(DEFAULT_BIN)))
    if not bin_.exists():
        log(f"Factorio binary not found: {bin_}"); return 2
    if not any((FACTORIO_DATA / "mods").glob("space-exploration_*")):
        log("SE not found in live mods dir"); return 2

    sys.path.insert(0, str(HERE))
    from rcon import wait_for_rcon, RconError

    workdir = Path(tempfile.mkdtemp(prefix="se-nauvis-ore-"))
    save_file = workdir / "verify.zip"
    mapgen_file = workdir / "map-gen-settings.json"
    template = json.loads((HERE / "se-map-gen-template.json").read_text())
    template["seed"] = args.map_seed
    # The template carries Krastorio2 autoplace controls (kr-*), but K2 is disabled
    # in the live mod set, so those control names are invalid → --create errors.
    # Drop them (and any autoplace_settings referencing them).
    for key in ("autoplace_controls", "autoplace_settings"):
        d = template.get(key)
        if isinstance(d, dict):
            template[key] = {k: v for k, v in d.items() if not k.startswith("kr-")}
    mapgen_file.write_text(json.dumps(template))

    game_out = SCRIPT_OUTPUT / f"zone-ore-{args.map_seed}-{Z}.jsonl"
    if game_out.exists():
        game_out.unlink()

    server = None
    try:
        log(f"Creating SE save for seed {args.map_seed} (runs SE universe gen)...")
        subprocess.run([str(bin_), "--create", str(save_file),
                        "--map-gen-settings", str(mapgen_file)], check=True, timeout=600)
        log(f"Starting headless server (RCON :{args.rcon_port})...")
        server = subprocess.Popen([str(bin_), "--start-server", str(save_file),
                                   "--port", str(args.game_port),
                                   "--rcon-port", str(args.rcon_port),
                                   "--rcon-password", args.rcon_password],
                                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        client = wait_for_rcon("127.0.0.1", args.rcon_port, args.rcon_password, deadline_s=240)
        client.command('/silent-command rcon.print("warmup")')
        client.command('/silent-command rcon.print("ready")')

        # Resolve the zone. AUTO picks the smallest resource-bearing moon whose
        # primary is NOT a Krastorio2 resource (K2 is disabled here).
        if Z == "AUTO":
            pick_lua = (
                'local zi=remote.call("space-exploration","get_zone_index");'
                'local best=nil;'
                'for idx,z in pairs(zi) do '
                '  if z.type=="moon" and z.primary_resource and not string.find(z.primary_resource,"kr-") and z.radius then '
                '    if (not best) or z.radius<best.radius then best=z end end end;'
                'if not best then rcon.print("NOZONE") else rcon.print("PICK:"..best.name) end'
            )
            p = client.command("/silent-command " + pick_lua).strip()
            log(f"auto-pick: {p}")
            if not p.startswith("PICK:"):
                log("No suitable moon found."); return 1
            Z = p.split("PICK:", 1)[1].strip()

        # Create the SE zone's surface on demand and report its seed/radius/controls.
        make_lua = (
            'local z=remote.call("space-exploration","get_zone_from_name",{zone_name="%s"});'
            'if not z then rcon.print("NOZONE") return end;'
            'remote.call("space-exploration","zone_get_make_surface",{zone_index=z.index});'
            'local s=game.surfaces[z.name];'
            'local ac=s.map_gen_settings.autoplace_controls or {};'
            'local parts={};for k,v in pairs(ac) do parts[#parts+1]=k.."="..string.format("%%.3f/%%.3f/%%.3f",v.frequency or 1,v.size or 1,v.richness or 1) end;'
            'rcon.print("ZONE:"..z.name..":seed="..s.map_gen_settings.seed..":radius="..tostring(z.radius)..":primary="..tostring(z.primary_resource)..":ctrls="..table.concat(parts,","))'
        ) % Z
        resp = client.command("/silent-command " + make_lua).strip()
        log(f"make-surface: {resp}")
        if resp.startswith("NOZONE") or not resp.startswith("ZONE"):
            log("Zone not found in this universe."); return 1

        # Now that Z is resolved, fix the output paths to match the game's write.
        nonlocal_out = None
        game_out2 = SCRIPT_OUTPUT / f"zone-ore-{args.map_seed}-{Z}.jsonl"
        out_path2 = Path(args.out) if args.out else (REPO / "verifier" / "fixtures" / f"zone-ore-game-{args.map_seed}-{Z}.jsonl")
        if game_out2.exists(): game_out2.unlink()

        R = args.radius
        cr = (R // 32) + 1
        log(f"Force-generating {Z} chunks within radius {R} ({(2*cr+1)**2} chunks; slow)...")
        try: client._sock.settimeout(1800)
        except Exception: pass
        gen_lua = (
            'local s=game.surfaces["%s"];'
            'local cr=%d;'
            'for cx=-cr,cr do for cy=-cr,cr do s.request_to_generate_chunks({cx*32,cy*32},0) end end;'
            's.force_generate_chunk_requests();'
            'rcon.print("GEN_DONE")'
        ) % (Z, cr)
        try:
            r = client.command("/silent-command " + gen_lua).strip()
            log(f"chunk-gen: {r}")
        except Exception as e:
            log(f"chunk-gen rcon return dropped (ignored): {type(e).__name__}")

        # Scan resource entities in the disk and write JSONL.
        dump_lua = (
            'local s=game.surfaces["%s"];local R=%d;'
            'local es=s.find_entities_filtered{type="resource",area={{-R,-R},{R,R}},limit=2000000};'
            'local buf={};local n=0;'
            'for _,e in pairs(es) do '
            '  local x=math.floor(e.position.x);local y=math.floor(e.position.y);'
            '  if x*x+y*y<=R*R then n=n+1; buf[n]=string.format("{\\"x\\":%%d,\\"y\\":%%d,\\"n\\":\\"%%s\\",\\"a\\":%%d}",x,y,e.name,e.amount or 0) end '
            'end;'
            'helpers.write_file("zone-ore-%d-%s.jsonl", table.concat(buf,"\\n"), false, 0);'
            'rcon.print("DUMP_DONE:"..n)'
        ) % (Z, R, args.map_seed, Z)
        r = client.command("/silent-command " + dump_lua).strip()
        log(f"dump: {r}")

        # Terrain summary: water fraction + top tiles within the disk.
        tile_lua = (
            'local s=game.surfaces["%s"];local R=%d;'
            'local ts=s.find_tiles_filtered{area={{-R,-R},{R,R}},limit=4000000};'
            'local hist={};local water=0;local land=0;local tot=0;'
            'for _,t in pairs(ts) do local x=math.floor(t.position.x);local y=math.floor(t.position.y);'
            '  if x*x+y*y<=R*R then tot=tot+1; local n=t.name; hist[n]=(hist[n] or 0)+1;'
            '    if t.prototype.collision_mask and (n:find("water") or n:find("deepwater")) then water=water+1 else land=land+1 end end end;'
            'local parts={};for n,c in pairs(hist) do parts[#parts+1]=n.."="..c end;'
            'rcon.print("TILES tot="..tot.." water="..water.." land="..land.." | "..table.concat(parts,","))'
        ) % (Z, R)
        rt = client.command("/silent-command " + tile_lua).strip()
        log(f"tiles: {rt}")
        client.close()

        # Poll for the written file, then copy out.
        deadline = time.time() + 60
        while time.time() < deadline and not game_out2.exists():
            time.sleep(1)
        if not game_out2.exists():
            log(f"MISSING game output: {game_out2}"); return 1
        shutil.copy(game_out2, out_path2)
        log(f"copied -> {out_path2} ({out_path2.stat().st_size} bytes)")
        return 0
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, RconError) as e:
        log(f"FAILED: {e}"); return 1
    finally:
        if server and server.poll() is None:
            server.terminate()
            try: server.wait(timeout=15)
            except subprocess.TimeoutExpired: server.kill()
        shutil.rmtree(workdir, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
