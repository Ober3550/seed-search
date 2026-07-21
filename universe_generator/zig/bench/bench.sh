#!/bin/bash
set -e
cd "$(dirname "$0")/../../.."

NUM_SEEDS=${1:-50}
echo "=== SE Universe Generation Benchmark: $NUM_SEEDS seeds ==="
echo ""

# --- Lua (Docker) ---
if command -v docker &>/dev/null && [ -f runner/mods/space-exploration_0.7.57.zip ]; then
    echo "--- Lua (Docker, emulated x86_64) ---"
    mkdir -p se_extracted
    unzip -q -o runner/mods/space-exploration_0.7.57.zip -d se_extracted/

    START=$(date +%s%3N)
    docker run --rm --platform linux/amd64 -v "$(pwd)":/workspace ubuntu:22.04 bash -c '
        apt-get update -qq 2>/dev/null && apt-get install -y -qq libreadline8 libcurl4 2>/dev/null
        cd /workspace
        chmod +x ./runner/bin/lua-linux-x86_64
        ./runner/bin/lua-linux-x86_64 ./runner/native/zig/bench/bench_lua.lua '"$NUM_SEEDS"'
    ' 2>&1
    END=$(date +%s%3N)
    echo "Lua wall time: $((END - START))ms"

    rm -rf se_extracted
else
    echo "--- Lua: SKIP (docker not available) ---"
fi

echo ""

# --- Zig (native) ---
echo "--- Zig (native) ---"
START=$(date +%s%3N)
for i in $(seq 1 $NUM_SEEDS); do
    runner/native/zig/seedgen > /dev/null 2>&1
done
END=$(date +%s%3N)
ZIG_MS=$((END - START))
echo "Zig: $NUM_SEEDS seeds in ${ZIG_MS}ms ($((ZIG_MS * 1000 / NUM_SEEDS))µs/seed)"

echo ""
echo "=== Done ==="
