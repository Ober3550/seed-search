#!/usr/bin/env bash
# Wall-clock time to generate seeds 0..TOTAL across N parallel seedgen workers
# (one per performance core). Default mode (Calidus-only, as bulk generation
# runs). Output discarded — we're timing generation, not I/O.
set -euo pipefail
cd "$(dirname "$0")"
TOTAL="${1:-1000000}"
N="${2:-8}"
K2="${SE_K2:-}"
chunk=$(( TOTAL / N ))
echo "generating seeds 0..$TOTAL across $N workers (chunk $chunk each)${K2:+ [K2]}"
start=$(date +%s.%N)
pids=()
for ((k=0; k<N; k++)); do
  s=$(( k * chunk ))
  e=$(( s + chunk ))
  SE_K2="$K2" START_SEED="$s" END_SEED="$e" ./seedgen >/dev/null 2>&1 &
  pids+=($!)
done
for p in "${pids[@]}"; do wait "$p"; done
end=$(date +%s.%N)
dur=$(echo "$end - $start" | bc)
# actual seeds = TOTAL/2 (seedgen steps by 2)
printf "done in %.2fs  (~%.0f seeds/s over %d workers)\n" "$dur" "$(echo "($TOTAL/2)/$dur" | bc -l)" "$N"
