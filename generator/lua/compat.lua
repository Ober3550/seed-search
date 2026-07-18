-- Compatibility shim: loads pure-Lua fallbacks for the native modules (rng, env,
-- zip) when running on a standard Lua interpreter without the Zig-built C modules.
--
-- Usage: require('compat') at the top of any entry script, before other requires.
--
-- The native modules and their Lua fallbacks:
--   rng   -> generator/rng_lua.lua   (Tausworthe PRNG, byte-identical to Factorio)
--   env   -> generator/env_lua.lua   (filesystem, OS detection, clock)
--   zip   -> generator/zip_lua.lua   (zip file extraction via system unzip)
--
-- curl and struct already have alternatives:
--   struct -> already implemented as pure Lua (generator/struct.lua)
--   curl   -> only used by manager.lua (distributed task system), not generation

-- Try to load each native module. If it fails (not compiled in), register the
-- pure-Lua fallback in package.preload so subsequent requires succeed.
-- Try to load each native module. If it fails (not compiled in), register the
-- pure-Lua fallback in package.preload so subsequent requires succeed.
-- For rng, try the native C module first (rng_native.so), then pure Lua.
local fallbacks = {
    rng = {"rng_native", "rng_lua"},  -- try native C module, fall back to pure Lua
    env = {"env_lua"},
    zip = {"zip_lua"},
}

for native_name, candidates in pairs(fallbacks) do
    -- Check if the native module is already available
    local has_native = false
    for _, searcher in ipairs(package.searchers or package.loaders or {}) do
        if type(searcher) == "function" then
            local ok, loader = pcall(searcher, native_name)
            if ok and type(loader) == "function" then
                has_native = true
                break
            end
        end
    end

    if not has_native then
        -- Register fallback: try each candidate in order
        package.preload[native_name] = function()
            for _, mod in ipairs(candidates) do
                local ok, result = pcall(require, mod)
                if ok then
                    -- If loaded as rng_native, expose it as 'rng'
                    package.loaded[native_name] = result
                    return result
                end
            end
            error("cannot load module '" .. native_name .. "': tried " .. table.concat(candidates, ", "))
        end
    end
end

return {}
