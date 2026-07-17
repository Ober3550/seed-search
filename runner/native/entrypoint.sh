#!/usr/bin/env bash
# Entrypoint for the seedlua-native Docker image (ARM64 native).
#
# Usage:
#   docker run --rm --platform linux/arm64 \
#     -v "$PWD/runner/output:/w/runner/output" \
#     seedlua-native chunk 0
#
#   docker run --rm --platform linux/arm64 seedlua-native bench 10
#
#   docker run --rm --platform linux/arm64 seedlua-native unpack runner/output/universe-0000.bin
set -euo pipefail

export LUA_PATH="./generator/?.lua;./?.lua;${LUA_PATH:-}"

CMD="${1:-help}"
shift || true

case "$CMD" in
    chunk)
        CHUNK="${1:-0}"
        echo "[seedlua-native] Chunk ${CHUNK} — $(date -Iseconds 2>/dev/null || date)"
        mkdir -p runner/output
        START=$(date +%s 2>/dev/null || echo 0)
        lua5.2 -e 'require("compat")' generator/generate.lua "$CHUNK"
        END=$(date +%s 2>/dev/null || echo 0)
        ELAPSED=$((END - START))
        OUTFILE="runner/output/universe-$(printf '%04x' "$CHUNK").bin"
        if [ -f "$OUTFILE" ]; then
            SIZE=$(wc -c < "$OUTFILE" | tr -d ' ')
            echo "[seedlua-native] Done: ${OUTFILE} (${SIZE} bytes, ${ELAPSED}s)"
        else
            echo "[seedlua-native] FAILED: no output file"
            exit 1
        fi
        ;;

    bench)
        N="${1:-10}"
        echo "[seedlua-native] Benchmark ${N} chunks ($((N * 32768)) seeds) — $(date -Iseconds 2>/dev/null || date)"
        mkdir -p runner/output
        START=$(date +%s 2>/dev/null || echo 0)
        for i in $(seq 0 $((N - 1))); do
            lua5.2 -e 'require("compat")' generator/generate.lua "$i"
        done
        END=$(date +%s 2>/dev/null || echo 0)
        ELAPSED=$((END - START))
        if [ "$ELAPSED" -eq 0 ]; then ELAPSED=1; fi
        TOTAL_SEEDS=$((N * 32768))
        RATE=$((TOTAL_SEEDS / ELAPSED))
        echo "[seedlua-native] ${N} chunks (${TOTAL_SEEDS} seeds) in ${ELAPSED}s = ${RATE} seeds/s"
        ;;

    unpack)
        FILE="${1:?usage: seedlua unpack <file.bin>}"
        lua5.2 -e 'require("compat")' generator/unpack.lua "$FILE"
        ;;

    lua)
        exec lua5.2 -e 'require("compat")' "$@"
        ;;

    *)
        echo "Usage: seedlua {chunk <n>|bench <n>|unpack <file>|lua <script>}"
        echo ""
        echo "  chunk <n>    Generate one chunk of seeds (32768 seeds)"
        echo "  bench <n>    Benchmark N chunks, report seeds/s"
        echo "  unpack <f>   Unpack a binary universe file to JSON (stdout)"
        echo "  lua <s>      Run a Lua script with compat modules loaded"
        exit 1
        ;;
esac
