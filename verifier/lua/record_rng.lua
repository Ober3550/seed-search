-- Record EVERY RNG draw during Universe.build() by intercepting at the Lua level
-- before the native rng module is called.
package.path = "./generator/?.lua;../generator/?.lua;" .. (package.path or "")
require("se_env")

-- Intercept game.create_random_generator BEFORE Universe.build runs
-- We replace it with a version that wraps generators in a Lua proxy
local orig_create = game.create_random_generator
local total_draws = 0
local draw_log = {}

game.create_random_generator = function(seed)
    local gen = orig_create(seed)
    -- Create a Lua proxy table that intercepts every call
    local proxy = {}
    local mt = {
        __call = function(_, a, b)
            total_draws = total_draws + 1
            local result
            if a == nil then
                result = gen()
            elseif b == nil then
                result = gen(a)
            else
                result = gen(a, b)
            end
            -- Log: draw_number, seed_x, a, b, result
            if total_draws <= 200 then
                table.insert(draw_log, string.format("%d,%d,%s,%s,%s",
                    total_draws, gen.x,
                    a or "", b or "",
                    tostring(result)))
            end
            return result
        end
    }
    setmetatable(proxy, mt)
    return proxy
end

local summarize = require("summarize")
summarize.build_universe(341)

print("Total RNG draws: " .. total_draws)
print("First 200 draws (draw_num, state_x, arg_a, arg_b, result):")
for _, entry in ipairs(draw_log) do
    print(entry)
end
