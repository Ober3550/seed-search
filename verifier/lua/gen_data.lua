-- Generate Zig data file from SE mod's universe-raw.lua.
-- Run via Docker: ./runner/bin/lua-linux-x86_64 verifier/lua/gen_data.lua

package.path = "./generator/lua/?.lua;" .. (package.path or "")

package.preload["env"] = function() return require("env_lua") end
package.preload["rng"] = function() return require("rng_lua") end
package.preload["zip"] = function()
    return { extract = function(_, p)
        local f = io.open("./se_extracted/" .. p, "rb")
        if f then local d = f:read("*a"); f:close(); return d end
    end}
end

require("se_env")
local UR = UniverseRaw

local function esc(s)
    if not s then return "null" end
    s = s:gsub("\\", "\\\\"):gsub('"', '\\"')
    return '"' .. s .. '"'
end

local function body(p)
    local rm = p.radius_multiplier
    local rm_str = rm and string.format("%.6f", rm) or "null"
    -- Parse tags into individual fields
    local tag_fields = {temperature="null", water="null", moisture="null", trees="null", aux="null", cliff="null", enemy="null"}
    if p.tags then
        for _, t in ipairs(p.tags) do
            local u = string.find(t, "_")
            local domain = string.sub(t, 1, u-1)
            tag_fields[domain] = '"' .. t .. '"'
        end
    end
    return string.format("    .{ .name=\"%s\", .patron=%s, .primary_resource=%s, .radius_multiplier=%s, .has_biome_replacements=%s, .tag_temperature=%s, .tag_water=%s, .tag_moisture=%s, .tag_trees=%s, .tag_aux=%s, .tag_cliff=%s, .tag_enemy=%s },",
        p.name, esc(p.patron), esc(p.primary_resource), rm_str,
        p.biome_replacements and "true" or "false",
        tag_fields.temperature, tag_fields.water, tag_fields.moisture, tag_fields.trees, tag_fields.aux, tag_fields.cliff, tag_fields.enemy)
end

local lines = {}
local function w(s) table.insert(lines, s) end

w("// Auto-generated from SE 0.7.57 universe-raw.lua.")
w("")
w('pub const Body = struct { name: []const u8, patron: ?[]const u8, primary_resource: ?[]const u8, radius_multiplier: ?f64, has_biome_replacements: bool, tag_temperature: ?[]const u8, tag_water: ?[]const u8, tag_moisture: ?[]const u8, tag_trees: ?[]const u8, tag_aux: ?[]const u8, tag_cliff: ?[]const u8, tag_enemy: ?[]const u8, };')
w("")
w("pub const stars = [_][]const u8{")
for _, s in ipairs(UR.universe.stars) do w('    "' .. s.name .. '",') end
w("};")
w("")
w("pub const space_zones = [_][]const u8{")
for _, z in ipairs(UR.universe.space_zones) do w('    "' .. z.name .. '",') end
w("};")
w("")
w("pub const average_moons_per_planet: f64 = 3;")
w("pub const max_asteroid_belts: u32 = 2;")
w("")

local function emit_pool(name, pool)
    w("pub const " .. name .. " = [_]Body{")
    for _, p in ipairs(pool) do w(body(p)) end
    w("};")
    w("")
end

emit_pool("unassigned_planets", UR.unassigned_planets)
emit_pool("unassigned_moons", UR.unassigned_moons)
emit_pool("unassigned_planets_or_moons", UR.unassigned_planets_or_moons)

for _, special in ipairs({
    {"vulcanite_planets"},
    {"cryonite_moons"},
    {"iridium_moons"},
    {"holmium_moons"},
    {"vitamelange_moons"},
    {"haven_moons"},
}) do
    local pool = UR[special[1]]
    if pool and #pool > 0 then
        w("pub const " .. special[1] .. "_names = [_][]const u8{")
        for _, p in ipairs(pool) do w('    "' .. p.name .. '",') end
        w("};")
        w("")
    end
end

-- All special moons with their radius_multiplier for lookup
w("pub const special_moon_multipliers = [_]struct { name: []const u8, radius_multiplier: f64 }{")
for _, special in ipairs({
    {"vulcanite_planets"},
    {"cryonite_moons"},
    {"iridium_moons"},
    {"holmium_moons"},
    {"vitamelange_moons"},
    {"haven_moons"},
}) do
    local pool = UR[special[1]]
    if pool then
        for _, p in ipairs(pool) do
            local rm = p.radius_multiplier or 0.3
            w(string.format('    .{ .name="%s", .radius_multiplier=%.6f },', p.name, rm))
        end
    end
end
w("};") 
w("")

-- All special pool bodies with their tags for lookup
w("pub const special_bodies = [_]Body{")
for _, special in ipairs({
    {"vulcanite_planets"},
    {"cryonite_moons"},
    {"iridium_moons"},
    {"holmium_moons"},
    {"vitamelange_moons"},
    {"haven_moons"},
}) do
    local pool = UR[special[1]]
    if pool then
        for _, p in ipairs(pool) do w(body(p)) end
    end
end
w("};")
w("")

local f = io.open("generator/zig/data.zig", "w")
f:write(table.concat(lines, "\n"))
f:close()
print("Wrote " .. #lines .. " lines to generator/zig/data.zig")
