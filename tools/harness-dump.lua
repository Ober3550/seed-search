#!/usr/bin/env lua
-- Dump THIS harness's generated universe for a seed, in the same JSON schema as
-- tools/ingame-dump.lua. Useful as a reference to eyeball, and to self-test
-- compare.lua (comparing a harness dump against the same seed must be perfect).
--
--   bin/lua tools/harness-dump.lua <seed> [outfile.json]
--
-- (run bin/lua through the seedlua docker image on Apple Silicon.)

package.path = './?.lua;' .. package.path
require('se_env')
local summarize = require('summarize')
local json = require('json')

local seed = math.floor(tonumber(arg[1]) or error('usage: harness-dump.lua <seed> [outfile]'))
local outfile = arg[2] or ('universe-dump-' .. seed .. '.json')

summarize.build_universe(seed)

local out = { map_seed = seed, zones = {} }
for _, z in pairs(storage.zone_index) do
    out.zones[#out.zones + 1] = {
        name = z.name,
        type = z.type,
        index = z.index,
        radius = z.radius,
        seed = z.seed,
        parent = z.parent and z.parent.name or nil,
    }
end

local f = assert(io.open(outfile, 'w'))
f:write(json.encode(out))
f:close()
io.stderr:write(string.format('wrote %d zones for seed %d to %s\n', #out.zones, seed, outfile))
