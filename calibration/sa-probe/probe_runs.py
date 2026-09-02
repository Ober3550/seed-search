#!/usr/bin/env python3
"""Drive probes for a generated run: maps run's noise-expression names onto the
6 engine property slots, creates the world, probes every slot over a grid.
Usage: probe_runs.py --run N --grid "x0:x1:y0:y1:step" [--seed S] [--out F]
"""
import argparse, json, os, sys, subprocess, socket, struct, time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from probe_ops import Rcon, parse_grids

FACTORIO = "/Applications/factorio.app/Contents/MacOS/factorio"
RCON_PORT = 25594
GAME_PORT = 34203

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--run", type=int, default=None)
    ap.add_argument("--props", default=None, help="JSON {slot: exprname} or {slot: rawexpr}")
    ap.add_argument("--grid", required=True)
    ap.add_argument("--seed", type=int, default=341)
    ap.add_argument("--out", required=True)
    ap.add_argument("--tag", default="")
    a = ap.parse_args()

    if a.props:
        props = json.loads(a.props)
    else:
        meta = json.load(open(os.path.join(HERE, "out", "probe-runs.json")))
        slots = meta["slots"]
        run_names = meta["runs"][a.run]
        assert len(run_names) <= len(slots), run_names
        props = {slots[i]: n for i, n in enumerate(run_names)}
    pts = parse_grids([a.grid])
    print(f"[probe-runs] run {a.run} {len(pts)} pts props={props}", file=sys.stderr, flush=True)

    mgs = {"seed": a.seed, "property_expression_names": props}
    with open(os.path.join(HERE, "out", f"mgs-run{a.run}.json"), "w") as f:
        json.dump(mgs, f)
    save = os.path.join(HERE, "fdata", "saves", f"run{a.run}.zip")
    if os.path.exists(save): os.remove(save)
    r = subprocess.run([FACTORIO, "--config", os.path.join(HERE, "config.ini"),
                        "--mod-directory", os.path.join(HERE, "mods"),
                        "--create", save, "--map-gen-settings", os.path.join(HERE, "out", f"mgs-run{a.run}.json")],
                       capture_output=True, text=True, timeout=600)
    if not os.path.exists(save):
        print(r.stdout[-3000:], file=sys.stderr); print(r.stderr[-3000:], file=sys.stderr); sys.exit(1)
    srv = subprocess.Popen([FACTORIO, "--config", os.path.join(HERE, "config.ini"),
                            "--mod-directory", os.path.join(HERE, "mods"),
                            "--start-server", save, "--port", str(GAME_PORT),
                            "--rcon-port", str(RCON_PORT), "--rcon-password", "saprobe",
                            "--server-settings", os.path.join(HERE, "server-settings.json")],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        c = None
        for _ in range(240):
            if srv.poll() is not None:
                print("[probe-runs] server died", file=sys.stderr); sys.exit(1)
            try:
                c = Rcon("127.0.0.1", RCON_PORT, "saprobe", timeout=10); break
            except OSError: time.sleep(1)
        if c is None:
            print("[probe-runs] rcon timeout", file=sys.stderr); sys.exit(1)
        c.s.settimeout(600)
        c.cmd('/silent-command rcon.print("warmup")')
        n = 0
        with open(a.out, "w") as fout:
            for key, name in props.items():
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
                    resp = c.cmd(lua).strip()
                    if resp in ("ERR", "NOFIELD") or not resp:
                        print(f"[probe-runs] {name}: {resp} batch {i}", file=sys.stderr); break
                    vals = resp.split(",")
                    if len(vals) != len(batch):
                        print(f"[probe-runs] {name} len mismatch", file=sys.stderr); break
                    for (x, y), v in zip(batch, vals):
                        try: fv = float(v)
                        except ValueError: continue
                        fout.write(json.dumps({"p": name, "x": x, "y": y, "v": fv}) + "\n")
                        got += 1
                print(f"[probe-runs] {name}: {got}", file=sys.stderr, flush=True)
                n += got
        print(f"[probe-runs] wrote {n} rows -> {a.out}", file=sys.stderr, flush=True)
        return 0
    finally:
        if srv.poll() is None:
            srv.terminate()
            try: srv.wait(timeout=15)
            except subprocess.TimeoutExpired: srv.kill()

if __name__ == "__main__":
    sys.exit(main())
