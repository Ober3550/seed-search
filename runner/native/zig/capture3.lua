-- Capture global RNG draw count at zone seed assignment
package.path = "./generator/?.lua;../generator/?.lua;" .. (package.path or "")
require("se_env")

local orig_create = game.create_random_generator
local global_draws = 0
local seed_rng = nil -- the global RNG instance

game.create_random_generator = function(s)
    local gen = orig_create(s)
    if s == nil then
        -- This is the global universe RNG (line 289: storage.universe_rng = game.create_random_generator())
        seed_rng = gen
        local proxy = {}
        local mt = {
            __call = function(_, a, b)
                global_draws = global_draws + 1
                if a == nil then return gen() end
                if b == nil then return gen(a) end
                return gen(a, b)
            end
        }
        setmetatable(proxy, mt)
        return proxy
    end
    return gen -- other generators (zone_seed_rng, per-zone) are not wrapped
end

local summarize = require("summarize")
summarize.build_universe(341)

print("GLOBAL_RNG_DRAWS=" .. global_draws)
print("ZONES=" .. #storage.zone_index)
