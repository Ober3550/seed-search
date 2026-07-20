#!/usr/bin/env bash
# calibration/test-field.sh
# Tests asteroid field resource generation: varies freq/size/richness
# on a fixed area to calibrate FSR → ore count mapping.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS_DIR="$SCRIPT_DIR/results/field-tests"
mkdir -p "$RESULTS_DIR"

# Fixed area
RADIUS=500

# Parameters to test (asteroid field ranges: freq 1-4, size 0-4, rich 0.1-2)
echo "=== Asteroid Field Calibration ==="
echo "Testing freq/size/richness combinations on radius=$RADIUS"
echo ""

# ── Test 1: Vary frequency (hold size=2, rich=1) ──
echo "--- Phase 1: Frequency curve ---"
for freq in 1.0 1.5 2.0 2.5 3.0 3.5 4.0; do
  echo "  freq=$freq size=2 rich=1"
  "$SCRIPT_DIR/run-custom.sh" "freq-${freq}" "$RADIUS" "none" \
    "$freq" "2.0" "1.0" "$freq" "2.0" "1.0" "$freq" "2.0" "1.0" \
    2>/dev/null || true
done

# ── Test 2: Vary size (hold freq=2, rich=1) ──
echo "--- Phase 2: Size curve ---"
for size in 0.5 1.0 2.0 3.0 4.0; do
  echo "  freq=2 size=$size rich=1"
  "$SCRIPT_DIR/run-custom.sh" "size-${size}" "$RADIUS" "none" \
    "2.0" "$size" "1.0" "2.0" "$size" "1.0" "2.0" "$size" "1.0" \
    2>/dev/null || true
done

# ── Test 3: Vary richness (hold freq=2, size=2) ──
echo "--- Phase 3: Richness curve ---"
for rich in 0.1 0.5 1.0 1.5 2.0; do
  echo "  freq=2 size=2 rich=$rich"
  "$SCRIPT_DIR/run-custom.sh" "rich-${rich}" "$RADIUS" "none" \
    "2.0" "2.0" "$rich" "2.0" "2.0" "$rich" "2.0" "2.0" "$rich" \
    2>/dev/null || true
done

echo ""
echo "=== Done ==="
echo "Results in $RESULTS_DIR/"
ls "$RESULTS_DIR/"*.json 2>/dev/null | wc -l | xargs echo "Files:"

# Collect summary
echo ""
echo "=== Summary ==="
for f in "$RESULTS_DIR/"*.json; do
  [ -f "$f" ] || continue
  python3 -c "
import json, sys
d = json.load(open('$f'))
iron = d['resources'].get('iron-ore',{}).get('total',0)
copper = d['resources'].get('copper-ore',{}).get('total',0)
land = d['land_tiles']
print(f\"  {d['tag']:12s} iron={iron:>10,} copper={copper:>10,} land={land:,}\")
" 2>/dev/null || true
done
