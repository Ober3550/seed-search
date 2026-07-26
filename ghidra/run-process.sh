#!/usr/bin/env bash
# Run a post-script against the ALREADY-imported+analyzed program in the existing
# Ghidra project — no re-import, no re-analysis (fast). Use this instead of
# run-headless.sh once the binary has been analyzed once.
# Usage: ./run-process.sh [postScript.java]   (default: ExportEntityPlacement.java)
set -euo pipefail

ROOT="/Users/olivermainey/Workspace/seed-search"
HEADLESS="/opt/homebrew/Cellar/ghidra/12.1.2/libexec/support/analyzeHeadless"
PROJDIR="$ROOT/ghidra/project"
PROJNAME="factorio-surface-gen"
SCRIPTS="$ROOT/ghidra/scripts"
POST="${1:-ExportEntityPlacement.java}"

export GHIDRA_HEADLESS_MAXMEM=12G

"$HEADLESS" "$PROJDIR" "$PROJNAME" \
  -process "factorio-arm64" \
  -noanalysis \
  -scriptPath "$SCRIPTS" \
  -postScript "$POST" \
  -log "$ROOT/ghidra/headless.log" \
  -scriptlog "$ROOT/ghidra/headless-script.log"
