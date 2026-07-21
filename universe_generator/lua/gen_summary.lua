-- Generate rich K2SE seed summaries as JSONL.
-- Requires the SE mod zip (runner/mods/space-exploration_0.7.57.zip).
--
-- Usage (via Docker):
--   docker run --rm --platform linux/amd64 -v "$PWD":/workspace -w /workspace \
--     -e SE_ENABLE_K2=1 ubuntu:22.04 /bin/bash -c \
--     'apt-get update -qq && apt-get install -y -qq libreadline8 libcurl4 >/dev/null 2>&1 && \
--      ./runner/bin/lua-linux-x86_64 gen_summary.lua 341 5 output/rich.jsonl'

package.path = "./generator/lua/?.lua;" .. (package.path or "")

-- Pure-Lua fallbacks for macOS. The native Linux lua binary has these built-in.
package.preload["env"] = function() return require("env_lua") end
package.preload["rng"] = function() return require("rng_lua") end
package.preload["zip"] = function()
    return {
        extract = function(archive_path, internal_path)
            local f = io.open("./se_extracted/" .. internal_path, "rb")
            if f then local data = f:read("*a"); f:close(); return data end
            return nil
        end
    }
end

require("se_env")
local summarize = require("summarize")

local start_seed = tonumber(arg[1] or "343")
local count = tonumber(arg[2] or "1")
local output_path = arg[3] or "output/rich.json"

local out
if output_path then
    os.execute('mkdir -p "' .. string.match(output_path, "^(.*)/") .. '"')
    out = io.open(output_path, "w")
    assert(out, "Could not open " .. output_path)
else
    out = io.stdout
end

local seed = start_seed
local generated = 0
while generated < count do
    local summary = summarize.summarize_seed(seed)

    -- Format numbers with reasonable precision
    local function fmt(n)
        if type(n) == "number" then
            if n == math.floor(n) then return string.format("%d", n) end
            return string.format("%.6f", n)
        end
        return tostring(n)
    end

    local parts = {}
    table.insert(parts, string.format('"s":%d', summary.seed))

    -- Loot: compact string of P/S/E
    table.insert(parts, string.format('"l":"%s"', table.concat(summary.loot, "")))

    -- Planets (Calidus, non-Nauvis, sorted by delta_v)
    local planet_strs = {}
    for _, p in ipairs(summary.planets) do
        local p_parts = {}
        table.insert(p_parts, string.format('"n":"%s"', p.name))
        table.insert(p_parts, string.format('"dv":%d', p.delta_v))
        table.insert(p_parts, string.format('"r":%d', p.radius))
        -- Resources
        local res_parts = {}
        for name, score in pairs(p.resource) do
            table.insert(res_parts, string.format('"%s":%s', name, fmt(score)))
        end
        table.insert(p_parts, string.format('"res":{%s}', table.concat(res_parts, ",")))
        -- Tags
        if p.tags then
            table.insert(p_parts, string.format('"tags":%s',
                string.format('{"temp":"%s","water":"%s","moist":"%s","trees":"%s","aux":"%s","cliff":"%s","enemy":"%s"}',
                    p.tags.temperature, p.tags.water, p.tags.moisture,
                    p.tags.trees, p.tags.aux, p.tags.cliff, p.tags.enemy)))
        end
        table.insert(planet_strs, string.format("{%s}", table.concat(p_parts, ",")))
    end
    table.insert(parts, string.format('"p":[%s]', table.concat(planet_strs, ",")))

    -- Moons (Calidus, sorted by delta_v)
    local moon_strs = {}
    for _, m in ipairs(summary.moons) do
        local m_parts = {}
        table.insert(m_parts, string.format('"n":"%s"', m.name))
        table.insert(m_parts, string.format('"dv":%d', m.delta_v))
        table.insert(m_parts, string.format('"r":%d', m.radius))
        local res_parts = {}
        for name, score in pairs(m.resource) do
            table.insert(res_parts, string.format('"%s":%s', name, fmt(score)))
        end
        table.insert(m_parts, string.format('"res":{%s}', table.concat(res_parts, ",")))
        if m.tags then
            table.insert(m_parts, string.format('"tags":%s',
                string.format('{"temp":"%s","water":"%s","moist":"%s","trees":"%s","aux":"%s","cliff":"%s","enemy":"%s"}',
                    m.tags.temperature, m.tags.water, m.tags.moisture,
                    m.tags.trees, m.tags.aux, m.tags.cliff, m.tags.enemy)))
        end
        table.insert(moon_strs, string.format("{%s}", table.concat(m_parts, ",")))
    end
    table.insert(parts, string.format('"m":[%s]', table.concat(moon_strs, ",")))

    -- Fields (nearest 10 asteroid fields, sorted by delta_v)
    local field_strs = {}
    for _, f in ipairs(summary.fields) do
        local f_parts = {}
        table.insert(f_parts, string.format('"n":"%s"', f.name))
        table.insert(f_parts, string.format('"dv":%d', f.delta_v))
        local res_parts = {}
        for name, score in pairs(f.resource) do
            table.insert(res_parts, string.format('"%s":%s', name, fmt(score)))
        end
        table.insert(f_parts, string.format('"res":{%s}', table.concat(res_parts, ",")))
        table.insert(field_strs, string.format("{%s}", table.concat(f_parts, ",")))
    end
    table.insert(parts, string.format('"f":[%s]', table.concat(field_strs, ",")))

    out:write(string.format("{%s}\n", table.concat(parts, ",")))

    generated = generated + 1
    seed = seed + 2
end

if output_path then out:close() end
io.stderr:write(string.format("Done: %d seeds.\n", generated))
