-- Deterministic `pairs` override.
--
-- WHY THIS EXISTS
-- Lua 5.2 seeds its string-hash function per-process (luai_makeseed() == time()),
-- so `pairs()`/`next()` iterate string-keyed tables in a different order every run.
-- SE 0.7's generator (notably universe-homesystem.lua) draws from the universe RNG
-- *inside* such loops, so iteration order changes the RNG draw sequence and thus
-- the generated universe. Without this shim the seed finder is not even
-- reproducible across processes (see docs/universe-generation.md).
--
-- Factorio gets determinism differently: its Lua iterates tables in INSERTION
-- order (confirmed against a live game — `{zebra,apple,mango}` iterates
-- zebra,apple,mango, not sorted). Stock Lua 5.2 (our bin/lua) can't recover a
-- table's insertion order after the fact, so:
--   * default: a *stable sorted* order — reproducible, and it happens to match
--     the game everywhere iteration order doesn't affect the result (arrays, and
--     order-independent string-keyed loops), and
--   * override: for the few string-keyed tables whose iteration order DOES drive
--     RNG draws, register the real insertion order via set_order() so we match the
--     game exactly. Today that's UniverseHomesystem.guaranteed_special_types
--     (registered in se_env.lua).
--
-- The only fully-general fix is an interpreter that preserves insertion order
-- (like Factorio's); that needs rebuilding bin/lua, which is blocked by the lack
-- of source for its native modules.

local function key_less(a, b)
  local ta, tb = type(a), type(b)
  if ta ~= tb then return ta < tb end
  if ta == "number" or ta == "string" then return a < b end
  return tostring(a) < tostring(b)  -- stable fallback for other key types
end

local real_next = next

-- Tables with a known real insertion order. Weak keys so registration never keeps
-- a table alive. Value = array of keys in the game's (insertion) iteration order.
local explicit_order = setmetatable({}, { __mode = "k" })

-- Register the true (insertion) order for a specific table. Keys not in `keys`
-- (e.g. runtime additions like K2's kr-imersite) are appended after the listed
-- ones — which matches insertion order, since such keys are always added after
-- the source literal that defines the base keys.
local function set_order(tbl, keys)
  explicit_order[tbl] = keys
end

-- Deterministic pairs: snapshot keys in a fixed order, then iterate.
local function det_pairs(t)
  local keys = {}
  local n = 0
  local order = explicit_order[t]
  if order then
    local seen = {}
    for _, k in ipairs(order) do
      if rawget(t, k) ~= nil then n = n + 1; keys[n] = k; seen[k] = true end
    end
    local extra = {}
    for k in real_next, t do if not seen[k] then extra[#extra + 1] = k end end
    table.sort(extra, key_less)
    for _, k in ipairs(extra) do n = n + 1; keys[n] = k end
  else
    for k in real_next, t do n = n + 1; keys[n] = k end
    table.sort(keys, key_less)
  end
  local i = 0
  return function()
    i = i + 1
    local k = keys[i]
    if k ~= nil then return k, t[k] end
  end
end

-- Install globally. ipairs is already array-ordered (deterministic) so is left
-- alone; direct `for k in next, t do` loops in mod code are rare and mostly used
-- as emptiness checks, which are order-insensitive.
pairs = det_pairs

return { pairs = det_pairs, key_less = key_less, set_order = set_order }
