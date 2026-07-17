#!/usr/bin/env bash
# End-to-end verification: generate a real SE map for a seed in Factorio, dump
# its universe, and diff it against the seed finder's generation via compare.lua.
#
#   tools/verify/verify-seed.sh <seed>
#
# Env overrides:
#   FACTORIO_BIN    -> path to the native factorio binary (see ingame_dump.py).
#   SEED_LUA        -> command that runs the repo's Lua interpreter. If unset, uses
#                      ./bin/lua when it runs natively, else the `seedlua` image.
#   SE_ENABLE_K2=1  -> compare against Krastorio2-flavoured generation. Krastorio2
#                      MUST then be enabled in Factorio's mod set too; otherwise
#                      leave it unset and disable K2 in the mod set.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO"

SEED="${1:?usage: verify-seed.sh <seed>}"
DUMP="universe-ingame-${SEED}.json"

# 1) Real-game dump.
python3 tools/verify/ingame_dump.py "$SEED" -o "$DUMP"

# 2) Pick a Lua runner.
if [ -z "${SEED_LUA:-}" ]; then
  if ./bin/lua -v >/dev/null 2>&1; then
    SEED_LUA="./bin/lua"
  else
    # -e SE_ENABLE_K2 forwards the host value so K2 mode reaches the container.
    SEED_LUA="docker run --rm --platform linux/amd64 -e SE_ENABLE_K2 -v ${REPO}:/w -w /w --entrypoint /w/bin/lua-linux-x86_64 seedlua"
  fi
fi

# 3) Compare (compare.lua exits non-zero on any difference).
echo "=== comparing game dump vs seed finder for seed ${SEED} ==="
$SEED_LUA compare.lua "$DUMP" "$SEED"
