package.path = "./generator/?.lua;../generator/?.lua;" .. (package.path or "")
require("se_env")

local orig_create = game.create_random_generator
local rng_call_count = 0

game.create_random_generator = function(seed)
    local gen = orig_create(seed)
    local mt = getmetatable(gen)
    local orig_call = mt.__call
    mt.__call = function(self, a, b)
        rng_call_count = rng_call_count + 1
        return orig_call(self, a, b)
    end
    return gen
end

local summarize = require("summarize")
summarize.build_universe(341)

print("Total RNG draws: " .. rng_call_count)
