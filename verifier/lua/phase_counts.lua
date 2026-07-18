package.path = "./generator/?.lua;../generator/?.lua;" .. (package.path or "")
require("se_env")

local orig_create = game.create_random_generator
local global_draws = 0
local phase_draws = {}
local current_phase = "init"

game.create_random_generator = function(s)
    local gen = orig_create(s)
    if s == nil then
        local proxy = {}
        local mt = {
            __call = function(_, a, b)
                global_draws = global_draws + 1
                phase_draws[current_phase] = (phase_draws[current_phase] or 0) + 1
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

-- Patch key functions to track phases
local orig_shuffle = Universe.shuffle
Universe.shuffle = function(tbl)
    current_phase = "shuffle"
    orig_shuffle(tbl)
end

local orig_build = Universe.build
Universe.build = function()
    current_phase = "build"
    orig_build()
end

local summarize = require("summarize")
summarize.build_universe(341)

for phase, count in pairs(phase_draws) do
    print(string.format("%s: %d draws", phase, count))
end
print("TOTAL: " .. global_draws)
