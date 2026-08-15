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
    ap.add_argument("--radius", type=int, default=500)
    ap.add_argument("-o", "--out", default=None)
    ap.add_argument("--rcon-port", type=int, default=27719)
    ap.add_argument("--game-port", type=int, default=34719)
    ap.add_argument("--rcon-password", default="seedsearch")
    args = ap.parse_args()

    out_path = Path(args.out) if args.out else (REPO / "verifier" / "fixtures" / f"nauvis-ore-game-{args.map_seed}.jsonl")
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
    fsr = float(os.environ.get("FSR_MULT", "1"))
    if fsr != 1.0:
        ac = template.setdefault("autoplace_controls", {})
        for r in ("iron-ore", "copper-ore", "coal", "stone", "uranium-ore"):
            ac[r] = {"frequency": fsr, "size": fsr, "richness": fsr}
        log(f"FSR override: ore controls set to {fsr}/{fsr}/{fsr}")
    mapgen_file.write_text(json.dumps(template))

    game_out = SCRIPT_OUTPUT / f"nauvis-ore-{args.map_seed}.jsonl"
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

        # Confirm Nauvis seed matches what we injected.
        seed = client.command('/silent-command rcon.print(game.surfaces["nauvis"].map_gen_settings.seed)').strip()
        log(f"game Nauvis map_gen_settings.seed = {seed} (injected {args.map_seed})")

        R = args.radius
        cr = (R // 32) + 1
        log(f"Force-generating Nauvis chunks within radius {R} ({(2*cr+1)**2} chunks; slow)...")
        try: client._sock.settimeout(1800)
        except Exception: pass
        gen_lua = (
            'local s=game.surfaces["nauvis"];'
            'local cr=%d;'
            'for cx=-cr,cr do for cy=-cr,cr do s.request_to_generate_chunks({cx*32,cy*32},0) end end;'
            's.force_generate_chunk_requests();'
            'rcon.print("GEN_DONE")'
        ) % cr
        try:
            r = client.command("/silent-command " + gen_lua).strip()
            log(f"chunk-gen: {r}")
        except Exception as e:
            log(f"chunk-gen rcon return dropped (ignored): {type(e).__name__}")

        # Scan resource entities in the disk and write JSONL via game.write_file.
        dump_lua = (
            'local s=game.surfaces["nauvis"];local R=%d;'
            'local es=s.find_entities_filtered{type="resource",area={{-R,-R},{R,R}},limit=2000000};'
            'local buf={};local n=0;'
            'for _,e in pairs(es) do '
            '  local x=math.floor(e.position.x);local y=math.floor(e.position.y);'
            '  if x*x+y*y<=R*R then n=n+1; buf[n]=string.format("{\\"x\\":%%d,\\"y\\":%%d,\\"n\\":\\"%%s\\",\\"a\\":%%d}",x,y,e.name,e.amount or 0) end '
            'end;'
            'helpers.write_file("nauvis-ore-%d.jsonl", table.concat(buf,"\\n"), false, 0);'
            'rcon.print("DUMP_DONE:"..n)'
        ) % (R, args.map_seed)
        r = client.command("/silent-command " + dump_lua).strip()
        log(f"dump: {r}")

        # Terrain summary: water fraction + top tiles within the disk.
        tile_lua = (
            'local s=game.surfaces["nauvis"];local R=%d;'
            'local ts=s.find_tiles_filtered{area={{-R,-R},{R,R}},limit=4000000};'
            'local hist={};local water=0;local land=0;local tot=0;'
            'for _,t in pairs(ts) do local x=math.floor(t.position.x);local y=math.floor(t.position.y);'
            '  if x*x+y*y<=R*R then tot=tot+1; local n=t.name; hist[n]=(hist[n] or 0)+1;'
            '    if t.prototype.collision_mask and (n:find("water") or n:find("deepwater")) then water=water+1 else land=land+1 end end end;'
            'local parts={};for n,c in pairs(hist) do parts[#parts+1]=n.."="..c end;'
            'rcon.print("TILES tot="..tot.." water="..water.." land="..land.." | "..table.concat(parts,","))'
        ) % (R,)
        rt = client.command("/silent-command " + tile_lua).strip()
        log(f"tiles: {rt}")
        client.close()

        # Poll for the written file, then copy out.
        deadline = time.time() + 60
        while time.time() < deadline and not game_out.exists():
            time.sleep(1)
        if not game_out.exists():
            log(f"MISSING game output: {game_out}"); return 1
        shutil.copy(game_out, out_path)
        log(f"copied -> {out_path} ({out_path.stat().st_size} bytes)")
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
