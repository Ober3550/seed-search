-- Trace every universe RNG call during Calidus star construction
package.path = "./generator/lua/?.lua;" .. (package.path or "")
package.preload["env"] = function() return require("env_lua") end
package.preload["rng"] = function() return require("rng_lua") end
package.preload["zip"] = function()
    return { extract = function(_, p)
        local f = io.open("./se_extracted/" .. p, "rb")
        if f then local d = f:read("*a"); f:close(); return d end
    end}
end

require("se_env")

local draw = 0
local tracing = false
local trace_log = {}

local orig_create = game.create_random_generator
game.create_random_generator = function(s)
    local gen = orig_create(s)
    if s == nil then
        local proxy = {}
        local mt = {
            __call = function(_, a, b)
                draw = draw + 1
                if a == nil then
                    local v = gen()
                    if tracing then
                        table.insert(trace_log, string.format("TRACE %d: float = %.6f", draw, v))
                    end
                    return v
                elseif b == nil then
                    local v = gen(a)
                    if tracing then
                        table.insert(trace_log, string.format("TRACE %d: int1(%d)=%d", draw, a, v))
                    end
                    return v
                else
                    local v = gen(a, b)
                    if tracing then
                        table.insert(trace_log, string.format("TRACE %d: intRange(%d,%d)=%d", draw, a, b, v))
                    end
                    return v
                end
            end
        }
        setmetatable(proxy, mt)
        return proxy
    end
    return gen
end

-- Hook Universe.build to detect Calidus star processing
local orig_build = Universe.build
Universe.build = function()
    -- Patch the star loop
    local orig_random_stellar_position = Universe.random_stellar_position
    -- Actually, the star processing is inside Universe.build, not in a separate function.
    -- Let's hook at a lower level: patch Universe.add_zone to detect Calidus star
    orig_build()
end

-- Instead, hook random_stellar_position which is called for each star
-- But it's a local function inside build... let me just instrument add_zone
local orig_add_zone = Universe.add_zone
Universe.add_zone = function(zone_index, zones_by_name, zone)
    if zone.name == "Calidus" and zone.type == "star" then
        if not tracing then
            tracing = true
        end
    end
    orig_add_zone(zone_index, zones_by_name, zone)
end

local summarize = require("summarize")
summarize.build_universe(341)

-- Print only the Calidus section (from first TRACE to the star after Calidus)
for _, line in ipairs(trace_log) do
    print(line)
end

io.stderr:write(string.format("# Total draws: %d, Calidus trace lines: %d\n", draw, #trace_log))
