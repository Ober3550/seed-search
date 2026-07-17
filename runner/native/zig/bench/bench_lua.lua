-- Benchmark: Lua SE universe generation
-- Run via Docker: docker run --rm --platform linux/amd64 -v "$(pwd)":/workspace ubuntu:22.04 \
--   bash -c 'apt-get install -y -qq libreadline8 libcurl4 > /dev/null 2>&1 && \
--   cd /workspace && ./runner/bin/lua-linux-x86_64 ./runner/native/zig/bench/bench_lua.lua 50'
--
-- Or natively on Linux: ./runner/bin/lua-linux-x86_64 runner/native/zig/bench/bench_lua.lua 50

package.path = "./generator/?.lua;./runner/native/zig/?.lua;" .. (package.path or "")

-- Use a zip preload that reads from extracted mod files (extract first with:
--   mkdir -p se_extracted && unzip -q -o runner/mods/space-exploration_0.7.57.zip -d se_extracted/)
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

local num_seeds = tonumber(arg[1]) or 50
io.stderr:write(string.format("Lua: running %d seeds...\n", num_seeds))

local start = os.clock()
for i = 0, num_seeds - 1 do
    local seed = i * 2 + 341
    summarize.build_universe(seed)
end
local elapsed = os.clock() - start

io.stderr:write(string.format(
    "LUA: %d seeds in %.1fms (%.0fµs/seed)\n",
    num_seeds, elapsed * 1000, elapsed * 1000000 / num_seeds
))
