#!/usr/bin/env bash
# Run seedgen with the repo .env config ALWAYS applied (tail filters, SE_K2, …),
# writing to Cloud SQL via the auth proxy. Usage:  run.sh [START_SEED] [END_SEED]
#
# .env is loaded LITERALLY (no shell expansion) so values containing `$` — e.g.
# PGPASSWORD — aren't corrupted the way `source .env` corrupts them.
set -euo pipefail
cd "$(dirname "$0")"
ROOT="$(cd ../.. && pwd)"

# literal .env loader: export each KEY=VALUE without expanding the value
while IFS= read -r line || [ -n "$line" ]; do
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]] || continue
  key="${BASH_REMATCH[1]}"; val="${BASH_REMATCH[2]}"
  val="${val%\"}"; val="${val#\"}"; val="${val%\'}"; val="${val#\'}"
  export "$key=$val"
done < "$ROOT/.env"

export DATABASE_URL="${DATABASE_URL:-postgres://postgres@127.0.0.1:5433/space-exploration}"
export START_SEED="${1:-0}" END_SEED="${2:-100000}"
echo "# seedgen START=$START_SEED END=$END_SEED K2=${SE_K2:-0}" \
     "filters naq=${NAQ_DV_LOW:-0}/${NAQ_DV_HIGH:-0} pl=${PLANETS_LOW:-0}/${PLANETS_HIGH:-0}" \
     "wp=${WATER_PCT_LOW:-0}/${WATER_PCT_HIGH:-0} ef=${ENEMY_PCT_LOW:-0}/${ENEMY_PCT_HIGH:-0}"
exec ./seedgen
