#!/usr/bin/env python3
"""Probe the live SE game's raw resource noise field (calculate_tile_properties)
for a zone at a set of points — the value-field oracle to compare against our
generator's --zone-field-probe. No chunk generation needed (the expression is
evaluated directly).

Usage: field_probe_game.py <map_seed> <zone_name> <points_file> <out.jsonl>
  points_file: "x y" per line. Probes default-<res>-patches for a fixed resource set.
"""
import json, os, shutil, subprocess, sys, tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
HOME = Path.home()
DEFAULT_BIN = Path("/Applications/factorio.app/Contents/MacOS/factorio")
FACTORIO_DATA = HOME / "Library" / "Application Support" / "factorio"
RES = ["iron-ore", "copper-ore", "coal", "stone", "uranium-ore", "se-beryllium-ore"]


def log(m): print(f"[field-probe] {m}", file=sys.stderr, flush=True)


def main():
    seed = int(sys.argv[1]); Z = sys.argv[2]
    pts_file = Path(sys.argv[3]); out_path = Path(sys.argv[4])
    rcon_port, game_port, pw = 27721, 34721, "seedsearch"

    pts = []
    for ln in pts_file.read_text().splitlines():
        p = ln.replace(",", " ").split()
        if len(p) >= 2: pts.append((int(float(p[0])), int(float(p[1]))))

    bin_ = Path(os.environ.get("FACTORIO_BIN", str(DEFAULT_BIN)))
    sys.path.insert(0, str(HERE))
    from rcon import wait_for_rcon, RconError

    fsr = float(os.environ.get("FSR_MULT", "1"))  # ore autoplace_controls freq/size/rich
    workdir = Path(tempfile.mkdtemp(prefix="se-field-"))
    save_file = workdir / "verify.zip"; mapgen_file = workdir / "mgs.json"
    template = json.loads((HERE / "se-map-gen-template.json").read_text())
    template["seed"] = seed
    for key in ("autoplace_controls", "autoplace_settings"):
        d = template.get(key)
        if isinstance(d, dict):
            template[key] = {k: v for k, v in d.items() if not k.startswith("kr-")}
    if fsr != 1.0:
        ac = template.setdefault("autoplace_controls", {})
        for r in RES:
            ac[r] = {"frequency": fsr, "size": fsr, "richness": fsr}
        log(f"FSR override: {r if False else ''}ore controls set to {fsr}/{fsr}/{fsr}")
    mapgen_file.write_text(json.dumps(template))

    server = None
    try:
        log(f"Creating SE save (seed {seed})...")
        subprocess.run([str(bin_), "--create", str(save_file), "--map-gen-settings", str(mapgen_file)], check=True, timeout=600)
        server = subprocess.Popen([str(bin_), "--start-server", str(save_file), "--port", str(game_port),
                                   "--rcon-port", str(rcon_port), "--rcon-password", pw],
                                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        client = wait_for_rcon("127.0.0.1", rcon_port, pw, deadline_s=240)
        client.command('/silent-command rcon.print("warmup")')
        client.command('/silent-command rcon.print("ready")')
        surf = Z
        if Z.lower() == "nauvis":
            surf = "nauvis"  # surface 1 already exists
            r = client.command('/silent-command rcon.print("OK:nauvis:"..game.surfaces["nauvis"].map_gen_settings.seed)').strip()
        else:
            mk = ('local z=remote.call("space-exploration","get_zone_from_name",{zone_name="%s"});'
                  'if not z then rcon.print("NOZONE") return end;'
                  'remote.call("space-exploration","zone_get_make_surface",{zone_index=z.index});'
                  'rcon.print("OK:"..z.name)') % Z
            r = client.command("/silent-command " + mk).strip()
        log(f"make-surface: {r}")
        if not r.startswith("OK"): return 1
        Z = surf

        try: client._sock.settimeout(600)
        except Exception: pass
        with open(out_path, "w") as fout:
            for res in RES:
                prop = f"default-{res}-patches"
                got = 0
                B = 300
                for i in range(0, len(pts), B):
                    batch = pts[i:i + B]
                    pos = ",".join(f"{{{x},{y}}}" for x, y in batch)
                    lua = (f"/silent-command local ok,t=pcall(function() return game.surfaces['{Z}'].calculate_tile_properties({{'{prop}'}},{{{pos}}}) end) "
                           f"if not ok then rcon.print('ERR') return end local v=t['{prop}'] local o={{}} "
                           f"for k=1,#v do o[k]=string.format('%.6g',v[k]) end rcon.print(table.concat(o,','))")
                    resp = client.command(lua).strip()
                    if resp == "ERR" or not resp:
                        log(f"{prop}: property not available (skipped)"); break
                    vals = resp.split(",")
                    for (x, y), v in zip(batch, vals):
                        try: fv = float(v)
                        except ValueError: continue
                        fout.write(json.dumps({"n": res, "x": x, "y": y, "v": fv}) + "\n"); got += 1
                log(f"{prop}: {got} values")
        log(f"wrote {out_path}")
        client.close()
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
