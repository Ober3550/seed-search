package.path = "./generator/lua/?.lua;"
package.preload["env"] = function() return require("env_lua") end
package.preload["rng"] = function() return require("rng_lua") end
package.preload["zip"] = function() return {extract=function(_,p) local f=io.open("./se_extracted/"..p,"rb") if f then local d=f:read("*a");f:close();return d end end} end
require("se_env")
local summarize = require("summarize")
summarize.build_universe(341)
local n = storage.zones_by_name["Nauvis"]
io.stderr:write(string.format("is_homeworld=%s\n", tostring(n.is_homeworld)))
if n.tags then
    for k,v in pairs(n.tags) do io.stderr:write(string.format("  %s = %s\n", k, v)) end
else
    io.stderr:write("no tags\n")
end
