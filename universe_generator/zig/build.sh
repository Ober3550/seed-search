#!/usr/bin/env bash
# Build the universe generator (seedgen). Links libpq for the direct-to-Postgres
# writer (main.zig / pg.zig, enabled at runtime by DATABASE_URL).
set -euo pipefail
cd "$(dirname "$0")"
# find libpq via pg_config (fall back to the Homebrew keg)
PATH="$PATH:/opt/homebrew/opt/postgresql@15/bin:/usr/local/opt/postgresql@15/bin"
INC="$(pg_config --includedir 2>/dev/null || echo /opt/homebrew/opt/postgresql@15/include)"
LIB="$(pg_config --libdir     2>/dev/null || echo /opt/homebrew/opt/postgresql@15/lib)"
zig build-exe main.zig -O ReleaseFast -femit-bin=seedgen -lc \
  -I"$INC" -L"$LIB" -lpq
echo "built ./seedgen (libpq: $LIB)"
