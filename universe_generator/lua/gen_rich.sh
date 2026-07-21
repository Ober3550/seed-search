#!/bin/bash
# Generate rich K2SE summary for seed 343 -> output/rich.json
# Overwrites the file each run. Good for iterating on gen_summary.lua.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO"
docker run --rm --platform linux/amd64 \
    -v "$PWD":/workspace -w /workspace \
    -e SE_ENABLE_K2=1 \
    ubuntu:22.04 /bin/bash -c \
    'apt-get update -qq && apt-get install -y -qq libreadline8 libcurl4 >/dev/null 2>&1 && ./runner/bin/lua-linux-x86_64 generator/lua/gen_summary.lua' 2>/dev/null
echo "Wrote output/rich.json"
python3 -c "
import json
with open('output/rich.json') as f:
    d = json.loads(f.readline())
print(f'seed={d[\"s\"]}  loot=\"{d[\"l\"]}\"  planets={len(d[\"p\"])}  moons={len(d[\"m\"])}  fields={len(d[\"f\"])}')
"
