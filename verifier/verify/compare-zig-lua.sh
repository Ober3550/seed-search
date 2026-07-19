#!/usr/bin/env bash
# Compare Zig and Lua universe generation for correctness and performance.
#
# Usage:
#   verifier/verify/compare-zig-lua.sh [--k2] [--seed START] [--count N]
#
# Defaults: 5 seeds starting at 341, no K2.
# Requires: Zig compiler, Docker with seedlua image.
#
# Output: per-seed correctness check + timing table with ms/seed averages.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO"

# ── args ──────────────────────────────────────────────────────────────
K2=0
START_SEED=341
COUNT=5

while [ $# -gt 0 ]; do
  case "$1" in
    --k2) K2=1 ;;
    --seed) START_SEED="$2"; shift ;;
    --count) COUNT="$2"; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

# ── prerequisites ─────────────────────────────────────────────────────
ZIG_BIN="./generator/zig/seedgen"
if [ ! -x "$ZIG_BIN" ]; then
  echo "Building Zig seedgen..." >&2
  (cd generator/zig && zig build-exe main.zig -O ReleaseFast -femit-bin=seedgen) || exit 1
fi

if ! docker image inspect seedlua >/dev/null 2>&1; then
  echo "ERROR: Docker image 'seedlua' not found. Build it first:" >&2
  echo "  cd runner/native && docker build -t seedlua ." >&2
  exit 1
fi

# ── helpers ───────────────────────────────────────────────────────────
now_ms() { python3 -c 'import time; print(int(time.time() * 1000))'; }

# Write a Lua script that builds the universe for one seed and dumps it
# as JSONL matching the Zig main.zig output format.
gen_lua_script() {
  local seed="$1" out="$2"
  cat > "$out" << 'LUASCRIPT'
package.path = "./generator/lua/?.lua;"
package.preload["env"] = function() return require("env_lua") end
package.preload["rng"] = function() return require("rng_lua") end
package.preload["zip"] = function()
  return {extract=function(_,p)
    local f=io.open("./se_extracted/"..p,"rb")
    if f then local d=f:read("*a");f:close();return d end
  end}
end
require("se_env")

local summarize = require("summarize")
local seed = SEED_PLACEHOLDER
summarize.build_universe(seed)

-- Dump zones: "name|type|seed" strings in storage.zone_index order
local parts = {}
for _, zone in pairs(storage.zone_index) do
  table.insert(parts, string.format("%s|%s|%s", zone.name, zone.type, zone.seed))
end

-- Vault loot (mirrors Ancient.get_next_vault_loot logic)
local loot = {}
local calidus = storage.zones_by_name["Calidus"]
if calidus then
  -- Count non-homeworld planets belonging to Calidus
  local planet_count = 0
  for _, child in pairs(calidus.children) do
    if child.type == "planet" and not child.is_homeworld then
      planet_count = planet_count + 1
    end
  end
  -- Also include tail planets (homesystem-created) not in children
  for _, z in pairs(storage.zone_index) do
    if z.type == "planet" and not z.is_homeworld
       and z.parent and z.parent.name == "Calidus" then
      local found = false
      for _, c in pairs(calidus.children) do
        if c.name == z.name then found = true; break end
      end
      if not found then planet_count = planet_count + 1 end
    end
  end
  for _ = 1, planet_count do
    local m = Ancient.get_next_vault_loot({name="player"})
    if m == "productivity-module-9" then table.insert(loot, "P")
    elseif m == "speed-module-9" then table.insert(loot, "S")
    elseif m == "efficiency-module-9" then table.insert(loot, "E")
    end
  end
end

io.write(string.format('{"s":%d,"l":"%s","z":[', seed, table.concat(loot)))
for i, p in ipairs(parts) do
  if i > 1 then io.write(",") end
  io.write(string.format('"%s"', p))
end
io.write(']}\n')
LUASCRIPT
  # Replace placeholder with actual seed
  sed -i '' "s/SEED_PLACEHOLDER/${seed}/" "$out"
}

# ── per-seed comparison ───────────────────────────────────────────────
compare_seed() {
  local seed="$1" tmpdir="$2"

  # --- Zig ---
  local zig_start zig_ms
  zig_start=$(now_ms)
  START_SEED=$seed COUNT=1 SE_K2=$K2 "$ZIG_BIN" 2>&1 | grep '^{' > "$tmpdir/zig_${seed}.jsonl" || {
    echo "  ZIG ERROR for seed $seed" >&2
    return 1
  }
  zig_ms=$(( $(now_ms) - zig_start ))

  # --- Lua ---
  local lua_script="$tmpdir/lua_${seed}.lua"
  gen_lua_script "$seed" "$lua_script"

  local lua_start lua_ms
  lua_start=$(now_ms)
  docker run --rm --platform linux/amd64 \
    -e SE_ENABLE_K2=$K2 \
    -v "${REPO}:/workspace" \
    -w /workspace \
    --entrypoint /workspace/runner/bin/lua-linux-x86_64 \
    seedlua \
    "/workspace/${lua_script#$REPO/}" \
    2>/dev/null > "$tmpdir/lua_${seed}.jsonl" || {
    echo "  LUA ERROR for seed $seed" >&2
    return 1
  }
  lua_ms=$(( $(now_ms) - lua_start ))

  # --- Compare ---
  python3 -c "
import json, sys

with open('$tmpdir/zig_${seed}.jsonl') as f:
    zig = json.load(f)
with open('$tmpdir/lua_${seed}.jsonl') as f:
    lua = json.load(f)

zig_z = [(z['n'], z['t'], z['s']) for z in zig['z']]
lua_z = []
for zs in lua['z']:
    n, t, s = zs.split('|')
    lua_z.append((n, t, int(s)))

errors = []

if len(zig_z) != len(lua_z):
    errors.append(f'zone count: zig={len(zig_z)} lua={len(lua_z)}')

mismatches = 0
for i in range(min(len(zig_z), len(lua_z))):
    if zig_z[i] != lua_z[i]:
        errors.append(f'zone[{i}] {zig_z[i][0]}: zig={zig_z[i]} lua={lua_z[i]}')
        mismatches += 1
        if mismatches >= 5:
            errors.append('... (truncated)')
            break

if zig.get('l','') != lua.get('l',''):
    errors.append(f'loot: zig={zig.get(\"l\",\"?\")} lua={lua.get(\"l\",\"?\")}')

if errors:
    print(f'FAIL ({len(errors)} issues)')
    for e in errors[:6]: print(f'    {e}')
    sys.exit(1)
else:
    print(f'OK  z={len(zig_z)} loot={zig.get(\"l\",\"?\")}')
    sys.exit(0)
" 2>&1
  local cmp_rc=$?

  echo "${zig_ms} ${lua_ms}"
  return $cmp_rc
}

# ── main ──────────────────────────────────────────────────────────────
echo "=== Zig vs Lua universe comparison ==="
echo "K2:     $([ "$K2" = "1" ] && echo yes || echo no)"
echo "Seeds:  $COUNT consecutive starting at $START_SEED"
echo ""

mkdir -p "${REPO}/tmp"
TMPDIR=$(mktemp -d "${REPO}/tmp/seed-compare.XXXXXX")
trap "rm -rf $TMPDIR" EXIT

PASS=0; FAIL=0
declare -a TIMINGS

for ((i=0; i<COUNT; i++)); do
  SEED=$((START_SEED + i * 2))
  printf "  seed %-5s " "$SEED"

  RESULT=$(compare_seed "$SEED" "$TMPDIR") || true
  RC=$?

  # Last line: timing, rest: status
  TIMING_LINE=$(echo "$RESULT" | tail -1)
  ZIG_MS=$(echo "$TIMING_LINE" | awk '{print $1}')
  LUA_MS=$(echo "$TIMING_LINE" | awk '{print $2}')
  echo "$RESULT" | sed '$d'

  if [ "${RC:-1}" -eq 0 ]; then
    PASS=$((PASS + 1))
    TIMINGS+=("$SEED $ZIG_MS $LUA_MS")
  else
    FAIL=$((FAIL + 1))
    TIMINGS+=("$SEED - -")
  fi
done

echo ""
echo "────────────────────────────────────────────"
echo "  Correct: $PASS / $((PASS + FAIL))"
echo ""
printf "  %-8s %10s %10s\n" "Seed" "Zig (ms)" "Lua (ms)"
echo "  ──────────────────────────────────"
ZIG_TOTAL=0; LUA_TOTAL=0; ZIG_N=0
for t in "${TIMINGS[@]}"; do
  read -r S Z L <<< "$t"
  if [ "$Z" != "-" ]; then
    printf "  %-8s %7s ms %7s ms\n" "$S" "$Z" "$L"
    ZIG_TOTAL=$((ZIG_TOTAL + Z)); LUA_TOTAL=$((LUA_TOTAL + L)); ZIG_N=$((ZIG_N + 1))
  else
    printf "  %-8s %10s %10s\n" "$S" "FAIL" "FAIL"
  fi
done

if [ $ZIG_N -gt 0 ]; then
  ZIG_AVG=$((ZIG_TOTAL / ZIG_N))
  LUA_AVG=$((LUA_TOTAL / ZIG_N))
  printf "  %-8s %7s ms %7s ms\n" "avg" "${ZIG_AVG}" "${LUA_AVG}"
  if [ $ZIG_AVG -gt 0 ]; then
    SPEEDUP=$(python3 -c "print(f'{${LUA_AVG}/${ZIG_AVG}:.1f}x')")
    echo ""
    echo "  Zig is ${SPEEDUP} faster than Lua (Docker x86_64)"
  fi
fi
echo ""

if [ $FAIL -gt 0 ]; then
  echo "FAIL: $FAIL seed(s) had mismatches"
  exit 1
else
  echo "PASS: all $PASS seeds produce identical universes"
  exit 0
fi
