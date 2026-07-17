-- Capture the star shuffle order and planet assignments for seed 341
package.path = "./generator/?.lua;../generator/?.lua;" .. (package.path or "")
require("se_env")

-- Hook Universe.build to capture intermediate state
local orig_build = Universe.build
Universe.build = function()
    -- Run the original build but capture key state
    orig_build()
end

-- Actually let's just modify the shuffle to log star order
local orig_shuffle = Universe.shuffle
local star_order_logged = false
Universe.shuffle = function(t)
    orig_shuffle(t)
    -- Check if this is the stars table
    if not star_order_logged and #t == 31 and t[1] and t[1].name and t[1].type == nil then
        -- This is a shuffled table; check if it's stars by looking at first element
        -- Stars have .name and no .type before build
        -- unassigned_moons and unassigned_planets are also tables of {name=...}
        -- Let's just check if the first element is a star-like object
        if t[1].name and not t[1].radius_multiplier and not t[1].primary_resource then
            -- Could be stars or unassigned_moons/planets which have different structures
            -- Stars have just {name=...}, same as unassigned_planets
            -- Let's just log everything and filter later
        end
    end
end

local summarize = require("summarize")
summarize.build_universe(341)

-- Print star order from zone_index
print("STAR_ORDER_FROM_ZONE_INDEX")
for i, z in ipairs(storage.zone_index) do
    if z.type == "star" then
        print(string.format("  %s", z.name))
    end
end

-- Print Calidus planet names from children
print("CALIDUS_PLANETS")
local calidus = storage.zones_by_name["Calidus"]
for _, z in ipairs(calidus.children) do
    if z.type == "planet" then
        print(string.format("  %s (seed=%d)", z.name, z.seed))
    end
end

-- Print all planet-to-star mapping
print("ALL_PLANET_TO_STAR")
for _, star in ipairs(storage.zone_index) do
    if star.type == "star" then
        for _, child in ipairs(star.children or {}) do
            if child.type == "planet" then
                print(string.format("  %s -> %s", child.name, star.name))
            end
        end
    end
end
