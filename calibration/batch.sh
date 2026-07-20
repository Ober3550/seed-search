#!/usr/bin/env bash
# calibration/batch.sh
# Runs multiple calibration tests across different seeds, radii, and water levels.
# Usage: ./batch.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Test matrix
SEEDS=(12345 67890 11111 22222 33333)
RADII=(500 1000 2000)
WATERS=(max high med low none)
FREQ_VALUES=(0.5 1.0 2.0 4.0)

echo "=== Calibration Batch Runner ==="
echo "Seeds: ${SEEDS[*]}"
echo "Radii: ${RADII[*]}"
echo "Waters: ${WATERS[*]}"
echo "Freq multipliers: ${FREQ_VALUES[*]}"
echo ""

# First: baseline runs (default freq=1.0, varying radius/water)
echo "--- Phase 1: Baseline (freq=1.0, varying radius+water) ---"
for seed in "${SEEDS[@]:0:3}"; do
  for radius in "${RADII[@]}"; do
    for water in "${WATERS[@]}"; do
      echo "  seed=$seed radius=$radius water=$water"
      "$SCRIPT_DIR/run.sh" "$seed" "$radius" "$water" 2>/dev/null || echo "    FAILED"
    done
  done
done

echo ""
echo "=== Batch complete ==="
echo "Results in $SCRIPT_DIR/results/"
ls "$SCRIPT_DIR/results/"seed-*.json 2>/dev/null | wc -l | xargs echo "Files:"
