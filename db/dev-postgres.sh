#!/usr/bin/env bash
# Local Postgres for dev, standing in for Cloud SQL until creds land.
# Connect with the printed DATABASE_URL (Cloud SQL is a drop-in: same URL shape).
#
#   ./db/dev-postgres.sh start|stop|psql|reset|url
#
# Notes:
#  - TCP on 127.0.0.1:55432 (macOS unix-socket paths are capped at 103 bytes, so
#    we keep the socket dir short and connect over TCP).
#  - Data dir is repo-local .pgdata/ (gitignored), so it persists across sessions.
set -euo pipefail
PGBIN="${PGBIN:-/opt/homebrew/opt/postgresql@15/bin}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PGDATA="$ROOT/.pgdata"
PORT="${PGPORT:-55432}"
SOCK=/tmp/ss_pg
DB="${PGDATABASE:-seedsearch}"
URL="postgres://postgres@127.0.0.1:$PORT/$DB"

case "${1:-start}" in
  start)
    mkdir -p "$SOCK"
    [ -f "$PGDATA/PG_VERSION" ] || "$PGBIN/initdb" -U postgres -D "$PGDATA" --auth=trust >/dev/null
    "$PGBIN/pg_ctl" -D "$PGDATA" -o "-p $PORT -k $SOCK -c listen_addresses=127.0.0.1" \
      -l "$PGDATA/server.log" -w start
    "$PGBIN/psql" -h 127.0.0.1 -p "$PORT" -U postgres -d postgres -tAc \
      "SELECT 1 FROM pg_database WHERE datname='$DB'" | grep -q 1 \
      || "$PGBIN/createdb" -h 127.0.0.1 -p "$PORT" -U postgres "$DB"
    "$PGBIN/psql" "$URL" -v ON_ERROR_STOP=1 -qf "$ROOT/db/schema.sql" >/dev/null
    echo "up. DATABASE_URL=$URL" ;;
  stop)  "$PGBIN/pg_ctl" -D "$PGDATA" -w stop ;;
  psql)  shift; exec "$PGBIN/psql" "$URL" "$@" ;;
  url)   echo "$URL" ;;
  reset) "$PGBIN/psql" "$URL" -v ON_ERROR_STOP=1 -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" \
           && "$PGBIN/psql" "$URL" -qf "$ROOT/db/schema.sql" && echo "reset." ;;
  *) echo "usage: $0 start|stop|psql|reset|url" >&2; exit 1 ;;
esac
