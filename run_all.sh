#!/bin/bash
# Run seedgen across multiple 100K ranges in parallel.
# Usage: ./run_all.sh [START] [END] [THREADS]
#   START   First seed (default: 341)
#   END     Last seed (default: 1000000)
#   THREADS Max parallel containers (default: CPU cores)
set -e
cd "$(dirname "$0")"

START=${1:-341}
END=${2:-1000000}
THREADS=${3:-$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)}
RANGE=100000

echo "=== seedgen: seeds $START → $END, $THREADS threads ==="

# Ensure output dir exists
mkdir -p output

# Launch one container per 100K range, up to THREADS at a time
active=0
for ((s=START; s<=END; s+=RANGE)); do
  # Wait if at max threads
  while [ $active -ge $THREADS ]; do
    wait -n 2>/dev/null || true
    active=$((active - 1))
  done
  
  BUCKET=$(( ((s + RANGE - 1) / RANGE) * RANGE ))
  [ $BUCKET -gt $END ] && BUCKET=$END
  
  COUNT=$((BUCKET - s))
  [ $COUNT -le 0 ] && continue
  
  echo "[orch] Starting $s → $((s + COUNT)) ($(( active + 1 ))/$THREADS)"
  docker compose run --rm -e START_SEED=$s -e COUNT=$COUNT seedgen 2>&1 | grep '^\[' &
  active=$((active + 1))
done

# Wait for remaining jobs
wait
echo "=== Done ==="
ls -la output/seeds_*.jsonl
