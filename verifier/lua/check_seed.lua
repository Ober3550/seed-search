package.path = "./generator/lua/?.lua;"
package.preload["env"] = function() return require("env_lua") end
package.preload["rng"] = function() return require("rng_lua") end
package.preload["zip"] = function() return {extract=function(_,p) local f=io.open("./se_extracted/"..p,"rb") if f then local d=f:read("*a");f:close();return d end end} end
require("se_env")
local summarize = require("summarize")
local seed = tonumber(arg[1]) or 341
summarize.build_universe(seed)
local n = storage.zones_by_name["Nauvis"]
local c = storage.zones_by_name["Calidus"]
for _, child in ipairs(c.children) do
    if child.type == "planet" then
        local dv = math.ceil(Zone.get_travel_delta_v(n, child))
        local r = math.floor((child.radius or 0) + 0.5)
        print(string.format("planet %s dv=%d r=%d", child.name, dv, r))
        for _, moon in ipairs(child.children or {}) do
            local mdv = math.ceil(Zone.get_travel_delta_v(n, moon))
            local mr = math.floor((moon.radius or 0) + 0.5)
            print(string.format("moon %s dv=%d r=%d", moon.name, mdv, mr))
        end
    end
end
