#!/usr/bin/env lua
-- Compare a real in-game universe dump against this harness's generation for the
-- same seed. This is the ground-truth check that the seed finder reproduces the
-- game: every zone's `seed` is drawn sequentially from the global universe RNG,
-- so if all zone seeds match by name, the RNG stream ran in perfect lockstep.
--
--   bin/lua compare.lua <dump.json> [seed]
--
-- <dump.json> is produced in-game by tools/ingame-dump.lua. If [seed] is omitted
-- the dump's map_seed is used. On Apple Silicon run bin/lua via the seedlua
-- docker image (see docs/universe-generation.md).
--
-- Exit code 0 = perfect match, 1 = differences found, 2 = usage/IO error.

package.path = './?.lua;' .. package.path
require('se_env')
local summarize = require('summarize')
local json = require('json')

local function die(code, msg)
    io.stderr:write(msg .. '\n')
    os.exit(code)
end

local dump_path = arg[1]
if not dump_path then die(2, 'usage: compare.lua <dump.json> [seed]') end

local f = io.open(dump_path, 'r')
if not f then die(2, 'cannot open ' .. dump_path) end
local ok, ref = pcall(json.decode, f:read('*a'))
f:close()
if not ok then die(2, 'failed to parse JSON: ' .. tostring(ref)) end

-- Accept either { map_seed=, zones={...} } or a bare array of zones.
local ref_zones = ref.zones or ref
local seed = arg[2] and math.floor(tonumber(arg[2])) or ref.map_seed
if not seed then die(2, 'no seed: pass one as argument 2, or include map_seed in the dump') end

-- Normalise a zone's parent. SE stores a body's orbit in `.orbit`, not
-- `.children`, so the in-game dump can't reconstruct orbit parents from
-- child_indexes and leaves them nil. Orbits are always named "<parent> Orbit",
-- so derive the parent from the name when it's missing (applied to both sides).
local function effective_parent(z)
    if z.parent then return z.parent end
    if z.name then
        local base = string.match(z.name, "^(.*) Orbit$")
        if base then return base end
    end
    return nil
end

-- Index the reference by zone name.
local ref_by_name = {}
local ref_count = 0
local ref_dups = 0
for _, z in pairs(ref_zones) do
    if z.name then
        if ref_by_name[z.name] then ref_dups = ref_dups + 1 end
        z.parent = effective_parent(z)
        ref_by_name[z.name] = z
        ref_count = ref_count + 1
    end
end

-- Resources whose per-zone controls (frequency/richness/size) we verify. Must
-- match the RES list in tools/verify/ingame_dump.py.
local RES = {
    "coal", "stone", "iron-ore", "copper-ore", "crude-oil", "uranium-ore",
    "se-vulcanite", "se-cryonite", "se-vitamelange", "se-holmium-ore", "se-beryllium-ore", "se-iridium-ore",
    "se-water-ice", "se-methane-ice", "se-naquium-ore", "kr-imersite", "kr-rare-metal-ore", "kr-mineral-water",
}

-- Pull {f,r,s} for each RES from a live zone's controls table.
local function our_controls(zone)
    local out = {}
    if zone.controls then
        for _, rn in ipairs(RES) do
            local c = zone.controls[rn]
            if type(c) == "table" then
                out[rn] = { f = c.frequency, r = c.richness, s = c.size }
            end
        end
    end
    return out
end

-- Generate our universe for the same seed.
summarize.build_universe(seed)
local our_by_name = {}
local our_count = 0
for _, z in pairs(storage.zone_index) do
    our_by_name[z.name] = {
        name = z.name,
        type = z.type,
        radius = z.radius,
        seed = z.seed,
        parent = z.parent and z.parent.name or effective_parent(z),
        controls = our_controls(z),
        is_homeworld = z.is_homeworld or false,
    }
    our_count = our_count + 1
end

-- Float compare for radius (JSON may round; RNG-derived values should be exact).
local function radius_equal(a, b)
    if a == nil and b == nil then return true end
    if a == nil or b == nil then return false end
    return math.abs(a - b) <= 1e-6 * (1 + math.abs(a))
end

-- Control values are RNG-derived floats; match to a small relative tolerance to
-- absorb JSON rounding on either side.
local function num_equal(a, b)
    a = a or 0; b = b or 0
    return math.abs(a - b) <= 1e-4 * (1 + math.abs(a))
end

local only_in_ref, only_in_ours = {}, {}
local mism_seed, mism_type, mism_parent, mism_radius, mism_control = {}, {}, {}, {}, {}
local control_fields_checked = 0
local per_resource_mism = {}  -- resource -> count of zones with a control mismatch
local matched = 0

for name, rz in pairs(ref_by_name) do
    local oz = our_by_name[name]
    if not oz then
        table.insert(only_in_ref, name)
    else
        matched = matched + 1
        if rz.seed ~= oz.seed then
            table.insert(mism_seed, string.format('%s: game=%s harness=%s', name, tostring(rz.seed), tostring(oz.seed)))
        end
        if rz.type ~= oz.type then
            table.insert(mism_type, string.format('%s: game=%s harness=%s', name, tostring(rz.type), tostring(oz.type)))
        end
        if rz.parent ~= oz.parent then
            table.insert(mism_parent, string.format('%s: game=%s harness=%s', name, tostring(rz.parent), tostring(oz.parent)))
        end
        if not radius_equal(rz.radius, oz.radius) then
            table.insert(mism_radius, string.format('%s: game=%s harness=%s', name, tostring(rz.radius), tostring(oz.radius)))
        end
        -- Resource controls: compare f/r/s per resource present on either side.
        -- Skip the homeworld: in-game Nauvis' ground resources come from the live
        -- starting surface's map-gen autoplace controls, not universe generation,
        -- so the finder does not (and need not) model them.
        local rc, oc = rz.controls or {}, oz.controls or {}
        if oz.is_homeworld then rc, oc = {}, {} end
        for _, rn in ipairs(RES) do
            local g, h = rc[rn], oc[rn]
            if g or h then
                g = g or {}; h = h or {}
                for _, f in ipairs({ "f", "r", "s" }) do
                    control_fields_checked = control_fields_checked + 1
                    if not num_equal(g[f], h[f]) then
                        per_resource_mism[rn] = (per_resource_mism[rn] or 0) + 1
                        table.insert(mism_control, string.format('%s.%s.%s: game=%s harness=%s',
                            name, rn, f, tostring(g[f]), tostring(h[f])))
                    end
                end
            end
        end
    end
end
for name in pairs(our_by_name) do
    if not ref_by_name[name] then table.insert(only_in_ours, name) end
end

table.sort(only_in_ref); table.sort(only_in_ours)
table.sort(mism_seed); table.sort(mism_type); table.sort(mism_parent); table.sort(mism_radius)
table.sort(mism_control)

local function section(title, list, limit)
    print(string.format('%s: %d', title, #list))
    limit = limit or 20
    for i = 1, math.min(limit, #list) do print('    ' .. list[i]) end
    if #list > limit then print(string.format('    ... and %d more', #list - limit)) end
end

print('=== universe comparison ===')
print(string.format('seed:              %d%s', seed, arg[2] and ' (override)' or ' (from dump)'))
print(string.format('reference zones:   %d%s', ref_count, ref_dups > 0 and (' (' .. ref_dups .. ' duplicate names!)') or ''))
print(string.format('harness zones:     %d', our_count))
print(string.format('matched by name:   %d', matched))
print()
section('only in game (missing from harness)', only_in_ref)
section('only in harness (extra)', only_in_ours)
print()
section('SEED mismatches', mism_seed)
section('type mismatches', mism_type)
section('parent mismatches', mism_parent)
section('radius mismatches', mism_radius)
print()
print(string.format('resource control fields checked: %d', control_fields_checked))
section('resource CONTROL mismatches (zone.resource.field)', mism_control)
if next(per_resource_mism) then
    local rows = {}
    for rn, c in pairs(per_resource_mism) do rows[#rows + 1] = string.format('%s (%d)', rn, c) end
    table.sort(rows)
    print('  by resource: ' .. table.concat(rows, ', '))
end
print()

local perfect = #only_in_ref == 0 and #only_in_ours == 0
    and #mism_seed == 0 and #mism_type == 0 and #mism_parent == 0 and #mism_radius == 0
    and #mism_control == 0

if perfect then
    print('VERDICT: PERFECT — every zone matches, the RNG stream is in lockstep.')
    os.exit(0)
elseif #mism_seed == matched and matched > 0 then
    print('VERDICT: ALL SEEDS DIFFER — the RNG desynced from the very first draw.')
    print('  Likely the seed value or its mapping into the generator is wrong')
    print('  (try passing the seed explicitly, or check game.create_random_generator seeding).')
    os.exit(1)
else
    print('VERDICT: DIFFERENCES FOUND (see above).')
    print('  A structural diff (only-in-* / parent) means the global stream desynced;')
    print('  isolated seed mismatches localise where. Same set but wrong per-zone seeds')
    print('  means an earlier zone consumed a different number of draws.')
    os.exit(1)
end
