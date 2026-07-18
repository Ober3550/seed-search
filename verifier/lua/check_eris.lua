package.path = "./generator/lua/?.lua;"
package.preload["env"] = function() return require("env_lua") end
package.preload["rng"] = function() return require("rng_lua") end
package.preload["zip"] = function() return {extract=function(_,p) local f=io.open("./se_extracted/"..p,"rb") if f then local d=f:read("*a");f:close();return d end end} end
require("se_env")
local summarize = require("summarize")
summarize.build_universe(341)
local e = storage.zones_by_name["Eris"]
io.stderr:write(string.format("primary_resource=%s\n", e.primary_resource or "nil"))
io.stderr:write(string.format("new_primary_resource=%s\n", e.new_primary_resource or "nil"))
if e.resource_bias then
    io.stderr:write(string.format("resource_bias count: %d\n", table_size(e.resource_bias)))
else
    io.stderr:write("no resource_bias\n")
end
-- Print resource bias entries
if e.resource_bias then
    for name, rb in pairs(e.resource_bias) do
        io.stderr:write(string.format("  %-25s base=%.10f ordered=%.10f\n", name, rb.base_bias, rb.ordered_bias))
    end
end
