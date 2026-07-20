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

declare -a PIDS=()
worker=0

for ((s=0; s<END; s+=RANGE)); do
  E=$((s + RANGE))
  [ $E -gt $END ] && E=$END

  # Skip if output file already exists and has data
  if [ -s "output/seeds_${E}.jsonl" ]; then
    echo "[orch] SKIP $s → $E (already exists)"
    continue
  fi

  # Wait for a slot to free up
  while [ ${#PIDS[@]} -ge $THREADS ]; do
    for i in "${!PIDS[@]}"; do
      if ! kill -0 "${PIDS[$i]}" 2>/dev/null; then
        unset "PIDS[$i]"
      fi
    done
    PIDS=("${PIDS[@]}")  # re-index
    [ ${#PIDS[@]} -ge $THREADS ] && sleep 1
  done
  
  wid=$((worker % THREADS + 1))
  
  echo "[orch] worker $wid: $s → $E (${#PIDS[@]}/$THREADS)"
  docker run --rm --platform linux/arm64 --ulimit stack=1073741824 \
    -v "${PWD}/output:/workspace/output" \
    -e WORKER_ID=$wid \
    -e START_SEED=$s -e END_SEED=$E \
    -e SE_K2=1 \
    -e MIN_NAQ_DV=${MIN_NAQ_DV:-20000} \
    -e MIN_PROD_MODULES=${MIN_PROD_MODULES:-4} \
    seed-search-seedgen 2>&1 &
  PIDS+=($!)
  worker=$((worker + 1))
done

# Wait for remaining jobs
for pid in "${PIDS[@]}"; do
  wait "$pid" 2>/dev/null || true
done

echo "=== Done ==="
ls -la output/seeds_*.jsonl
