#!/usr/bin/env sh
# Bootstrapper for the cross-platform Node installer (macOS / Linux).
# All real work lives in install.mjs — this just locates Node and runs it.
set -e
cd "$(dirname "$0")"
if ! command -v node >/dev/null 2>&1; then
  echo "Node.js (>=18) is required to run the installer." >&2
  echo "Install it from https://nodejs.org/ and re-run ./install.sh" >&2
  exit 1
fi
exec node install.mjs "$@"
