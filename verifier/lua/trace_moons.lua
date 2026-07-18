package.path = "./generator/?.lua;../generator/?.lua;" .. (package.path or "")
require("se_env")
local rng = require("rng")
local g = {x=341,y=341,z=341}; setmetatable(g,{__call=rng.call})

-- Skip to draw 674 (after build remaining in Zig)
g(127,156) -- 1
for i=15,2,-1 do g(i) end
for i=31,2,-1 do g(i) end
for i=16,2,-1 do g(i) end
for i=534,2,-1 do g(i) end
for i=1,16 do g(31) end -- planet assignment

-- Build remaining: 65 int1(31) calls (matching Zig's 65 iterations, 0 floats)
for i=1,65 do g(31) end

-- Now at draw 675: moon assignment starts
-- 15 moons: int1(127), then min-1-moon (0 draws), then build moons: int1(127) + float()

-- Print first 40 build moon calls  
print("LUA moon/build draws starting at 675:")
for i=1,40 do
    local v = g(127)
    print(string.format("  %d: int1(127)=%d", 674+i, v))
end
