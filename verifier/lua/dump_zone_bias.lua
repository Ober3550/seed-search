-- Dump resource bias for a specific zone
package.path = "./generator/lua/?.lua;"
package.preload["env"] = function() return require("env_lua") end
package.preload["rng"] = function() return require("rng_lua") end
package.preload["zip"] = function() return {extract=function(_,p) local f=io.open("./se_extracted/"..p,"rb") if f then local d=f:read("*a");f:close();return d end end} end
require("se_env")
local summarize = require("summarize")
summarize.build_universe(341)

local zone_name = arg[1] or "Eris"
local zone = storage.zones_by_name[zone_name]
if not zone then print("zone not found: " .. zone_name); os.exit(1) end

print("Zone: " .. zone.name .. " type=" .. zone.type .. " seed=" .. zone.seed)
print("primary_resource: " .. (zone.primary_resource or "nil"))
print()

-- Dump per-zone RNG bias
local bias_rng = game.create_random_generator(zone.seed)
print("=== Bias RNG values (first 18) ===")
local biases = {}
for i = 1, 18 do
    local v = bias_rng()
    biases[i] = v
    print(string.format("%2d: %.10f", i, v))
end

-- Now dump the actual resource_bias from the zone
print()
print("=== zone.resource_bias (after sorting) ===")
if zone.resource_bias then
    for i, rb in ipairs(zone.ordered_resource_bias) do
        print(string.format("%2d: %-25s base=%.10f ordered=%.10f", i, rb.resource_name, rb.base_bias, rb.ordered_bias))
    end
end

-- Dump actual controls
print()
print("=== zone.controls (non-zero FSR) ===")
if zone.controls then
    for name, c in pairs(zone.controls) do
        if type(c) == "table" and c.frequency then
            local fsr = c.frequency * c.size * c.richness
            if fsr > 0.00001 then
                local norm = 22.02730826300005162466
                print(string.format("%-25s freq=%.6f size=%.6f rich=%.6f fsr=%.6f score=%.6f",
                    name, c.frequency, c.size, c.richness, fsr, fsr/norm))
            end
        end
    end
end
