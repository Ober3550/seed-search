#!/usr/bin/env bash
# Headless import + analyze of the Factorio arm64 slice, then run a post-script.
# Usage: ./run-headless.sh [postScript.java]     (default: ExportSpotNoise.java)
set -euo pipefail

ROOT="/Users/olivermainey/Workspace/seed-search"
HEADLESS="/opt/homebrew/Cellar/ghidra/12.1.2/libexec/support/analyzeHeadless"
PROJDIR="$ROOT/ghidra/project"
PROJNAME="factorio-surface-gen"
BIN="$ROOT/ghidra/factorio-arm64"
SCRIPTS="$ROOT/ghidra/scripts"
POST="${1:-ExportSpotNoise.java}"

# Give the JVM plenty of heap for a 100MB binary.
# (analyzeHeadless reads GHIDRA_HEADLESS_MAXMEM, not MAXMEM.)
export GHIDRA_HEADLESS_MAXMEM=12G

"$HEADLESS" "$PROJDIR" "$PROJNAME" \
  -import "$BIN" \
  -overwrite \
  -scriptPath "$SCRIPTS" \
  -postScript "$POST" \
  -log "$ROOT/ghidra/headless.log" \
  -scriptlog "$ROOT/ghidra/headless-script.log"
