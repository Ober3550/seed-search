-- Dump resource settings to understand data needed for Zig port
package.path = "./generator/lua/?.lua;"
package.preload["env"] = function() return require("env_lua") end
package.preload["rng"] = function() return require("rng_lua") end
package.preload["zip"] = function()
    return { extract = function(_, p)
        local f = io.open("./se_extracted/" .. p, "rb")
        if f then local d = f:read("*a"); f:close(); return d end
    end}
end
require("se_env")
local summarize = require("summarize")
summarize.build_universe(341)

local resource_settings = storage.resources_and_controls.resource_settings
local resource_order = Universe.resource_order

print("=== Resource order ===")
for i, name in ipairs(resource_order) do
    print(string.format("%2d: %s", i, name))
end

print("\n=== Resource settings (key fields) ===")
for name, setting in pairs(resource_settings) do
    local fields = {}
    if setting.can_be_primary then table.insert(fields, "can_be_primary") end
    if setting.tags_required_for_primary then
        table.insert(fields, "tags_for_primary=" .. table.concat(setting.tags_required_for_primary, ","))
    end
    if setting.tags_required_for_presence then
        table.insert(fields, "tags_for_presence=" .. table.concat(setting.tags_required_for_presence, ","))
    end
    if setting.core_fragment then table.insert(fields, "core_fragment=" .. setting.core_fragment) end
    if setting.allowed_for_zone then
        local zones = {}
        for k,_ in pairs(setting.allowed_for_zone) do table.insert(zones, k) end
        table.insert(fields, "allowed=" .. table.concat(zones, ","))
    end
    print(string.format("  %-25s %s", name, table.concat(fields, " ")))
end

print("\n=== Example zone controls (Agni) ===")
local agni = storage.zones_by_name["Agni"]
if agni then
    print(string.format("Agni primary_resource=%s", agni.primary_resource or "nil"))
    print("Controls:")
    for name, control in pairs(agni.controls or {}) do
        if control.frequency and control.size and control.richness then
            local fsr = control.frequency * control.size * control.richness
            print(string.format("  %-25s freq=%.6f size=%.6f rich=%.6f fsr=%.6f",
                name, control.frequency, control.size, control.richness, fsr))
        end
    end
end
