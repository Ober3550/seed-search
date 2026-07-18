-- Trace per-zone RNG for a specific body
package.path = "./generator/lua/?.lua;"
package.preload["env"] = function() return require("env_lua") end
package.preload["rng"] = function() return require("rng_lua") end
package.preload["zip"] = function() return {extract=function(_,p) local f=io.open("./se_extracted/"..p,"rb") if f then local d=f:read("*a");f:close();return d end end} end
require("se_env")

local zone_seed = tonumber(arg[1] or "1662216144")
local crng = game.create_random_generator(zone_seed)
local draw = 0
local mt = getmetatable(crng)
local orig_call = mt.__call
mt.__call = function(self, a, b)
    draw = draw + 1
    if a == nil then
        local v = orig_call(self, nil, nil)
        print(string.format("%d: float = %.6f", draw, v))
        return v
    elseif b == nil then
        local v = orig_call(self, a, nil)
        print(string.format("%d: int1(%d) = %d", draw, a, v))
        return v
    else
        local v = orig_call(self, a, b)
        print(string.format("%d: intRange(%d,%d) = %d", draw, a, b, v))
        return v
    end
end

-- ticks_per_day
if crng() < 0.5 then
    _ = crng(60*60*59)
else
    _ = crng(60*60*19)
end

-- temperature
local temp_i = crng(1, #Universe.temperature_tags)
print("temperature = " .. Universe.temperature_tags[temp_i] .. " (idx=" .. temp_i .. ")")

-- water/moisture/trees
local rng_water, rng_moisture, rng_trees = 1, 1, 1
if crng() < 0.75 then
    rng_water = crng(1, 5)
    rng_moisture = rng_water
    if crng() < 0.5 then
        rng_moisture = crng(1, 5)
    end
    rng_trees = rng_moisture
    if crng() < 0.5 then
        rng_trees = crng(1, 5)
    end
end
rng_trees = math.min(rng_trees, crng(1, 5))
print(string.format("water=%s(%d) moisture=%s(%d) trees=%s(%d)",
    Universe.water_tags[rng_water], rng_water,
    Universe.moisture_tags[rng_moisture], rng_moisture,
    Universe.trees_tags[rng_trees], rng_trees))

-- enemy
local enemy_i = crng(1, #Universe.enemy_tags)
print("enemy = " .. Universe.enemy_tags[enemy_i] .. " (idx=" .. enemy_i .. ")")

-- aux
local aux_i = crng(1, #Universe.aux_tags)
print("aux = " .. Universe.aux_tags[aux_i] .. " (idx=" .. aux_i .. ")")

-- cliff
local cliff_i = crng(1, #Universe.cliff_tags)
print("cliff = " .. Universe.cliff_tags[cliff_i] .. " (idx=" .. cliff_i .. ")")
