-- Capture global RNG draws at the zone seed assignment point
package.path = "./generator/?.lua;../generator/?.lua;" .. (package.path or "")
require("se_env")

local orig_create = game.create_random_generator
local global_draws = 0

game.create_random_generator = function(s)
    local gen = orig_create(s)
    if s == nil then
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
    return gen
end

-- Hook into the zone seed assignment loop
local orig_build = Universe.build
Universe.build = function()
    -- Patch the seed assignment to capture the count
    local orig_pairs = pairs
    orig_build()
end

local summarize = require("summarize")
summarize.build_universe(341)

print("GLOBAL_RNG_DRAWS=" .. global_draws)

-- Also print zone seed assignment RNG calls count
-- From the code: for _, zone in pairs(zone_index) do zone.seed = storage.universe_rng(4294967295) end
-- So seeds use draws 4652 - 1270 - homesystem_draws ... hmm
print("ZONES=" .. #storage.zone_index)
-- Zone seeds = 1270 draws
print("DRAWS_BEFORE_HOMESYSTEM=" .. (global_draws - 1270)) -- rough estimate
