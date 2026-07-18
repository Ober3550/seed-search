-- Quick test: compute Ezra's tags
package.path = "./generator/lua/?.lua;"
package.preload["env"] = function() return require("env_lua") end
package.preload["rng"] = function() return require("rng_lua") end
package.preload["zip"] = function() return {extract=function(_,p) local f=io.open("./se_extracted/"..p,"rb") if f then local d=f:read("*a");f:close();return d end end} end
require("se_env")

-- Replicate inflate_climate_controls for Ezra
local crng = game.create_random_generator(547253870)
local draw = 0
local orig = crng
local mt = getmetatable(crng)
local orig_call = mt.__call
mt.__call = function(self, a, b)
    draw = draw + 1
    if a == nil then
        local v = orig_call(self, nil, nil)
        io.stderr:write(string.format("%d: float = %.6f\n", draw, v))
        return v
    elseif b == nil then
        local v = orig_call(self, a, nil)
        io.stderr:write(string.format("%d: int1(%d) = %d\n", draw, a, v))
        return v
    else
        local v = orig_call(self, a, b)
        io.stderr:write(string.format("%d: intRange(%d,%d) = %d\n", draw, a, b, v))
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
io.stderr:write(string.format("temperature = %s\n", Universe.temperature_tags[temp_i]))

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
io.stderr:write(string.format("water=%s moisture=%s trees=%s\n", Universe.water_tags[rng_water], Universe.moisture_tags[rng_moisture], Universe.trees_tags[rng_trees]))

-- enemy
local enemy_i = crng(1, #Universe.enemy_tags)
io.stderr:write(string.format("enemy = %s\n", Universe.enemy_tags[enemy_i]))

-- aux
local aux_i = crng(1, #Universe.aux_tags)
io.stderr:write(string.format("aux = %s\n", Universe.aux_tags[aux_i]))

-- cliff
local cliff_i = crng(1, #Universe.cliff_tags)
io.stderr:write(string.format("cliff = %s\n", Universe.cliff_tags[cliff_i]))
