#!/usr/bin/env bash
# Fast terrain-only iteration loop: render the alien-biomes tile map for a
# central patch of Horaerratum (NO ore) and diff it against the live ground
# truth. Usage: ./terrain-check.sh [radius]   (default 250; ~5s. 150 ≈ 2s)
set -euo pipefail
cd "$(dirname "$0")"
R="${1:-250}"
ROOT="$(cd ../.. && pwd)"
SEGEN="$ROOT/surface_generator/zig-out/bin/segen"
GEN="/tmp/hora-biome-gen-r${R}.bmp"

[ -x "$SEGEN" ] || { echo "build segen first: (cd surface_generator && zig build -Doptimize=ReleaseFast)"; exit 1; }

echo "rendering GEN biome patch r=$R ..."
t0=$(date +%s.%N)
"$SEGEN" --horaerratum-biome --radius "$R" --bmp "$GEN" >/dev/null 2>&1
t1=$(date +%s.%N)
printf "  render: %.2fs\n" "$(echo "$t1 - $t0" | bc)"

python3 terrain_3panel.py "$GEN" "terrain-3panel-Horaerratum.png"
