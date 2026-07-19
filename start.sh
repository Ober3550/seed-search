#!/bin/bash
# Start the seedgen container in detached mode.
# Builds the Linux binary, rebuilds the Docker image, and starts.
set -e
cd "$(dirname "$0")"

echo "=== Building Linux binary ==="
cd generator/zig
zig build-exe main.zig -O ReleaseFast -femit-bin=seedgen -target aarch64-linux-gnu -lc
cd ../..

echo "=== Building Docker image ==="
docker build --platform linux/arm64 -t seedgen -f Dockerfile.zig .

echo "=== Stopping existing container ==="
docker compose down --timeout 1 2>/dev/null || true

echo "=== Starting in detached mode ==="
docker compose up -d

echo "=== Waiting for first log lines... ==="
sleep 5
cat output/progress.log 2>/dev/null || echo "(no output yet, check in 30s)"
echo ""
echo "Monitor:  tail -f output/progress.log"
echo "Results:  ls -la output/seeds_*.jsonl"
