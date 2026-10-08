#!/usr/bin/env python3
"""Probe raw voronoi/terrace noise expressions on a live headless Factorio 2.0
(Space Age) game via calculate_tile_properties. The map's
map_gen_settings.property_expression_names carries RAW expression strings
(expression per property key), and each key is probed over a grid of tile
positions. This is the oracle for pinning noise.zig's voronoi/terrace ports.

Usage:
  probe_ops.py --name tag --seed N --props '{"elevation": "voronoi_cell_id{...}"}'
      --grid "x0:x1:y0:y1:stepx:stepy" [--more-grids "..." ] --out FILE.jsonl
"""
import argparse, json, os, socket, struct, subprocess, sys, shutil, time

ROOT = os.path.dirname(os.path.abspath(__file__))
FACTORIO = "/Applications/factorio.app/Contents/MacOS/factorio"
CONFIG = os.path.join(ROOT, "config.ini")
MODS = os.path.join(ROOT, "mods")
FDATA = os.path.join(ROOT, "fdata")
OUT = os.path.join(ROOT, "out")
RCON_PORT = 25592
RCON_PW = "saprobe"
GAME_PORT = 34201


class Rcon:
    def __init__(self, host, port, pw, timeout=600):
        self.s = socket.create_connection((host, port), timeout=timeout)
        self.s.settimeout(timeout)
        self.rid = 0
        self._send(3, pw)
        self._recv()

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
        while True:
            rid, ptype, resp = self._recv()
            if ptype == 0:
                return resp


def parse_grids(specs):
    pts = []
    for g in specs:
        parts = [int(v) for v in g.split(":")]
        x0, x1, y0, y1 = parts[:4]
        sx = parts[4] if len(parts) > 4 else 1
        sy = parts[5] if len(parts) > 5 else sx
        for y in range(y0, y1 + 1, sy):
            for x in range(x0, x1 + 1, sx):
                pts.append((x, y))
    return pts


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--name", required=True)
    ap.add_argument("--seed", type=int, default=341)
    ap.add_argument("--props", required=True, help="JSON {key: expr}")
    ap.add_argument("--grid", required=True)
    ap.add_argument("--more-grids", default=None)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    props = json.loads(args.props)
    grids = [args.grid] + ([args.more_grids] if args.more_grids else [])
    pts = parse_grids([g for g in grids if g])
    print(f"[sa-probe] {len(pts)} points, props={list(props)}", file=sys.stderr, flush=True)

    mgs = {"seed": args.seed, "property_expression_names": props}
    mgs_path = os.path.join(OUT, f"mgs-{args.name}.json")
    with open(mgs_path, "w") as f:
        json.dump(mgs, f, indent=1)

    save = os.path.join(FDATA, "saves", f"{args.name}.zip")
    if os.path.exists(save):
        os.remove(save)
    os.makedirs(os.path.dirname(save), exist_ok=True)

    print(f"[sa-probe] creating world seed={args.seed}", file=sys.stderr, flush=True)
    r = subprocess.run([FACTORIO, "--config", CONFIG, "--mod-directory", MODS,
                        "--create", save, "--map-gen-settings", mgs_path],
                       capture_output=True, text=True, timeout=600)
    if not os.path.exists(save):
        print(r.stdout[-4000:], file=sys.stderr)
        print(r.stderr[-4000:], file=sys.stderr)
        sys.exit(1)

    srv = subprocess.Popen([FACTORIO, "--config", CONFIG, "--mod-directory", MODS,
                            "--start-server", save, "--port", str(GAME_PORT),
                            "--rcon-port", str(RCON_PORT), "--rcon-password", RCON_PW,
                            "--server-settings", os.path.join(ROOT, "server-settings.json"),
                            "--map-gen-settings", mgs_path],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        # wait for RCON
        client = None
        for _ in range(240):
            if srv.poll() is not None:
                print("[sa-probe] server died", file=sys.stderr); sys.exit(1)
            try:
                client = Rcon("127.0.0.1", RCON_PORT, RCON_PW, timeout=10)
                break
            except OSError:
                time.sleep(1)
        if client is None:
            print("[sa-probe] rcon timeout", file=sys.stderr); sys.exit(1)
        client.s.settimeout(600)
        client.cmd('/silent-command rcon.print("warmup")')
        r = client.cmd('/silent-command rcon.print("ready")')
        if "ready" not in r:
            print(f"[sa-probe] bad warmup: {r[:300]}", file=sys.stderr)
        n = 0
        with open(args.out, "w") as fout:
            for key, expr in props.items():
                got = 0
                B = 200
                for i in range(0, len(pts), B):
                    batch = pts[i:i + B]
                    pos = ",".join(f"{{{x},{y}}}" for x, y in batch)
                    lua = (f"/silent-command local ok,t=pcall(function() return "
                           f"game.surfaces['nauvis'].calculate_tile_properties({{'{key}'}},{{{pos}}}) end) "
                           f"if not ok then rcon.print('ERR') return end "
                           f"local v=t['{key}'] if not v then rcon.print('NOFIELD') return end "
                           f"local o={{}} for k=1,#v do o[k]=string.format('%.9g',v[k]) end "
                           f"rcon.print(table.concat(o,','))")
                    resp = client.cmd(lua).strip()
                    if resp in ("ERR", "NOFIELD") or not resp:
                        print(f"[sa-probe] {key}: {resp or 'empty'} at batch {i}", file=sys.stderr)
                        break
                    vals = resp.split(",")
                    if len(vals) != len(batch):
                        print(f"[sa-probe] {key} len mismatch {len(vals)} vs {len(batch)}", file=sys.stderr)
                        break
                    for (x, y), v in zip(batch, vals):
                        try:
                            fv = float(v)
                        except ValueError:
                            continue
                        fout.write(json.dumps({"p": key, "x": x, "y": y, "v": fv}) + "\n")
                        got += 1
                print(f"[sa-probe] {key}: {got} values", file=sys.stderr, flush=True)
                n += got
        print(f"[sa-probe] wrote {n} rows -> {args.out}", file=sys.stderr, flush=True)
        return 0
    finally:
        if srv.poll() is None:
            srv.terminate()
            try:
                srv.wait(timeout=15)
            except subprocess.TimeoutExpired:
                srv.kill()


if __name__ == "__main__":
    sys.exit(main())
