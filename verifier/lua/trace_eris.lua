-- Trace Eris radius computation in Lua
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

-- Patch moon radius to trace Eris
local orig_create = game.create_random_generator
local draw = 0
game.create_random_generator = function(s)
    local gen = orig_create(s)
    if s == nil then
        local proxy = {}
        local mt = {
            __call = function(_, a, b)
                draw = draw + 1
                if a == nil then
                    local v = gen()
                    -- The actual moon radius call happens deep in Universe code.
                    -- We'll trace after the build instead.
                    return v
                end
                if b == nil then return gen(a) end
                return gen(a, b)
            end
        }
        setmetatable(proxy, mt)
        return proxy
    end
    return gen
end

local summarize = require("summarize")
summarize.build_universe(341)

-- Find Eris zone and print its radius
local eris = storage.zones_by_name["Eris"]
if eris then
    print(string.format("Eris: radius=%.2f seed=%d type=%s", eris.radius or 0, eris.seed, eris.type))
    if eris.parent then
        print(string.format("  parent: %s radius=%.2f", eris.parent.name, eris.parent.radius or 0))
    end
end

-- Also print Nauvis
local nauvis = storage.zones_by_name["Nauvis"]
print(string.format("Nauvis: radius=%.2f", nauvis.radius))
