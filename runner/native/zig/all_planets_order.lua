package.path = "./generator/?.lua;../generator/?.lua;" .. (package.path or "")
require("se_env")

-- Hook into planet assignment to capture all_planets order
local orig_build = Universe.build
local all_planets_log = {}
Universe.build = function()
    -- We need to hook the all_planets table creation
    -- It's a local variable, but we can hook table.insert globally
    local orig_insert = table.insert
    local captured_all_planets = nil
    local in_build = false
    
    table.insert = function(t, ...)
        if in_build and #t == 0 and (...) == nil then
            -- First insert into an empty table after build starts
            -- Check if this is the all_planets table (line 312: local all_planets = {})
            -- The first insert is Nauvis (line 313)
        end
        return orig_insert(t, ...)
    end
    
    orig_build()
    table.insert = orig_insert
end

-- Actually, simpler: just print moon assignments which tell us the planet index
local summarize = require("summarize")
summarize.build_universe(341)

-- Reconstruct all_planets from moon assignments
-- Moon assignment: for each unassigned_moon (shuffled), pick rng.int1(#all_planets)
-- We know the shuffled moon order. We know which planet each moon ended up at.
-- From that, we can work backwards to find all_planets order.

print("MOON_TO_PLANET")
for _, z in ipairs(storage.zone_index) do
    if z.type == "moon" and z.parent and z.parent.type == "planet" then
        print(string.format("%s -> %s", z.name, z.parent.name))
    end
end
