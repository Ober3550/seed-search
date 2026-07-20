#!/usr/bin/env python3
"""Step-by-step calibration using Factorio --host mode (has a player).
Usage: python3 calibration/host-calibrate.py <zone_name> <universe_seed> <radius>
"""
import sys, os, subprocess, tempfile, time, json
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parent
sys.path.insert(0, str(REPO / "verifier" / "verify"))
from rcon import wait_for_rcon, RconClient

FACTORIO_BIN = "/Applications/factorio.app/Contents/MacOS/factorio"
RCON_PORT = 27717
GAME_PORT = 34717
RCON_PASSWORD = "seedsearch"

def step(msg):
    print(f"\n{'='*60}\n>>> {msg}\n{'='*60}", flush=True)

def rcon(c, cmd):
    """Run RCON command and print result."""
    r = c.command(cmd).strip()
    if r:
        print(f"  <- {r[:500]}")
    return r

# ── Args ──────────────────────────────────────────────────────────────
if len(sys.argv) < 4:
    print("Usage: python3 calibration/host-calibrate.py <zone_name> <universe_seed> <radius>")
    sys.exit(1)

zone_name = sys.argv[1]
universe_seed = int(sys.argv[2])
radius = int(sys.argv[3])

# ── Step 1: Create save ──────────────────────────────────────────────
step(f"1. Creating save for universe seed {universe_seed}")
workdir = Path(tempfile.mkdtemp(prefix="se-host-"))
save_file = workdir / "calib.zip"
mgs_file = workdir / "map-gen-settings.json"
mgs_file.write_text(json.dumps({"seed": universe_seed}))

subprocess.run([FACTORIO_BIN, "--create", str(save_file), "--map-gen-settings", str(mgs_file)],
    check=True, timeout=300, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
print("   Save created.")

# ── Step 2: Launch Factorio host ──────────────────────────────────────
step("2. Launching Factorio host (windowed, with player)")
server = subprocess.Popen([FACTORIO_BIN,
    "--host", str(save_file),
    "--port", str(GAME_PORT),
    "--fullscreen=false", "--window-size", "1024x768"],
    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
print(f"   PID: {server.pid}")

# ── Step 3: Wait for RCON ─────────────────────────────────────────────
step("3. Waiting for RCON (SE takes ~15-20s to init)...")
c = wait_for_rcon("127.0.0.1", RCON_PORT, RCON_PASSWORD, deadline_s=120)
print("   RCON connected!")

# ── Step 4: Enable cheat mode ─────────────────────────────────────────
step("4. Enabling cheat mode")
rcon(c, "/silent-command game.player.cheat_mode=true")
rcon(c, "/silent-command game.player.admin=true")
rcon(c, '/silent-command game.player.print("Cheat mode enabled")')
print("   Done.")

# ── Step 5: Check game state ──────────────────────────────────────────
step("5. Checking game state")
r = rcon(c, "/silent-command rcon.print('players='..#game.players..' player='..tostring(game.player~=nil))")
r = rcon(c, "/silent-command rcon.print('game.tick='..game.tick)")

# ── Step 6: Teleport to zone ──────────────────────────────────────────
step(f"6. Teleporting to zone '{zone_name}'")
rcon(c, f'/silent-command game.player.print("Teleporting to {zone_name}...")')
lua = (
    f'local ok,err=pcall(function() '
    f'remote.call("space-exploration","teleport_to_zone",'
    f'{{zone_name="{zone_name}",player=game.player}}) '
    f'end); '
    f'if ok then rcon.print("TELEPORT_OK") else rcon.print("TELEPORT_ERR: "..tostring(err)) end'
)
r = rcon(c, "/silent-command " + lua)
if "TELEPORT_OK" not in (r or ""):
    print(f"   FAILED: {r}")
    c.close()
    server.terminate()
    sys.exit(1)
print("   Teleported!")

# ── Step 7: Generate chunks ───────────────────────────────────────────
step(f"7. Generating chunks (r={radius})")
rcon(c, f'/silent-command game.player.print("Generating chunks r={radius}...")')
rcon(c, f'/silent-command local s=game.player.surface; s.request_to_generate_chunks({{0,0}},{radius//32+1}); s.force_generate_chunk_requests()')
print("   Chunks requested. Waiting 5s for generation...")
time.sleep(5)

# ── Step 8: Count resources ───────────────────────────────────────────
step(f"8. Counting resources in {radius}x{radius} area")
lua = (
    f'local s=game.player.surface; local r={radius};'
    f'local a={{{{-r,-r}},{{r,r}}}};'
    f'local c={{}};'
    f'for _,e in pairs(s.find_entities_filtered{{type="resource",area=a}}) do '
    f'local n=e.name;if not c[n] then c[n]={{total=0,patches=0}} end;'
    f'c[n].total=c[n].total+e.amount;c[n].patches=c[n].patches+1 end;'
    f'local wt=s.count_tiles_filtered{{area=a,name="water"}};'
    f'local tt=(2*r)*(2*r);'
    f'local o={{zone="{zone_name}",universe_seed={universe_seed},surface_name=s.name,'
    f'surface_seed=s.map_gen_settings.seed,radius=r,'
    f'total_tiles=tt,water_tiles=wt,land_tiles=tt-wt,resources=c}};'
    f'rcon.print(helpers.table_to_json(o))'
)
r = rcon(c, "/silent-command " + lua)

if r and r.startswith("{"):
    data = json.loads(r)
    print(f"\n   Zone: {data['zone']}")
    print(f"   Surface: {data['surface_name']}, seed: {data['surface_seed']}")
    print(f"   Land: {data.get('land_tiles', 0):,} tiles")
    print(f"   Water: {data.get('water_tiles', 0):,} tiles")
    print(f"\n   Resources:")
    for n, i in sorted(data.get("resources", {}).items(), key=lambda x: -x[1]["total"]):
        print(f"     {n}: {i['total']:,} ({i['patches']} patches)")

    # Save
    out = HERE / "results" / f"host-{zone_name}-r{radius}.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(data, indent=2))
    print(f"\n   Saved: {out}")
else:
    print(f"   Failed: {r[:300] if r else '(empty)'}")

# ── Step 9: Done ──────────────────────────────────────────────────────
step("9. Done! Factorio still running - check the window.")
rcon(c, f'/silent-command game.player.print("Calibration complete! {zone_name} r={radius}")')
c.close()
print("\nPress Ctrl+C to shut down Factorio.")
try:
    server.wait()
except KeyboardInterrupt:
    print("\nShutting down...")
    server.terminate()
    server.wait(timeout=10)
