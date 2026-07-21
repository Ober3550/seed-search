-- Pure-Lua shim for the native `rng` module using Lua 5.4+ native bitwise ops.
-- Compatible with the `rng.call` __call interface expected by se_env.lua.
local rng = {}

local function taus_step(s1, s2, s3)
    s1 = (s1 & 0xFFFFFFFE) << 12 ~ ((s1 << 13 ~ s1) >> 19)
    s2 = (s2 & 0xFFFFFFF8) << 4 ~ ((s2 << 2 ~ s2) >> 25)
    s3 = (s3 & 0xFFFFFFF0) << 17 ~ ((s3 << 3 ~ s3) >> 11)
    return s1, s2, s3, s1 ~ s2 ~ s3
end

local function to_float(u32)
    return u32 * 2.3283064365386963e-10
end

local function to_int(u32, n)
    return math.floor(u32 * 2.3283064365386963e-10 * n - 0.0000001) + 1
end

local function to_int_range(u32, lo, hi)
    return lo + math.floor(u32 * 2.3283064365386963e-10 * (hi - lo + 1) - 0.0000001)
end

function rng.new(seed)
    local gen = { x = seed, y = seed, z = seed }
    return gen
end

-- This .call function is used as FactorioRNG.__call in se_env.lua
function rng.call(self, a, b)
    local s1, s2, s3, val = taus_step(self.x, self.y, self.z)
    self.x, self.y, self.z = s1, s2, s3
    if a == nil then
        return to_float(val)
    elseif b == nil then
        return to_int(val, a)
    else
        return to_int_range(val, a, b)
    end
end

return rng
