-- Record ALL RNG draws during Universe.build() for seed 341
package.path = "./generator/?.lua;../generator/?.lua;" .. (package.path or "")
require("se_env")

local orig_create = game.create_random_generator
local total_draws = 0

game.create_random_generator = function(seed)
    local gen = orig_create(seed)
    local proxy = {}
    local mt = {
        __call = function(_, a, b)
            total_draws = total_draws + 1
            if a == nil then return gen() end
            if b == nil then return gen(a) end
            return gen(a, b)
        end
    }
    setmetatable(proxy, mt)
    return proxy
end

local summarize = require("summarize")
summarize.build_universe(341)

-- Dump Calidus children with their seeds and types
local c = storage.zones_by_name["Calidus"]
print("CALIDUS_CHILDREN")
for _, z in ipairs(c.children) do
    print(string.format("  %s|%s|%d", z.name, z.type, z.seed))
end

-- Dump first 20 zone_index entries
print("ZONE_INDEX_FIRST_20")
for i = 1, math.min(20, #storage.zone_index) do
    local z = storage.zone_index[i]
    print(string.format("  %d|%s|%s|%d", i, z.name, z.type, z.seed))
end

print("TOTAL_DRAWS=" .. total_draws)
print("ZONE_COUNT=" .. #storage.zone_index)
