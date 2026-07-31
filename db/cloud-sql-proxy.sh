#!/usr/bin/env bash
# Cloud SQL Auth Proxy for the seed-search instance (Postgres 18, Cloud SQL).
# Exposes the instance on 127.0.0.1:5433 via Application Default Credentials.
#
# Usage:
#   db/cloud-sql-proxy.sh start          # run the proxy (foreground; & to background)
#   export PGPASSWORD="$(db/cloud-sql-proxy.sh password)"
#   export DATABASE_URL="$(db/cloud-sql-proxy.sh url)"
#   ./universe_generator/zig/seedgen     # now writes to Cloud SQL
#
# NOTE: .env stores PGPASSWORD in DOUBLE quotes but the password contains a `$`,
# so `source .env` shell-expands (corrupts) it. Always read it literally — the
# `password` subcommand below does that. (Better: switch .env to SINGLE quotes.)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONN="project-9902a576-feac-4b13-95e:australia-southeast1:space-exploration-explorer"
PORT="${CLOUDSQL_PORT:-5433}"
DB="space-exploration"
PROXY="${CLOUD_SQL_PROXY:-$HOME/google-cloud-sdk/bin/cloud-sql-proxy}"

case "${1:-start}" in
  start)    exec "$PROXY" "$CONN" --port "$PORT" --address 127.0.0.1 ;;
  password) grep -E '^[[:space:]]*PGPASSWORD=' "$ROOT/.env" | head -1 \
              | sed -E 's/^[[:space:]]*PGPASSWORD=//; s/^"//; s/"$//' ;;
  url)      echo "postgres://postgres@127.0.0.1:$PORT/$DB" ;;  # password via PGPASSWORD env
  *) echo "usage: $0 start|password|url" >&2; exit 1 ;;
esac
