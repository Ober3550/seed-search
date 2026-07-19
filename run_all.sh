#!/bin/bash
# Run seedgen across 100K ranges in parallel.
# Usage: ./run_all.sh [END] [THREADS]
#   END     Last seed (default: 1000000)
#   THREADS Max parallel containers (default: CPU cores)
set -e
cd "$(dirname "$0")"

END=${1:-1000000}
THREADS=${2:-$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)}
RANGE=100000

echo "=== seedgen: 0 → $END, $THREADS threads ==="

mkdir -p output

active=0
for ((s=0; s<END; s+=RANGE)); do
  while [ $active -ge $THREADS ]; do
    wait -n 2>/dev/null || true
    active=$((active - 1))
  done
  
  E=$((s + RANGE))
  [ $E -gt $END ] && E=$END
  
  echo "[orch] $s → $E ($(( active + 1 ))/$THREADS)"
  docker compose run --rm -e START_SEED=$s -e END_SEED=$E seedgen 2>&1 | grep '^\[' &
  active=$((active + 1))
done

wait
echo "=== Done ==="
ls -la output/seeds_*.jsonl
