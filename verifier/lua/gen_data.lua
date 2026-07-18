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
    return string.format("    .{ .name=\"%s\", .patron=%s, .primary_resource=%s, .radius_multiplier=%s, .has_biome_replacements=%s, .has_tags=%s },",
        p.name, esc(p.patron), esc(p.primary_resource), rm_str,
        p.biome_replacements and "true" or "false",
        p.tags and "true" or "false")
end

local lines = {}
local function w(s) table.insert(lines, s) end

w("// Auto-generated from SE 0.7.57 universe-raw.lua.")
w("")
w('pub const Body = struct { name: []const u8, patron: ?[]const u8, primary_resource: ?[]const u8, radius_multiplier: ?f64, has_biome_replacements: bool, has_tags: bool, };')
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

local f = io.open("generator/zig/data.zig", "w")
f:write(table.concat(lines, "\n"))
f:close()
print("Wrote " .. #lines .. " lines to generator/zig/data.zig")
