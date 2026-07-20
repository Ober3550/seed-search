#!/usr/bin/env bash
# calibration/run-custom.sh
# Like run.sh but with custom freq/size/richness for iron/copper/coal.
#
# Usage: ./run-custom.sh <tag> <radius> <water> <iron_freq> <iron_size> <iron_rich> <copper_freq> <copper_size> <copper_rich> <coal_freq> <coal_size> <coal_rich>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS_DIR="$SCRIPT_DIR/results/field-tests"
SAVES_DIR="$SCRIPT_DIR/saves/field-tests"
mkdir -p "$RESULTS_DIR" "$SAVES_DIR"

TAG="${1:?}"
RADIUS="${2:-500}"
WATER="${3:-none}"
IFREQ="${4:-1.0}"; ISIZE="${5:-1.0}"; IRICH="${6:-1.0}"
CFREQ="${7:-1.0}"; CSIZE="${8:-1.0}"; CRICH="${9:-1.0}"
COFREQ="${10:-1.0}"; COSIZE="${11:-1.0}"; CORICH="${12:-1.0}"
SEED=$((RANDOM % 100000))

case "$WATER" in
  none) MOISTURE_BIAS="1.0" ;;
  low)  MOISTURE_BIAS="0.5" ;;
  med)  MOISTURE_BIAS="0.0" ;;
  high) MOISTURE_BIAS="-0.5" ;;
  max)  MOISTURE_BIAS="-1.0" ;;
  *)    echo "Unknown water: $WATER"; exit 1 ;;
esac

# ── Generate map-gen-settings.json ──
SETTINGS_FILE="$SAVES_DIR/map-gen-$TAG.json"
sed \
  -e "s/{{seed}}/$SEED/g" \
  -e "s/{{iron_freq}}/$IFREQ/g" -e "s/{{iron_size}}/$ISIZE/g" -e "s/{{iron_rich}}/$IRICH/g" \
  -e "s/{{copper_freq}}/$CFREQ/g" -e "s/{{copper_size}}/$CSIZE/g" -e "s/{{copper_rich}}/$CRICH/g" \
  -e "s/{{coal_freq}}/$COFREQ/g" -e "s/{{coal_size}}/$COSIZE/g" -e "s/{{coal_rich}}/$CORICH/g" \
  -e "s/{{stone_freq}}/0.0/g" -e "s/{{stone_size}}/0.0/g" -e "s/{{stone_rich}}/0.0/g" \
  -e "s/{{uranium_freq}}/0.0/g" -e "s/{{uranium_size}}/0.0/g" -e "s/{{uranium_rich}}/0.0/g" \
  -e "s/{{oil_freq}}/0.0/g" -e "s/{{oil_size}}/0.0/g" -e "s/{{oil_rich}}/0.0/g" \
  -e "s/{{water_scale}}/0.0/g" -e "s/{{moisture_bias}}/$MOISTURE_BIAS/g" \
  "$SCRIPT_DIR/map-gen-settings.template.json" > "$SETTINGS_FILE"

# ── Create save ──
SAVE_NAME="calib-$TAG"
docker run --rm \
  --entrypoint /opt/factorio/bin/x64/factorio \
  -v "$SAVES_DIR:/saves" \
  factoriotools/factorio:stable \
  --create "/saves/$SAVE_NAME" \
  --map-gen-settings "/saves/map-gen-$TAG.json" \
  --map-gen-seed "$SEED" \
  2>&1 | grep -E "(Done\.|Error)" || true

SAVE_FILE="$SAVES_DIR/$SAVE_NAME.zip"
if [ ! -f "$SAVE_FILE" ]; then
  echo "ERROR: Save not created for $TAG"
  exit 1
fi

# ── Mod (same ore-counter, with radius) ──
MOD_DIR="$SAVES_DIR/mods/ore-counter_1.0.0"
mkdir -p "$MOD_DIR"
cat > "$MOD_DIR/info.json" << 'JSON'
{"name":"ore-counter","version":"1.0.0","title":"Ore Counter","author":"cal","factorio_version":"2.0","dependencies":["base >= 2.0"]}
JSON
cat > "$MOD_DIR/control.lua" << LUA
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
    tag = "$TAG",
    radius = RADIUS,
    total_tiles = total_tiles,
    water_tiles = water_tiles,
    land_tiles = land_tiles,
    resources = counts
  }
  local json = helpers.table_to_json(result)
  helpers.write_file("field-$TAG.json", json, false)
  log("ORE_COUNT_DONE: " .. json)
  game.print("ORE_COUNT_DONE")
  if not global then global = {} end
  global.done = true
end)
LUA

# ── Config ──
CONFIG_DIR="$SAVES_DIR/config"
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_DIR/server-settings.json" << 'JSON'
{"name":"Calib","description":"Field test","tags":[],"max_players":1,"visibility":{"public":false,"lan":false},"allow_commands":"admins-only","autosave_interval":0}
JSON
echo "calib" > "$CONFIG_DIR/rconpw"

# ── Bundle & run ──
TMPDIR="$SAVES_DIR/docker-bundle-$TAG"
rm -rf "$TMPDIR"
mkdir -p "$TMPDIR/saves" "$TMPDIR/mods" "$TMPDIR/config" "$TMPDIR/script-output"
cp "$SAVE_FILE" "$TMPDIR/saves/"
cp -r "$SAVES_DIR/mods/." "$TMPDIR/mods/"
cp "$CONFIG_DIR/server-settings.json" "$TMPDIR/config/"
echo "calib" > "$TMPDIR/config/rconpw"

cat > "$TMPDIR/Dockerfile" << DOCKERFILE
FROM factoriotools/factorio:stable
COPY saves/*.zip /factorio/saves/
COPY mods/ /factorio/mods/
COPY config/ /factorio/config/
ENV LOAD_LATEST_SAVE=false
ENV SAVE_NAME=$SAVE_NAME
DOCKERFILE

IMAGE_TAG="factorio-field-$TAG"
docker build -q -t "$IMAGE_TAG" "$TMPDIR" 2>&1 | tail -1

docker run --rm \
  --name factorio-field \
  -v "$RESULTS_DIR:/factorio/script-output" \
  "$IMAGE_TAG" \
  2>&1 | tee "/tmp/factorio-field-$TAG.log" > /dev/null &

SERVER_PID=$!

for i in $(seq 1 60); do
  if grep -q "ORE_COUNT_DONE" "/tmp/factorio-field-$TAG.log" 2>/dev/null; then
    break
  fi
  if ! kill -0 $SERVER_PID 2>/dev/null; then break; fi
  sleep 2
done

docker stop factorio-field 2>/dev/null || true
wait $SERVER_PID 2>/dev/null || true
docker rmi "$IMAGE_TAG" 2>/dev/null || true

# Copy result
if [ -f "$RESULTS_DIR/field-$TAG.json" ]; then
  python3 -m json.tool "$RESULTS_DIR/field-$TAG.json" 2>/dev/null | head -20
  echo "OK: $TAG"
else
  echo "FAIL: $TAG"
fi
