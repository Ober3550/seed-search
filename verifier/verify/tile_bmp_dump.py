#!/usr/bin/env python3
"""Render a real SE zone's terrain to a BMP ground truth via the tile-dump mod.

Creates an SE universe for a map seed, starts a headless server, makes the named
zone's surface (SE on-demand), generates its chunks, then invokes the tile-dump
mod's `/tile-bmp` command which writes each tile's live map_color to a BMP plus a
tile-name->color legend. Copies both out of script-output into the repo.

Usage:
  tile_bmp_dump.py <map_seed> <zone_name> [--radius R] [-o out_dir]
"""
import argparse
import json
import os
import shutil
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
SCRIPT_OUTPUT = FACTORIO_DATA / "script-output"


def log(msg):
    print(f"[tile_bmp] {msg}", file=sys.stderr, flush=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("map_seed", type=int)
    ap.add_argument("zone_name")
    ap.add_argument("--radius", type=int, default=300)
    ap.add_argument("-o", "--out", default=str(REPO / "calibration" / "mod-dump"))
    ap.add_argument("--factorio-bin", default=os.environ.get("FACTORIO_BIN", str(DEFAULT_BIN)))
    ap.add_argument("--rcon-port", type=int, default=int(os.environ.get("RCON_PORT", "27718")))
    ap.add_argument("--game-port", type=int, default=int(os.environ.get("GAME_PORT", "34718")))
    ap.add_argument("--rcon-password", default=os.environ.get("RCON_PASSWORD", "seedsearch"))
    args = ap.parse_args()

    factorio_bin = Path(args.factorio_bin)
    if not factorio_bin.exists():
        log(f"Factorio binary not found: {factorio_bin} (set FACTORIO_BIN)")
        return 2
    mods_dir = FACTORIO_DATA / "mods"
    if not any(mods_dir.glob("space-exploration_*")):
        log(f"Space Exploration not found in {mods_dir}")
        return 2

    sys.path.insert(0, str(HERE))
    from rcon import wait_for_rcon, RconError  # noqa: E402

    workdir = Path(tempfile.mkdtemp(prefix="se-tilebmp-"))
    save_file = workdir / "verify.zip"
    mapgen_file = workdir / "map-gen-settings.json"
    # SE's Zone.create_surface reads game.default_map_gen_settings.autoplace_controls,
    # which is nil when the save is created from a bare {"seed":...}. Seeding --create
    # with a full map-gen-settings (autoplace_controls included) makes it work.
    template = json.loads((HERE / "se-map-gen-template.json").read_text())
    template["seed"] = args.map_seed
    mapgen_file.write_text(json.dumps(template))

    bmp_out = SCRIPT_OUTPUT / f"tile-bmp-{args.zone_name}.bmp"
    legend_out = SCRIPT_OUTPUT / f"tile-legend-{args.zone_name}.json"
    for p in (bmp_out, legend_out):
        if p.exists():
            p.unlink()

    server = None
    try:
        log(f"Creating SE save for seed {args.map_seed}...")
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

        # First console command only trips the "disable achievements — repeat to
        # proceed" prompt; send a throwaway pair so real commands execute.
        client.command('/silent-command rcon.print("warmup")')
        client.command('/silent-command rcon.print("ready")')

        make_lua = (
            'local z=remote.call("space-exploration","get_zone_from_name",{zone_name="%s"});'
            'if not z then rcon.print("NOZONE") return end;'
            'remote.call("space-exploration","zone_get_make_surface",{zone_index=z.index});'
            'rcon.print("OK:"..z.name..":"..tostring(z.radius))'
        ) % args.zone_name
        resp = client.command("/silent-command " + make_lua).strip()
        log(f"make-surface: {resp}")
        if resp.startswith("NOZONE") or not resp.startswith("OK"):
            log("Zone not found in this universe.")
            return 1

        # Expected BMP size so we know when the render is complete (rows padded to 4).
        half = args.radius
        size = half * 2
        row_pad = (4 - (size * 3) % 4) % 4
        expect = 54 + size * (size * 3 + row_pad)

        log(f"Rendering /tile-bmp {args.zone_name} {args.radius} (generates chunks; slow)...")
        t0 = time.time()
        try:
            client._sock.settimeout(900)
        except Exception:
            pass
        try:
            client.command(f"/tile-bmp {args.zone_name} {args.radius}")
        except Exception as e:
            log(f"rcon return dropped (ignored): {type(e).__name__}")
        # Poll for the completed file (the mod writes it atomically at the end).
        deadline = time.time() + 900
        while time.time() < deadline:
            if bmp_out.exists() and bmp_out.stat().st_size == expect:
                break
            time.sleep(2)
        log(f"tile-bmp done in {time.time()-t0:.0f}s "
            f"(size={bmp_out.stat().st_size if bmp_out.exists() else 0}, expect={expect})")
        client.close()

        out_dir = Path(args.out)
        out_dir.mkdir(parents=True, exist_ok=True)
        ok = True
        for src, dst in ((bmp_out, out_dir / bmp_out.name), (legend_out, out_dir / legend_out.name)):
            if src.exists():
                shutil.copy(src, dst)
                log(f"copied -> {dst}")
            else:
                log(f"MISSING output: {src}")
                ok = False
        return 0 if ok else 1
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, RconError) as e:
        log(f"FAILED: {e}")
        return 1
    finally:
        if server and server.poll() is None:
            server.terminate()
            try:
                server.wait(timeout=15)
            except subprocess.TimeoutExpired:
                server.kill()
        shutil.rmtree(workdir, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
