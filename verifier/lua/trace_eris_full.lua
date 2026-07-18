-- Trace Eris resource computation by patching universe.lua at runtime
package.path = "./generator/lua/?.lua;"
package.preload["env"] = function() return require("env_lua") end
package.preload["rng"] = function() return require("rng_lua") end
package.preload["zip"] = function() return {extract=function(_,p) local f=io.open("./se_extracted/"..p,"rb") if f then local d=f:read("*a");f:close();return d end end} end
require("se_env")

-- Patch apply_zone_resource_assignments AFTER it's loaded
local orig_apply = Universe.apply_zone_resource_assignments

-- We need to modify the function. Since we can't easily modify the source,
-- we'll wrap the zone.controls computation by hooking math.pow
local captured_eris = {}
local orig_pow = math.pow
math.pow = function(x, y)
    if y == Universe.resource_power then
        -- Find which zone we're processing by checking the call stack
        -- Actually, let's track via a global flag
        if _G._eris_trace_active then
            table.insert(_G._eris_trace_data, x)
        end
    end
    return orig_pow(x, y)
end

-- Hook generate_zone_resource_bias to capture bias values
local orig_gen_bias = Universe.generate_zone_resource_bias
Universe.generate_zone_resource_bias = function(zone)
    orig_gen_bias(zone)
    if zone.name == "Eris" and zone.ordered_resource_bias then
        io.stderr:write("=== Eris bias after generate_zone_resource_bias ===\n")
        for i, bias in ipairs(zone.ordered_resource_bias) do
            io.stderr:write(string.format("%2d: %-25s base=%.10f ordered=%.10f\n",
                i, bias.resource_name, bias.base_bias, bias.ordered_bias))
        end
    end
end

-- Hook the actual apply function to trace
local orig_apply2 = Universe.apply_zone_resource_assignments
Universe.apply_zone_resource_assignments = function(zone)
    if zone.name == "Eris" then
        io.stderr:write(string.format("=== Eris apply_zone_resource_assignments primary=%s ===\n", zone.primary_resource or "nil"))
    end
    orig_apply2(zone)
    if zone.name == "Eris" and zone.controls then
        io.stderr:write("=== Eris final controls ===\n")
        for name, c in pairs(zone.controls) do
            if type(c) == "table" and type(c.frequency) == "number" and type(c.size) == "number" and type(c.richness) == "number" then
                local fsr = c.frequency * c.size * c.richness
                if fsr > 0.00001 then
                    io.stderr:write(string.format("%-25s freq=%.6f size=%.6f rich=%.6f fsr=%.6f score=%.6f\n",
                        name, c.frequency, c.size, c.richness, fsr, fsr/22.02730826300005162466))
                end
            end
        end
    end
end

local summarize = require("summarize")
summarize.build_universe(341)
