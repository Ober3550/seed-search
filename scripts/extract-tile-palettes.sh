#!/usr/bin/env bash
# Reproduce the authoritative tile-palette dump + per-planet palettes.
#
# Runs the headless game (2.0.77 at /Applications/factorio.app) once with the
# tile-palette-dump mod (data stage), then parses the log into:
#   surface_generator/biome/tiles-dump.json      every tile (name/color/layer/subgroup)
#   surface_generator/biome/planet-tiles.json    per-planet palettes (autoplace tile lists
#                                                from sa-data/planets.json)
#
# Usage: scripts/extract-tile-palettes.sh
# Env:   FACTORIO_BIN   override the game binary path.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FACTORIO_BIN="${FACTORIO_BIN:-/Applications/factorio.app/Contents/MacOS/factorio}"
MOD_SRC="$ROOT/calibration/tile-palette-dump/tile-palette-dump_1.0.0"

RUN="$(mktemp -d)"
trap 'rm -rf "$RUN"' EXIT
mkdir -p "$RUN/mods" "$RUN/write"
cp -R "$MOD_SRC" "$RUN/mods/"
cat > "$RUN/mods/mod-list.json" <<JSON
{ "mods": [ { "name": "base", "enabled": true }, { "name": "tile-palette-dump", "enabled": true } ] }
JSON
cat > "$RUN/config.ini" <<INI
[path]
read-data=$(dirname "$(dirname "$FACTORIO_BIN")")/data
write-data=$RUN/write
INI

"$FACTORIO_BIN" --config "$RUN/config.ini" --mod-directory "$RUN/mods" \
  --create "$RUN/dump.zip" >/dev/null 2>&1

python3 "$ROOT/scripts/extract-tile-palettes.py" "$RUN/write/factorio-current.log"
echo "Done. Regenerate after game updates (add the version to the file headers)."
