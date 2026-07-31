#!/usr/bin/env bash
# Perf test: generate TOTAL seeds across N workers, writing to Postgres with the
# .env config (SE_K2 + tail filters) applied. Clears seeds first, times the wall
# clock, reports throughput + rows written.  ./benchpg.sh [TOTAL=1000000] [N=8]
#
# NOTE: parallel workers share the zone_name interning table → some name ids may
# be inconsistent (throughput test only; not correctness). See run.sh for the
# single-writer path.
set -euo pipefail
cd "$(dirname "$0")"
ROOT="$(cd ../.. && pwd)"
TOTAL="${1:-1000000}"; N="${2:-8}"
PSQL="${PSQL:-/opt/homebrew/opt/postgresql@15/bin/psql}"

# load .env literally (filters + SE_K2 + PGPASSWORD without $-mangling)
while IFS= read -r line || [ -n "$line" ]; do
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]] || continue
  k="${BASH_REMATCH[1]}"; v="${BASH_REMATCH[2]}"; v="${v%\"}"; v="${v#\"}"; v="${v%\'}"; v="${v#\'}"
  export "$k=$v"
done < "$ROOT/.env"
export DATABASE_URL="${DATABASE_URL:-postgres://postgres@127.0.0.1:5433/space-exploration}"

echo "clearing seed data…"; "$ROOT/db/clear-seeds.sh" >/dev/null
chunk=$(( TOTAL / N ))
echo "generating 0..$TOTAL across $N workers -> Postgres  (K2=${SE_K2:-0}; filters naq=${NAQ_DV_LOW:-0}/${NAQ_DV_HIGH:-0} pl=${PLANETS_LOW:-0}/${PLANETS_HIGH:-0} wp=${WATER_PCT_LOW:-0}/${WATER_PCT_HIGH:-0} ef=${ENEMY_PCT_LOW:-0}/${ENEMY_PCT_HIGH:-0})"

start=$(date +%s.%N)
pids=()
for ((w=0; w<N; w++)); do
  s=$(( w * chunk )); e=$(( s + chunk ))
  START_SEED="$s" END_SEED="$e" ./seedgen >/dev/null 2>&1 &
  pids+=($!)
done
fail=0
for p in "${pids[@]}"; do wait "$p" || fail=$((fail+1)); done
end=$(date +%s.%N)
dur=$(echo "$end - $start" | bc)

printf "\ndone in %.1fs  (~%.0f seeds/s over %d workers)%s\n" \
  "$dur" "$(echo "($TOTAL/2)/$dur" | bc -l)" "$N" \
  "$([ "$fail" -gt 0 ] && echo "  [WARNING: $fail worker(s) exited non-zero]")"
echo "rows written to Postgres:"
"$PSQL" "$DATABASE_URL" -tAc \
  "SELECT 'seeds='||count(*) FROM seeds UNION ALL SELECT 'zone='||count(*) FROM zone UNION ALL SELECT 'zone_resource='||count(*) FROM zone_resource UNION ALL SELECT 'zone_name='||count(*) FROM zone_name;"
