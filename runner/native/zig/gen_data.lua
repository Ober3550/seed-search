-- Generate Zig data file from SE mod's universe-raw.lua.
-- Run: bin/lua runner/native/zig/gen_data.lua

package.path = "./generator/?.lua;../generator/?.lua;" .. (package.path or "")
require("se_env")
local UR = UniverseRaw

local function esc(s)
    if not s then return "null" end
    s = s:gsub("\\", "\\\\"):gsub('"', '\\"')
    return '"' .. s .. '"'
end

local function body(p)
    return string.format("    .{ .name=\"%s\", .patron=%s, .primary_resource=%s, .has_biome_replacements=%s, .has_tags=%s },",
        p.name, esc(p.patron), esc(p.primary_resource),
        p.biome_replacements and "true" or "false",
        p.tags and "true" or "false")
end

local lines = {}
local function w(s) table.insert(lines, s) end

w("// Auto-generated from SE 0.7.57 universe-raw.lua.")
w("")
w('pub const Body = struct { name: []const u8, patron: ?[]const u8, primary_resource: ?[]const u8, has_biome_replacements: bool, has_tags: bool, };')
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
    {"haven_moons"},
    {"vulcanite_planets"},
    {"cryonite_moons"},
    {"iridium_moons"},
    {"holmium_moons"},
    {"vitamelange_moons"},
}) do
    local pool = UR[special[1]]
    if pool and #pool > 0 then
        w("pub const " .. special[1] .. "_names = [_][]const u8{")
        for _, p in ipairs(pool) do w('    "' .. p.name .. '",') end
        w("};")
        w("")
    end
end

local f = io.open("/w/runner/native/zig/data.zig", "w")
f:write(table.concat(lines, "\n"))
f:close()
print("Wrote " .. #lines .. " lines")
