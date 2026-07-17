#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load local environment overrides if present.
if [ -f "${REPO}/.env" ]; then
    set -a
    source "${REPO}/.env"
    set +a
fi

cd "${REPO}/runner" && ./bin/lua manager.lua
