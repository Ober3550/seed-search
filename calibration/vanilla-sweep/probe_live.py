#!/usr/bin/env python3
"""Probe a named noise expression on a surface of the LIVE modded game
(factorio-ai host, RCON 25575). Usage:
  probe_live.py --surface Horaerratum --prop default-iron-ore-patches \
      --grids "x0:x1:y0:y1:step,..." --out FILE
"""
import argparse, json, socket, struct

class Rcon:
    def __init__(s, host, port, pw):
        s.s = socket.create_connection((host, port), timeout=120); s.rid = 0
        s._send(3, pw); s._recv()
    def _send(s, t, b):
        s.rid += 1
        s.s.sendall(struct.pack("<iii", 10 + len(b), s.rid, t) + b.encode() + b"\x00\x00")
    def _recv(s):
        h = b""
        while len(h) < 4: h += s.s.recv(4 - len(h))
        (sz,) = struct.unpack("<i", h); b = b""
        while len(b) < sz: b += s.s.recv(sz - len(b))
        return b[8:-2].decode(errors="replace")
    def cmd(s, c): s._send(2, c); return s._recv()

ap = argparse.ArgumentParser()
ap.add_argument("--surface", required=True)
ap.add_argument("--prop", required=True)
ap.add_argument("--grids", required=True)
ap.add_argument("--out", required=True)
a = ap.parse_args()

pts = []
for g in a.grids.split(","):
    x0, x1, y0, y1, st = (int(v) for v in g.split(":"))
    for y in range(y0, y1, st):
        for x in range(x0, x1, st):
            pts.append((x, y))
print(f"probing {len(pts)} points of {a.prop} on {a.surface}")
r = Rcon("127.0.0.1", 25575, "factorio-ai")
r.cmd("/sc rcon.print('warmup')")
with open(a.out, "w") as f:
    B = 400
    for i in range(0, len(pts), B):
        batch = pts[i:i + B]
        pos = ",".join(f"{{{x},{y}}}" for x, y in batch)
        lua = (f"/sc local t=game.surfaces['{a.surface}'].calculate_tile_properties({{'{a.prop}'}},{{{pos}}}) "
               f"local v=t['{a.prop}'] local o={{}} for k=1,#v do o[k]=string.format('%.9g',v[k]) end "
               f"rcon.print(table.concat(o,','))")
        vals = r.cmd(lua).strip().split(",")
        assert len(vals) == len(batch), f"batch {i}: {len(vals)} vs {len(batch)}"
        for (x, y), v in zip(batch, vals):
            f.write(json.dumps({"x": x, "y": y, "v": float(v)}) + "\n")
        if i % 8000 == 0: print(f"  {i}/{len(pts)}")
print(f"wrote {a.out}")
