#!/bin/bash
# Quick test: compare Zig delta-v with Lua for a given seed
SEED=${1:-341}
cd "$(dirname "$0")/.."
REPO=$(pwd)

# Zig
START_SEED=$SEED COUNT=1 SE_K2=1 ./generator/zig/seedgen 2>&1 > /dev/null | grep '^{' > /tmp/zig_dv_test.jsonl

# Lua
docker run --rm --platform linux/amd64 -v "$REPO":/workspace -w /workspace -e SE_ENABLE_K2=1 ubuntu:22.04 /bin/bash -c \
  "apt-get update -qq && apt-get install -y -qq libreadline8 libcurl4 >/dev/null 2>&1 && ./runner/bin/lua-linux-x86_64 -e \"
package.path = './generator/lua/?.lua;'
package.preload['env'] = function() return require('env_lua') end
package.preload['rng'] = function() return require('rng_lua') end
package.preload['zip'] = function() return {extract=function(_,p) local f=io.open('./se_extracted/'..p,'rb') if f then local d=f:read('*a');f:close();return d end end} end
require('se_env')
local summarize = require('summarize')
summarize.build_universe($SEED)
local n = storage.zones_by_name['Nauvis']
local c = storage.zones_by_name['Calidus']
for _, child in ipairs(c.children) do
    if child.type == 'planet' then
        local dv = math.ceil(Zone.get_travel_delta_v(n, child))
        print(string.format('planet %s dv=%d', child.name, dv))
        for _, moon in ipairs(child.children or {}) do
            local mdv = math.ceil(Zone.get_travel_delta_v(n, moon))
            print(string.format('moon %s dv=%d', moon.name, mdv))
        end
    end
end
\"" 2>/dev/null > /tmp/lua_dv_test.txt

python3 << PYEOF
import json, re
zig = json.load(open('/tmp/zig_dv_test.jsonl'))
lua_text = open('/tmp/lua_dv_test.txt').read()
ok = 0; bad = 0
for z in zig['z']:
    if z.get('dv',0) > 0:
        m = re.search(rf'{z["t"]}\s+{z["n"]}\s+dv=(\d+)', lua_text)
        if m:
            if int(m.group(1)) == z['dv']: ok += 1
            else: bad += 1; print(f'  {z["n"]}: zig={z["dv"]} lua={m.group(1)}')
print(f'Seed $SEED: {ok}/{ok+bad} delta-v match')
PYEOF
