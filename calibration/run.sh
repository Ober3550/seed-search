#!/usr/bin/env bash
# calibration/run.sh
# Generates a Factorio surface, counts total ore, outputs JSON.
# Always includes Space Exploration mod. Optionally includes K2.
#
# Usage: ./run.sh <seed> <radius> <water> [freq] [size] [rich] [--k2]
#   water: none, low, med, high, max
#   freq/size/rich: optional overrides (default 1.0)
#   --k2: also include Krastorio 2 mod (requires mod zip)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
RESULTS_DIR="$SCRIPT_DIR/results"
SAVES_DIR="$SCRIPT_DIR/saves"
mkdir -p "$RESULTS_DIR" "$SAVES_DIR"

SEED="${1:?Usage: run.sh <seed> <radius> <water> [freq] [size] [rich] [--k2]}"
RADIUS="${2:-2000}"
WATER="${3:-med}"
IRON_FREQ="${4:-1.0}"; IRON_SIZE="${5:-1.0}"; IRON_RICH="${6:-1.0}"

# Parse --k2 flag
K2_ENABLED=false
for arg in "$@"; do
  if [ "$arg" = "--k2" ]; then K2_ENABLED=true; fi
done

case "$WATER" in
  none) MOISTURE_BIAS="1.0" ;;
  low)  MOISTURE_BIAS="0.5" ;;
  med)  MOISTURE_BIAS="0.0" ;;
  high) MOISTURE_BIAS="-0.5" ;;
  max)  MOISTURE_BIAS="-1.0" ;;
  *)    echo "Unknown water: $WATER"; exit 1 ;;
esac

echo "=== Calibration: seed=$SEED radius=$RADIUS water=$WATER ==="

# ── Generate map-gen-settings.json ──
SETTINGS_FILE="$SAVES_DIR/map-gen-settings-$SEED.json"
sed \
  -e "s/{{seed}}/$SEED/g" \
  -e "s/{{coal_freq}}/$IRON_FREQ/g" -e "s/{{coal_size}}/$IRON_SIZE/g" -e "s/{{coal_rich}}/$IRON_RICH/g" \
  -e "s/{{stone_freq}}/$IRON_FREQ/g" -e "s/{{stone_size}}/$IRON_SIZE/g" -e "s/{{stone_rich}}/$IRON_RICH/g" \
  -e "s/{{copper_freq}}/$IRON_FREQ/g" -e "s/{{copper_size}}/$IRON_SIZE/g" -e "s/{{copper_rich}}/$IRON_RICH/g" \
  -e "s/{{iron_freq}}/$IRON_FREQ/g" -e "s/{{iron_size}}/$IRON_SIZE/g" -e "s/{{iron_rich}}/$IRON_RICH/g" \
  -e "s/{{uranium_freq}}/0.0/g" -e "s/{{uranium_size}}/0.0/g" -e "s/{{uranium_rich}}/0.0/g" \
  -e "s/{{oil_freq}}/0.0/g" -e "s/{{oil_size}}/0.0/g" -e "s/{{oil_rich}}/0.0/g" \
  -e "s/{{water_scale}}/0.0/g" -e "s/{{moisture_bias}}/$MOISTURE_BIAS/g" \
  "$SCRIPT_DIR/map-gen-settings.template.json" > "$SETTINGS_FILE"

# ── Create save file ──
echo "[$(date +%H:%M:%S)] Creating save..."
docker run --rm \
  --entrypoint /opt/factorio/bin/x64/factorio \
  -v "$SAVES_DIR:/saves" \
  factoriotools/factorio:stable \
  --create "/saves/calib-$SEED" \
  --map-gen-settings "/saves/map-gen-settings-$SEED.json" \
  --map-gen-seed "$SEED" \
  2>&1 | grep -E "(Done\.|Error|level.dat)" || true

SAVE_FILE="$SAVES_DIR/calib-$SEED.zip"
if [ ! -f "$SAVE_FILE" ]; then
  echo "ERROR: Save file not created at $SAVE_FILE"
  exit 1
fi

# ── Prepare mods ──
# Always include ore-counter + Space Exploration
MOD_DIR="$SAVES_DIR/mods/ore-counter_1.0.0"
mkdir -p "$MOD_DIR"
cat > "$MOD_DIR/info.json" << 'JSON'
{
  "name": "ore-counter",
  "version": "1.0.0",
  "title": "Ore Counter",
  "author": "calibration",
  "factorio_version": "2.0",
  "dependencies": ["base >= 2.0", "space-exploration >= 0.7.0"]
}
JSON

# Always bundle SE mod
SE_MOD_ZIP="$PROJECT_DIR/runner/mods/space-exploration_0.7.57.zip"
if [ -f "$SE_MOD_ZIP" ]; then
  SE_MOD_DIR="$SAVES_DIR/mods/space-exploration_0.7.57"
  rm -rf "$SE_MOD_DIR"
  mkdir -p "$SE_MOD_DIR"
  unzip -q -o "$SE_MOD_ZIP" -d "$SE_MOD_DIR"
  echo "[$(date +%H:%M:%S)] SE mod bundled"
else
  echo "ERROR: SE mod not found at $SE_MOD_ZIP"
  exit 1
fi

# Optionally bundle K2 mod
if $K2_ENABLED; then
  echo "WARNING: K2 mod not yet available - skipping"
fi

cat > "$MOD_DIR/control.lua" << LUA
-- Count resources and write JSON on startup
local RADIUS = $RADIUS
script.on_event(defines.events.on_tick, function(event)
  if global and global.done then return end
  if game.tick < 120 then return end

  local surface = game.surfaces.nauvis
  local half = RADIUS
  local area = {{-half, -half}, {half, half}}

  local water_tiles = surface.count_tiles_filtered{area=area, name="water"}
  local total_tiles = (2 * half) * (2 * half)
  local land_tiles = total_tiles - water_tiles

  local counts = {}
  local entities = surface.find_entities_filtered{type="resource", area=area}
  for _, e in pairs(entities) do
    local n = e.name
    if not counts[n] then counts[n] = {total = 0, patches = 0} end
    counts[n].total = counts[n].total + e.amount
    counts[n].patches = counts[n].patches + 1
  end

  local result = {
    seed = surface.map_gen_settings.seed,
    radius = RADIUS,
    water = "${WATER}",
    freq = ${IRON_FREQ},
    size = ${IRON_SIZE},
    rich = ${IRON_RICH},
    total_tiles = total_tiles,
    water_tiles = water_tiles,
    land_tiles = land_tiles,
    resources = counts
  }

  local json = helpers.table_to_json(result)
  helpers.write_file("ore-count-" .. tostring(RADIUS) .. ".json", json, false)
  log("ORE_COUNT_DONE: " .. json)
  game.print("ORE_COUNT_DONE")

  if not global then global = {} end
  global.done = true
end)
LUA

# ── Server config ──
CONFIG_DIR="$SAVES_DIR/config"
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_DIR/server-settings.json" << 'JSON'
{
  "name": "Calibration Server",
  "description": "Ore counting calibration",
  "tags": ["calibration"],
  "max_players": 1,
  "visibility": {"public": false, "lan": false},
  "username": "", "password": "", "token": "", "game_password": "",
  "require_user_verification": false,
  "max_upload_in_kilobytes_per_second": 0,
  "max_upload_slots": 0,
  "ignore_player_limit_for_returning_players": false,
  "allow_commands": "admins-only",
  "autosave_interval": 0, "autosave_slots": 0,
  "afk_autokick_interval": 0, "auto_pause": false,
  "only_admins_can_pause": false, "autosave_only_on_server": false,
  "admins": []
}
JSON
echo "calib" > "$CONFIG_DIR/rconpw"

# ── Run server ──
echo "[$(date +%H:%M:%S)] Starting server..."

# Build a temporary Dockerfile to bundle the save + mods into the image
# This avoids macOS volume mount corruption issues
TMPDIR="$SAVES_DIR/docker-bundle"
rm -rf "$TMPDIR"
mkdir -p "$TMPDIR/saves" "$TMPDIR/mods" "$TMPDIR/config" "$TMPDIR/script-output"

cp "$SAVE_FILE" "$TMPDIR/saves/"
cp -r "$SAVES_DIR/mods/." "$TMPDIR/mods/"
cp "$CONFIG_DIR/server-settings.json" "$TMPDIR/config/"
echo "calib" > "$TMPDIR/config/rconpw"

cat > "$TMPDIR/Dockerfile" << DOCKERFILE
FROM factoriotools/factorio:stable
COPY saves/calib-$SEED.zip /factorio/saves/
COPY mods/ /factorio/mods/
COPY config/ /factorio/config/
COPY script-output/ /factorio/script-output/
ENV LOAD_LATEST_SAVE=false
ENV SAVE_NAME=calib-$SEED
DOCKERFILE

IMAGE_TAG="factorio-calib-$SEED"
docker build -q -t "$IMAGE_TAG" "$TMPDIR" 2>&1 | tail -1

TIMEOUT=120
docker run --rm \
  --name factorio-calib \
  -v "$RESULTS_DIR:/factorio/script-output" \
  "$IMAGE_TAG" \
  2>&1 | tee "$RESULTS_DIR/server-$SEED.log" > /dev/null &

SERVER_PID=$!

# Wait for ORE_COUNT_DONE
echo "[$(date +%H:%M:%S)] Waiting for counting..."
for i in $(seq 1 $((TIMEOUT / 2))); do
  if grep -q "ORE_COUNT_DONE" "$RESULTS_DIR/server-$SEED.log" 2>/dev/null; then
    echo "[$(date +%H:%M:%S)] Counting complete!"
    break
  fi
  if ! kill -0 $SERVER_PID 2>/dev/null; then
    echo "[$(date +%H:%M:%S)] Server exited early"
    break
  fi
  sleep 2
done

docker stop factorio-calib 2>/dev/null || true
wait $SERVER_PID 2>/dev/null || true
docker rmi "$IMAGE_TAG" 2>/dev/null || true

# ── Parse results ──
# Save with FSR info in filename
FSR_TAG="f${IRON_FREQ}-s${IRON_SIZE}-r${IRON_RICH}"
SAVE_AS="$RESULTS_DIR/seed-${SEED}-r${RADIUS}-${FSR_TAG}.json"

RESULT_FILE="$RESULTS_DIR/ore-count-$RADIUS.json"
if [ -f "$RESULT_FILE" ]; then
  echo ""
  echo "=== RESULTS: seed=$SEED radius=$RADIUS water=$WATER freq=$IRON_FREQ size=$IRON_SIZE rich=$IRON_RICH ==="
  python3 -m json.tool "$RESULT_FILE" 2>/dev/null || cat "$RESULT_FILE"
  cp "$RESULT_FILE" "$SAVE_AS"
  echo ""
  echo "Saved to $SAVE_AS"
else
  # Fallback: parse from log
  RESULT_LINE=$(grep "ORE_COUNT_DONE:" "$RESULTS_DIR/server-$SEED.log" | head -1)
  if [ -n "$RESULT_LINE" ]; then
    echo ""
    echo "=== RESULTS: seed=$SEED radius=$RADIUS water=$WATER freq=$IRON_FREQ size=$IRON_SIZE rich=$IRON_RICH ==="
    echo "$RESULT_LINE" | sed 's/.*ORE_COUNT_DONE: //' | python3 -m json.tool
    echo "$RESULT_LINE" | sed 's/.*ORE_COUNT_DONE: //' > "$SAVE_AS"
    echo ""
    echo "Saved to $SAVE_AS"
  else
    echo "ERROR: No results file. Server log tail:"
    tail -30 "$RESULTS_DIR/server-$SEED.log"
    exit 1
  fi
fi
