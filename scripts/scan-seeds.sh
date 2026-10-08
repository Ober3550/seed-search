#!/usr/bin/env bash
# Run (or resume) the full coarse seed scan for one mod config.
#
#   scripts/scan-seeds.sh se|k2se
#
# Settings (environment variables, all optional):
#   WORKERS   parallel seedgen processes        (default: all CPU cores)
#   RANGE     seed-number range lo:hi           (default: 0:4294967296 = everything)
#
# The scan is resumable: stop it with Ctrl-C and run the same command again;
# work is saved every 100k seeds into 1M-seed files under seedlists/<mod>/. When the whole range is
# done the kept seeds are packed into seedlists/<mod>.u32 (4 bytes per seed).
# Expect roughly two days on a 10-core machine for the full range.
set -euo pipefail

MOD="${1:-}"
case "$MOD" in
  se|k2se) ;;
  *) echo "usage: $0 se|k2se" >&2; exit 1 ;;
esac

cd "$(dirname "$0")/.."
command -v node >/dev/null || { echo "node is required (>= 18)" >&2; exit 1; }

SEEDGEN="universe_generator/zig/seedgen"
[ -f "$SEEDGEN.exe" ] && SEEDGEN="$SEEDGEN.exe"
# rebuild when missing or older than the generator's sources
if [ ! -f "$SEEDGEN" ] || [ -n "$(find universe_generator/zig -name '*.zig' -newer "$SEEDGEN" -print -quit)" ]; then
  command -v zig >/dev/null || { echo "zig 0.16 is required to build seedgen" >&2; exit 1; }
  node install.mjs --seedgen-only
fi

ARGS=(--mod "$MOD" --range "${RANGE:-0:4294967296}")
[ -n "${WORKERS:-}" ] && ARGS+=(--workers "$WORKERS")
# seed-scan exits non-zero when interrupted or failed, so the packed list is
# only written once the whole range has been scanned
node scripts/seed-scan.mjs "${ARGS[@]}"
node scripts/seed-scan.mjs --mod "$MOD" --pack
