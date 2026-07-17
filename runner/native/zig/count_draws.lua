package.path = "./generator/?.lua;../generator/?.lua;" .. (package.path or "")
require("se_env")
local orig_create = game.create_random_generator
local draw = 0
game.create_random_generator = function(s)
    local gen = orig_create(s)
    if s == nil then
        local proxy = {}
        local mt = { __call = function(_, a, b) draw = draw + 1; if a == nil then return gen() end; if b == nil then return gen(a) end; return gen(a, b) end }
        setmetatable(proxy, mt)
        return proxy
    end
    return gen
end
local summarize = require("summarize")
summarize.build_universe(341)
print("DRAWS_BEFORE_SEEDS=" .. draw)
print("ZONES=" .. #storage.zone_index)
