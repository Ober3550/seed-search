#!/usr/bin/env python3
"""List ALL SE zones for a map seed from the live game (name, seed, type, radius)
via remote get_zone_index — to diff against our universe generator.
Usage: zone_list_game.py <map_seed> <out.jsonl>
"""
import json, os, shutil, subprocess, sys, tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
HOME = Path.home()
DEFAULT_BIN = Path("/Applications/factorio.app/Contents/MacOS/factorio")
FACTORIO_DATA = HOME / "Library" / "Application Support" / "factorio"


def log(m): print(f"[zone-list] {m}", file=sys.stderr, flush=True)


def main():
    seed = int(sys.argv[1]); out_path = Path(sys.argv[2])
    rcon_port, game_port, pw = 27722, 34722, "seedsearch"
    bin_ = Path(os.environ.get("FACTORIO_BIN", str(DEFAULT_BIN)))
    sys.path.insert(0, str(HERE))
    from rcon import wait_for_rcon, RconError

    wd = Path(tempfile.mkdtemp(prefix="se-zlist-"))
    save = wd / "v.zip"; mg = wd / "mgs.json"
    t = json.loads((HERE / "se-map-gen-template.json").read_text()); t["seed"] = seed
    for k in ("autoplace_controls", "autoplace_settings"):
        d = t.get(k)
        if isinstance(d, dict):
            t[k] = {kk: v for kk, v in d.items() if not kk.startswith("kr-")}
    mg.write_text(json.dumps(t))
    srv = None
    try:
        subprocess.run([str(bin_), "--create", str(save), "--map-gen-settings", str(mg)], check=True, timeout=600)
        srv = subprocess.Popen([str(bin_), "--start-server", str(save), "--port", str(game_port),
                                "--rcon-port", str(rcon_port), "--rcon-password", pw],
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        c = wait_for_rcon("127.0.0.1", rcon_port, pw, deadline_s=240)
        c.command('/silent-command rcon.print("warmup")'); c.command('/silent-command rcon.print("ready")')
        try: c._sock.settimeout(300)
        except Exception: pass
        # Emit one JSON object per zone via helpers.write_file.
        lua = (
            'local zi=remote.call("space-exploration","get_zone_index");'
            'local out={};'
            'for idx,z in pairs(zi) do '
            '  local nm=tostring(z.name or ""); local pr=tostring(z.primary_resource or "");'
            '  out[#out+1]="{\\"n\\":\\""..nm.."\\",\\"s\\":"..tostring(z.seed or 0)'
            '    ..",\\"t\\":\\""..tostring(z.type or "?").."\\",\\"r\\":"..tostring(math.floor(z.radius or 0))'
            '    ..",\\"pr\\":\\""..pr.."\\"}" end;'
            'helpers.write_file("zone-list-%d.jsonl", table.concat(out,"\\n"), false, 0);'
            'rcon.print("N="..#out)'
        ) % seed
        r = c.command("/silent-command " + lua).strip()
        log(f"zones: {r}")
        c.close()
        gm = FACTORIO_DATA / "script-output" / f"zone-list-{seed}.jsonl"
        import time
        for _ in range(30):
            if gm.exists(): break
            time.sleep(1)
        if not gm.exists():
            log("no output"); return 1
        shutil.copy(gm, out_path); log(f"wrote {out_path}")
        return 0
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, RconError) as e:
        log(f"FAILED: {e}"); return 1
    finally:
        if srv and srv.poll() is None:
            srv.terminate()
            try: srv.wait(timeout=15)
            except subprocess.TimeoutExpired: srv.kill()
        shutil.rmtree(wd, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
