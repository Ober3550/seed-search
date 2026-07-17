/* Fast Tausworthe RNG for the SE seed finder — native Lua C module.
 *
 * Implements Factorio's LuaRandomGenerator (Taus88) with the exact same
 * semantics as the Zig-built native `rng` module.
 *
 * Lua API (matches the native `rng` module):
 *   local rng = require("rng_native")
 *   local gen = { x = seed, y = seed, z = seed }
 *   setmetatable(gen, { __call = rng.call })
 *   gen()      --> float in [0, 1)
 *   gen(n)     --> integer in [1, n]
 *   gen(a, b)  --> integer in [a, b]
 */

#include <lua.h>
#include <lauxlib.h>
#include <stdint.h>
#include <math.h>

#define U32_TO_FLOAT(u) ((double)(u) * 2.3283064365386963e-10)

/* Factorio's exact Tausworthe step (same as the native binary) */
static void taus_step(uint32_t *s1, uint32_t *s2, uint32_t *s3, uint32_t *out) {
    *s1 = ((*s1 & 0xFFFFFFFE) << 12) ^ (((*s1 << 13) ^ *s1) >> 19);
    *s2 = ((*s2 & 0xFFFFFFF8) << 4) ^ (((*s2 << 2) ^ *s2) >> 25);
    *s3 = ((*s3 & 0xFFFFFFF0) << 17) ^ (((*s3 << 3) ^ *s3) >> 11);
    *out = *s1 ^ *s2 ^ *s3;
}

/* rng.call(self, a, b) — __call metamethod */
static int rng_call(lua_State *L) {
    /* Read state from the table (self) */
    lua_getfield(L, 1, "x");  uint32_t s1 = (uint32_t)lua_tointeger(L, -1); lua_pop(L, 1);
    lua_getfield(L, 1, "y");  uint32_t s2 = (uint32_t)lua_tointeger(L, -1); lua_pop(L, 1);
    lua_getfield(L, 1, "z");  uint32_t s3 = (uint32_t)lua_tointeger(L, -1); lua_pop(L, 1);

    uint32_t val;
    taus_step(&s1, &s2, &s3, &val);

    /* Write state back */
    lua_pushinteger(L, s1); lua_setfield(L, 1, "x");
    lua_pushinteger(L, s2); lua_setfield(L, 1, "y");
    lua_pushinteger(L, s3); lua_setfield(L, 1, "z");

    int nargs = lua_gettop(L) - 1; /* args after self */
    if (nargs == 0) {
        /* rng() -> float in [0, 1) */
        lua_pushnumber(L, U32_TO_FLOAT(val));
    } else if (nargs == 1) {
        /* rng(n) -> int in [1, n] */
        lua_Integer n = lua_tointeger(L, 2);
        lua_pushinteger(L, (lua_Integer)(U32_TO_FLOAT(val) * (double)n) + 1);
    } else {
        /* rng(a, b) -> int in [a, b] */
        lua_Integer a = lua_tointeger(L, 2);
        lua_Integer b = lua_tointeger(L, 3);
        lua_Integer range = b - a + 1;
        lua_pushinteger(L, a + (lua_Integer)(U32_TO_FLOAT(val) * (double)range));
    }
    return 1;
}

int luaopen_rng_native(lua_State *L) {
    lua_newtable(L);
    lua_pushcfunction(L, rng_call);
    lua_setfield(L, -2, "call");
    return 1;
}
