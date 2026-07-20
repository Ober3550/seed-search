#!/usr/bin/env python3
"""Calibrate by manually creating a zone surface (headless RCON, no player needed).
Works around Factorio 2.0's nil game.default_map_gen_settings by using
Nauvis surface settings as a template.

Usage: python3 calibration/calibrate-zone.py <zone_name> <universe_seed> <radius>
"""
import sys, os, subprocess, tempfile, time, json
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parent
sys.path.insert(0, str(REPO / "verifier" / "verify"))
from rcon import wait_for_rcon

FACTORIO_BIN = "/Applications/factorio.app/Contents/MacOS/factorio"

def step(msg):
    print(f"\n{'='*60}\n>>> {msg}\n{'='*60}", flush=True)

def rcon(c, cmd, timeout=None):
    if timeout:
        old = c.timeout
        c.timeout = timeout
    r = c.command(cmd).strip()
    if timeout:
        c.timeout = old
    if r:
        print(f"  <- {r[:500]}")
    return r

# ── Args ──────────────────────────────────────────────────────────────
zone_name = sys.argv[1]
universe_seed = int(sys.argv[2])
radius = int(sys.argv[3])

# ── Step 1: Create save ──────────────────────────────────────────────
step(f"1. Creating save for universe seed {universe_seed}")
workdir = Path(tempfile.mkdtemp(prefix="se-cal-"))
(workdir / "map-gen-settings.json").write_text(json.dumps({"seed": universe_seed}))
save_file = workdir / "calib.zip"

subprocess.run([FACTORIO_BIN, "--create", str(save_file), "--map-gen-settings", str(workdir / "map-gen-settings.json")],
    check=True, timeout=300, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
print("   Save created.")

# ── Step 2: Start headless server ─────────────────────────────────────
step("2. Starting headless server")
server = subprocess.Popen([FACTORIO_BIN,
    "--start-server", str(save_file),
    "--port", "34717", "--rcon-port", "27717", "--rcon-password", "seedsearch"],
    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# ── Step 3: Wait for RCON ─────────────────────────────────────────────
step("3. Waiting for RCON and game ticks...")
c = wait_for_rcon("127.0.0.1", 27717, "seedsearch", deadline_s=120)
# Wait for the game to tick a few times (SE universe init needs ticks)
for i in range(30):
    r = c.command("/silent-command rcon.print(game.tick)").strip()
    if r and r.isdigit() and int(r) > 60:
        print(f"   RCON ready at tick {r}")
        break
    time.sleep(1)
else:
    print("   WARNING: game ticks not advancing")

# ── Step 4: Get zone seed ─────────────────────────────────────────────
step(f"4. Getting zone '{zone_name}' seed")
lua = f'/silent-command local z=remote.call("space-exploration","get_zone_from_name",{{zone_name="{zone_name}"}}); if z then rcon.print(tostring(z.seed)) else rcon.print("ZONE_NOT_FOUND") end'
r = rcon(c, lua)
zone_seed = int(r.strip()) if r and r.strip().isdigit() else None
if not zone_seed:
    print(f"   FAILED: Could not get zone seed. Response: {r}")
    c.close(); server.terminate(); sys.exit(1)
print(f"   Zone seed: {zone_seed}")

# ── Step 5: Create surface using SE's zone controls (Nauvis as template) ──
step(f"5. Creating surface for {zone_name} (seed={zone_seed})")
lua = (
    f'local mgs=table.deepcopy(game.surfaces["nauvis"].map_gen_settings);'
    f'mgs.seed={zone_seed}; mgs.width=0; mgs.height=0;'
    f'mgs.autoplace_controls=mgs.autoplace_controls or {{}};'
    # Apply ALL zone controls (including SE specials not in Nauvis template)
    f'local z=remote.call("space-exploration","get_zone_from_name",{{zone_name="{zone_name}"}});'
    f'if z and z.controls then '
    f'for k,v in pairs(z.controls) do '
    f'local rn = type(k)=="userdata" and tostring(k) or k;'
    f'if type(v)=="table" and v.frequency and v.size and v.richness then '
    f'local fsr=v.frequency*v.size*v.richness;'
    f'if fsr>0.001 then '
    f'mgs.autoplace_controls[rn]={{frequency=v.frequency,size=v.size,richness=v.richness}};'
    f'end end end end;'
    f'game.create_surface("{zone_name}", mgs);'
    f'rcon.print("SURFACE_CREATED")'
)
r = rcon(c, "/silent-command " + lua)
if "SURFACE_CREATED" not in (r or ""):
    print(f"   FAILED: {r}")
    c.close(); server.terminate(); sys.exit(1)
print("   Surface created!")

# ── Step 6: Generate chunks (fire and forget) ─────────────────────────
step(f"6. Generating chunks (r={radius})")
lua = f'/silent-command local s=game.get_surface("{zone_name}"); s.request_to_generate_chunks({{0,0}}, {radius//32+1}); s.force_generate_chunk_requests(); rcon.print("CHUNKS_REQUESTED")'
r = rcon(c, lua, timeout=60)
if "CHUNKS_REQUESTED" not in (r or ""):
    print(f"   FAILED: {r}")
    c.close(); server.terminate(); sys.exit(1)
print("   Chunks generated. Waiting for entities to spawn...")
time.sleep(3)

# ── Step 7: Count resources ──────────────────────────────────────────
step(f"7. Counting resources in {radius}x{radius} area")
lua = (
    f'local s=game.get_surface("{zone_name}");'
    f'if not s then rcon.print("NO_SURFACE"); return end;'
    f'local r={radius};'
    f's.request_to_generate_chunks({{0,0}}, math.ceil(r/32)+1);'
    f's.force_generate_chunk_requests();'
    # Count after a brief delay (force_generate should be sync)
    f'local a={{{{-r,-r}},{{r,r}}}};'
    f'local c={{}};'
    f'for _,e in pairs(s.find_entities_filtered{{type="resource",area=a}}) do '
    f'local n=e.name;if not c[n] then c[n]={{total=0,patches=0}} end;'
    f'c[n].total=c[n].total+e.amount;c[n].patches=c[n].patches+1 end;'
    f'local wt=s.count_tiles_filtered{{area=a,name="water"}};'
    f'local tt=(2*r)*(2*r);'
    f'local o={{zone="{zone_name}",universe_seed={universe_seed},surface_seed=s.map_gen_settings.seed,'
    f'radius=r,total_tiles=tt,water_tiles=wt,land_tiles=tt-wt,resources=c}};'
    f'rcon.print(helpers.table_to_json(o))'
)
r = rcon(c, "/silent-command " + lua)

if r and r.startswith("{"):
    data = json.loads(r)
    print(f"\n   Surface seed: {data.get('surface_seed')}")
    print(f"   Land: {data.get('land_tiles', 0):,} tiles")
    print(f"   Water: {data.get('water_tiles', 0):,} tiles")
    print(f"\n   Resources:")
    resources = data.get("resources", {})
    if resources:
        for n, i in sorted(resources.items(), key=lambda x: -x[1]["total"]):
            print(f"     {n}: {i['total']:,} ({i['patches']} patches)")
    else:
        print("     (none found - surface may be empty)")

    # Save result
    out = HERE / "results" / f"zone-{zone_name}-r{radius}.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(data, indent=2))
    print(f"\n   Saved: {out}")
else:
    print(f"   Failed: {r[:500] if r else '(empty)'}")

# ── Done ──────────────────────────────────────────────────────────────
step("Done")
c.close()
server.terminate()
server.wait(timeout=10)
