#!/usr/bin/env bash
# Clear the generated seed DATA for a fresh test run, KEEPING the static
# dictionaries. Truncates: seeds, zone, zone_resource, zone_name.
# Keeps: resource, enum_value, meta (the enums / code space).
#
# zone_name IS cleared: the generator re-interns names from id 0 each run, so a
# stale zone_name would mismatch the new ids. resource/enum_value are re-upserted
# (ON CONFLICT DO NOTHING) by the generator anyway, so they're safe to keep.
#
# Targets Cloud SQL via the proxy by default; override with DATABASE_URL.
#   ./db/clear-seeds.sh                       # clear Cloud SQL (via 127.0.0.1:5433)
#   DATABASE_URL=postgres://postgres@127.0.0.1:55432/seedsearch ./db/clear-seeds.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PSQL="${PSQL:-/opt/homebrew/opt/postgresql@15/bin/psql}"
URL="${DATABASE_URL:-postgres://postgres@127.0.0.1:5433/space-exploration}"

# password from .env (literal — the double-quoted value contains a `$`)
if [ -z "${PGPASSWORD:-}" ]; then
  export PGPASSWORD="$(grep -E '^[[:space:]]*PGPASSWORD=' "$ROOT/.env" | head -1 \
    | sed -E 's/^[[:space:]]*PGPASSWORD=//; s/^"//; s/"$//')"
fi

echo "before: $("$PSQL" "$URL" -tAc "SELECT 'seeds='||count(*) FROM seeds")"
"$PSQL" "$URL" -v ON_ERROR_STOP=1 -c \
  "TRUNCATE seeds, zone, zone_resource, zone_name CASCADE;"
echo "after:  $("$PSQL" "$URL" -tAc "SELECT 'seeds='||count(*) FROM seeds")  (kept: resource, enum_value, meta)"
