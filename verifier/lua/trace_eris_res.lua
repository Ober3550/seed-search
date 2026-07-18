-- Trace apply_zone_resource_assignments for Eris (all calls)
package.path = "./generator/lua/?.lua;"
package.preload["env"] = function() return require("env_lua") end
package.preload["rng"] = function() return require("rng_lua") end
package.preload["zip"] = function() return {extract=function(_,p) local f=io.open("./se_extracted/"..p,"rb") if f then local d=f:read("*a");f:close();return d end end} end
require("se_env")

local call_count = 0
local orig_apply = Universe.apply_zone_resource_assignments
Universe.apply_zone_resource_assignments = function(zone)
    if zone.name == "Eris" then
        call_count = call_count + 1
        io.stderr:write(string.format("=== Eris call #%d: primary=%s ===\n", call_count, zone.primary_resource or "nil"))
        
        if call_count == 2 and zone.resource_bias then
            io.stderr:write("=== zone.resource_bias ===\n")
            local items = {}
            for name, rb in pairs(zone.resource_bias) do
                table.insert(items, {name=name, base=rb.base_bias, ordered=rb.ordered_bias})
            end
            table.sort(items, function(a,b) return a.base > b.base end)
            for i, item in ipairs(items) do
                io.stderr:write(string.format("%2d: %-25s base=%.10f ordered=%.10f\n", i, item.name, item.base, item.ordered))
            end
        end
        
        if call_count == 2 and zone.controls then
            io.stderr:write("=== zone.controls (non-zero) ===\n")
            for name, c in pairs(zone.controls) do
                if type(c) == "table" and c.frequency and type(c.frequency) == "number" and c.size and type(c.size) == "number" and c.richness and type(c.richness) == "number" then
                    local fsr = c.frequency * c.size * c.richness
                    if fsr > 0.0001 then
                        io.stderr:write(string.format("%-25s freq=%.6f size=%.6f rich=%.6f fsr=%.6f\n",
                            name, c.frequency, c.size, c.richness, fsr))
                    end
                end
            end
        end
    end
    
    orig_apply(zone)
end

local summarize = require("summarize")
summarize.build_universe(341)
io.stderr:write(string.format("Total calls for Eris: %d\n", call_count))
