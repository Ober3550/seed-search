package.path = "./generator/?.lua;../generator/?.lua;" .. (package.path or "")
require("se_env")
local summarize = require("summarize")
summarize.build_universe(341)

-- Planet-to-star mapping in zone_index order
print("PLANETS")
for _, z in ipairs(storage.zone_index) do
    if z.type == "planet" then
        local star = "?"
        if z.parent and z.parent.type == "star" then star = z.parent.name end
        print(string.format("%s|%s|%d", z.name, star, z.seed))
    end
end

print("MOONS_STATARIUS")
for _, z in ipairs(storage.zone_index) do
    if z.type == "moon" and z.parent and z.parent.parent and z.parent.parent.name == "Statarius" then
        print(string.format("%s|%s|%d", z.name, z.parent.name, z.seed))
    end
end

print("BELTS")
for _, z in ipairs(storage.zone_index) do
    if z.type == "star" then
        local belts = 0
        for _, c in ipairs(z.children or {}) do
            if c.type == "asteroid-belt" then belts = belts + 1 end
        end
        if belts > 0 then print(string.format("%s|%d", z.name, belts)) end
    end
end
