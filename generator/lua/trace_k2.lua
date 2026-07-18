package.path = "./generator/lua/?.lua;" .. (package.path or "")

package.preload["env"] = function() return require("env_lua") end

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

_G.draw = 0
local orig_create = game.create_random_generator
game.create_random_generator = function(s)
    local gen = orig_create(s)
    if s == nil then
        local proxy = {}
        local mt = {
            __call = function(_, a, b)
                _G.draw = _G.draw + 1
                if a == nil then return gen() end
                if b == nil then return gen(a) end
                return gen(a, b)
            end
        }
        setmetatable(proxy, mt)
        return proxy
    end
    return gen
end

local summarize = require("summarize")
summarize.build_universe(341)

print("LUA_K2_TOTAL_DRAWS=" .. _G.draw)
print("LUA_K2_ZONES=" .. #storage.zone_index)

for i, z in ipairs(storage.zone_index) do
    print(string.format("%d|%s|%s|%d", i, z.name, z.type, z.seed))
end
