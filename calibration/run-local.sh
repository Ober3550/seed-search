#!/usr/bin/env bash
# calibration/run-local.sh
# Wrapper around run-local.py — uses local Factorio with SE mod via RCON.
#
# Usage: ./run-local.sh <surface_seed> <radius> <water> [freq] [size] [rich]
#   water: none, low, med, high, max
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$SCRIPT_DIR/run-local.py" "$@"
