#!/usr/bin/env python3
"""Generate a VANILLA (no mods) Factorio world with given autoplace controls,
force-generate a disk of chunks, dump all resource tiles to JSONL, and exit.

Fully isolated from the user's normal Factorio (own write-data dir, own RCON
port, empty mod dir) so it can run alongside the modded factorio-ai host.

Usage:
  python3 run_case.py --name base --seed 341 [--radius-chunks 16]
      [--freq 1.0 --size 1.0 --rich 1.0] [--resource iron-ore]

Controls apply to ALL vanilla resources unless --resource limits the override.
Output: out/<name>.jsonl  (one {"n":name,"x":..,"y":..,"a":amount} per line)
"""
import argparse, json, os, socket, struct, subprocess, sys, time, shutil

ROOT = os.path.dirname(os.path.abspath(__file__))
FACTORIO = "/Applications/factorio.app/Contents/MacOS/factorio"
CONFIG = os.path.join(ROOT, "config.ini")
MODS = os.path.join(ROOT, "mods-empty")
FDATA = os.path.join(ROOT, "fdata")
OUT = os.path.join(ROOT, "out")
RCON_PORT = 25590
RCON_PW = "vanilla"

RESOURCES = ["iron-ore", "copper-ore", "coal", "stone", "uranium-ore", "crude-oil"]


class Rcon:
    def __init__(self, host, port, pw, timeout=600):
        self.s = socket.create_connection((host, port), timeout=timeout)
        self.s.settimeout(timeout)
        self.rid = 0
        self._send(3, pw)
        self._recv()  # auth response

    def _send(self, ptype, body):
        self.rid += 1
        data = struct.pack("<iii", 10 + len(body), self.rid, ptype) + body.encode() + b"\x00\x00"
        self.s.sendall(data)
        return self.rid

    def _recv(self):
        hdr = b""
        while len(hdr) < 4:
            hdr += self.s.recv(4 - len(hdr))
        (size,) = struct.unpack("<i", hdr)
        body = b""
        while len(body) < size:
            body += self.s.recv(size - len(body))
        rid, ptype = struct.unpack("<ii", body[:8])
        return rid, ptype, body[8:-2].decode(errors="replace")

    def cmd(self, c):
        self._send(2, c)
        _, _, resp = self._recv()
        return resp


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--name", required=True)
    ap.add_argument("--seed", type=int, default=341)
    ap.add_argument("--radius-chunks", type=int, default=16)  # 16 chunks = 512 tiles
    ap.add_argument("--freq", type=float, default=1.0)
    ap.add_argument("--size", type=float, default=1.0)
    ap.add_argument("--rich", type=float, default=1.0)
    ap.add_argument("--resource", default=None,
                    help="apply freq/size/rich override only to this resource (default: all)")
    args = ap.parse_args()

    os.makedirs(OUT, exist_ok=True)
    os.makedirs(MODS, exist_ok=True)
    os.makedirs(os.path.join(FDATA, "saves"), exist_ok=True)
    # mod-list with only base enabled (quality/space-age/elevated-rails DLC mods off)
    with open(os.path.join(MODS, "mod-list.json"), "w") as f:
        json.dump({"mods": [
            {"name": "base", "enabled": True},
            {"name": "quality", "enabled": False},
            {"name": "space-age", "enabled": False},
            {"name": "elevated-rails", "enabled": False},
        ]}, f)

    # map-gen-settings: default everything, explicit seed + per-resource controls
    controls = {}
    for r in RESOURCES:
        if args.resource is None or args.resource == r:
            controls[r] = {"frequency": args.freq, "size": args.size, "richness": args.rich}
    mgs = {
        "seed": args.seed,
        "autoplace_controls": controls,
        # keep everything else at engine defaults
    }
    mgs_path = os.path.join(ROOT, f"mgs-{args.name}.json")
    with open(mgs_path, "w") as f:
        json.dump(mgs, f, indent=1)

    save = os.path.join(FDATA, "saves", f"{args.name}.zip")
    if os.path.exists(save):
        os.remove(save)

    print(f"[{args.name}] creating world (seed={args.seed}, ctrl f={args.freq} s={args.size} r={args.rich})")
    r = subprocess.run([FACTORIO, "--config", CONFIG, "--mod-directory", MODS,
                        "--create", save, "--map-gen-settings", mgs_path],
                       capture_output=True, text=True, timeout=300)
    if not os.path.exists(save):
        print(r.stdout[-3000:]); print(r.stderr[-3000:]); sys.exit(1)

    print(f"[{args.name}] starting headless server")
    srv = subprocess.Popen([FACTORIO, "--config", CONFIG, "--mod-directory", MODS,
                            "--start-server", save, "--port", "34199",
                            "--rcon-port", str(RCON_PORT), "--rcon-password", RCON_PW,
                            "--server-settings", os.path.join(ROOT, "server-settings.json")],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        rcon = None
        for _ in range(120):
            time.sleep(1)
            try:
                rcon = Rcon("127.0.0.1", RCON_PORT, RCON_PW)
                break
            except OSError:
                continue
        if rcon is None:
            print("RCON never came up"); sys.exit(1)

        rcon.cmd("/sc rcon.print('warmup')")  # absorb achievements warning
        print(rcon.cmd("/sc rcon.print(game.surfaces[1].map_gen_settings.seed)"))

        n = args.radius_chunks
        print(f"[{args.name}] generating {2*n}x{2*n} chunks…")
        rcon.cmd(f"/sc local s=game.surfaces[1] s.request_to_generate_chunks({{0,0}}, {n}) s.force_generate_chunk_requests() rcon.print('gen done')")

        print(f"[{args.name}] dumping resources…")
        # dump in stripes to keep each RCON response small; write via script-output
        fname = f"{args.name}.jsonl"
        rcon.cmd(f"/sc helpers.write_file('{fname}', '', false)")
        r_tiles = n * 32
        stripe = 256
        y = -r_tiles
        while y < r_tiles:
            y2 = min(y + stripe, r_tiles)
            lua = (f"/sc local s=game.surfaces[1] local t={{}} "
                   f"for _,e in pairs(s.find_entities_filtered{{type='resource', area={{{{{-r_tiles},{y}}},{{{r_tiles},{y2}}}}}}}) do "
                   f"t[#t+1]=string.format('{{\"n\":\"%s\",\"x\":%d,\"y\":%d,\"a\":%d}}', e.name, math.floor(e.position.x), math.floor(e.position.y), e.amount) end "
                   f"if #t>0 then helpers.write_file('{fname}', table.concat(t,'\\n')..'\\n', true) end rcon.print(#t)")
            cnt = rcon.cmd(lua).strip()
            y = y2
        print(f"[{args.name}] dump complete")
    finally:
        srv.terminate()
        try:
            srv.wait(timeout=15)
        except subprocess.TimeoutExpired:
            srv.kill()

    src = os.path.join(FDATA, "script-output", fname)
    dst = os.path.join(OUT, fname)
    shutil.move(src, dst)
    ntiles = sum(1 for _ in open(dst))
    print(f"[{args.name}] wrote {dst} ({ntiles} resource tiles)")


if __name__ == "__main__":
    main()
