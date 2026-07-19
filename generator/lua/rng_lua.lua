-- Pure-Lua implementation of Factorio's LuaRandomGenerator (Tausworthe PRNG).
-- Validated against the native `rng` module from the seed finder's bin/lua.
--
-- Usage:
--   local rng = require('rng_lua')
--   local gen = rng.new(seed)
--   gen()       --> float in [0, 1)
--   gen(n)      --> integer in [1, n]
--   gen(a, b)   --> integer in [a, b]

local rng_lua = {}

-- Factorio's Tausworthe step function.
-- Returns a 32-bit unsigned integer.
local function taus_step(s1, s2, s3)
    -- tausworthe s1: (s1 & 0xFFFFFFFE) << 12 ^ (((s1 << 13) ^ s1) >> 19)
    -- All right shifts are LOGICAL (unsigned), matching the C/Zig implementation.
    s1 = bit32.bxor(
        bit32.lshift(bit32.band(s1, 0xFFFFFFFE), 12),
        bit32.rshift(bit32.bxor(bit32.lshift(s1, 13), s1), 19)
    )
    -- tausworthe s2: (s2 & 0xFFFFFFF8) << 4 ^ (((s2 << 2) ^ s2) >> 25)
    s2 = bit32.bxor(
        bit32.lshift(bit32.band(s2, 0xFFFFFFF8), 4),
        bit32.rshift(bit32.bxor(bit32.lshift(s2, 2), s2), 25)
    )
    -- tausworthe s3: (s3 & 0xFFFFFFF0) << 17 ^ (((s3 << 3) ^ s3) >> 11)
    s3 = bit32.bxor(
        bit32.lshift(bit32.band(s3, 0xFFFFFFF0), 17),
        bit32.rshift(bit32.bxor(bit32.lshift(s3, 3), s3), 11)
    )
    return s1, s2, s3, bit32.bxor(s1, bit32.bxor(s2, s3))
end

-- Normalize a 32-bit unsigned int to [0, 1) float
local function to_float(u32)
    return u32 * 2.3283064365386963e-10  -- 1 / 2^32
end

-- Integer in [1, n] from a 32-bit value.
-- Factorio uses: floor(u32 / 2^32 * n) + 1
local function to_int(u32, n)
    return math.floor(u32 * 2.3283064365386963e-10 * n - 0.0000001) + 1
end

-- Integer in [lo, hi] from a 32-bit value
local function to_int_range(u32, lo, hi)
    return lo + math.floor(u32 * 2.3283064365386963e-10 * (hi - lo + 1) - 0.0000001)
end

-- Seed initialization. The RNG module itself does NOT apply corrections;
-- game.create_random_generator in se_env.lua handles seed < 341 clamping and
-- low-bit masking. The native rng module just uses whatever x, y, z values
-- are set on the callable table.
local function init_state(seed)
    return seed, seed, seed
end

-- Create a new generator instance. Compatible with the native `rng` module's
-- calling convention: the table itself is callable via __call metamethod.
function rng_lua.new(seed)
    local s1, s2, s3 = init_state(seed)
    local gen = {
        _s1 = s1,
        _s2 = s2,
        _s3 = s3,
    }
    local function call(_, a, b)
        local val
        s1, s2, s3, val = taus_step(gen._s1, gen._s2, gen._s3)
        gen._s1, gen._s2, gen._s3 = s1, s2, s3
        if a == nil then
            return to_float(val)
        elseif b == nil then
            return to_int(val, a)
        else
            return to_int_range(val, a, b)
        end
    end
    setmetatable(gen, { __call = call })
    return gen
end

-- Also expose a `call` function compatible with the native module's API:
-- rng.call is used as the __call metamethod.
rng_lua.call = function(self, a, b)
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

return rng_lua
