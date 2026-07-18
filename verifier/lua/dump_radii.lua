-- Dump raw zone.radius values for all Calidus planets/moons
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
local summarize = require("summarize")
summarize.build_universe(341)

-- Find Calidus star
local calidus = storage.zones_by_name["Calidus"]
print("Calidus children (raw zone.radius):")
for _, child in ipairs(calidus.children) do
    if child.type == "planet" then
        print(string.format("planet %-25s radius=%.2f seed=%d", child.name, child.radius or 0, child.seed))
        for _, moon in ipairs(child.children or {}) do
            print(string.format("  moon %-25s radius=%.2f seed=%d", moon.name, moon.radius or 0, moon.seed))
        end
    end
end
