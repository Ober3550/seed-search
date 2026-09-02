#!/usr/bin/env lua
-- Extracts Space Age (Factorio 2.0) surface-generation data from the installed
-- game into JSON for the Zig noise-expression engine (see docs/space-age.md).
--
--   lua scripts/extract-sa-data.lua [GAME_DATA_DIR] [OUT_DIR]
--
--   GAME_DATA_DIR  default /Applications/factorio.app/Contents/data
--   OUT_DIR        default surface_generator/sa-data
--
-- How it works: the game's surface-generation data lives in pure-data Lua
-- files (noise-function / noise-expression / planet map-gen settings). This
-- script shims `data:extend`, `require` and `data.raw.resource.*.autoplace`
-- assignment, loads those files under stock Lua, and serializes the captured
-- tables to JSON. The Zig engine consumes the JSON (expression source strings
-- are kept verbatim — the engine parses/evaluates them).
--
-- Captures:
--   noise-functions.json     engine helper functions (core + base + space-age)
--   expressions.json         named noise expressions (base + space-age planets)
--   planets.json             per-planet map_gen_settings (property expressions,
--                            autoplace controls/settings, cliff/territory)
--   resource-autoplace.json  direct data.raw.resource.<name>.autoplace
--                            overrides (e.g. fulgora scrap)
--
-- Tile / decorative / entity prototype autoplace (the bulk data in
-- base/prototypes/tile etc.) uses lualib helpers and is extracted separately —
-- see docs/space-age.md P1.

local args = { ... }
local GAME = args[1] or "/Applications/factorio.app/Contents/data"
local OUT = args[2] or "surface_generator/sa-data"

local captured = { functions = {}, expressions = {}, resources = {} }
local file_src = {}

local function count(t)
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  return n
end

-- ── Game-data shims ────────────────────────────────────────────────────────
data = {
  extend = function(_, tbl)
    for _, item in ipairs(tbl or {}) do
      if item.type == "noise-function" then
        captured.functions[item.name] = item
      elseif item.type == "noise-expression" then
        captured.expressions[item.name] = item
      end
    end
  end,
}

-- data.raw.<type>.<name>.<field> = ... — the planet files directly assign
-- resource autoplace overrides (e.g. data.raw.resource.scrap.autoplace = {...})
-- where the prototype table may not exist yet, so proxy every path and record
-- resource autoplace assignments.
do
  local function proto_proxy(typename, name)
    return setmetatable({}, {
      __newindex = function(t, k, v)
        if typename == "resource" and k == "autoplace" then
          captured.resources[name] = v
        end
        rawset(t, k, v)
      end,
    })
  end
  local raw = setmetatable({}, {
    __index = function(t, typename)
      local tn = setmetatable({}, {
        __index = function(t2, name)
          local p = proto_proxy(typename, name)
          rawset(t2, name, p)
          return p
        end,
        __newindex = function(t2, name, v) rawset(t2, name, v) end,
      })
      rawset(t, typename, tn)
      return tn
    end,
  })
  data.raw = raw
end

-- Resolve a require() name to a file path under the game data dir.
local function resolve(name)
  if name:sub(1, 9) == "__base__/" then
    return GAME .. "/base/" .. name:sub(10) .. ".lua"
  end
  if name:sub(1, 9) == "__core__." then
    return GAME .. "/core/" .. name:sub(10):gsub("%.", "/") .. ".lua"
  end
  if name:sub(1, 14) == "__space-age__." then
    return GAME .. "/space-age/" .. name:sub(15):gsub("%.", "/") .. ".lua"
  end
  if name:sub(1, 14) == "__space-age__/" then
    return GAME .. "/space-age/" .. name:sub(15) .. ".lua"
  end
  -- bare core lualib name, e.g. "resource-autoplace"
  return GAME .. "/core/lualib/" .. name .. ".lua"
end

local cache = {}
function require(name)
  local path = resolve(name)
  if cache[path] then return cache[path] end
  local chunk, err = loadfile(path)
  if not chunk then error("require " .. name .. ": " .. tostring(err)) end
  local result = chunk()
  cache[path] = result
  return result
end

local function dofile_capture(path, label)
  local chunk, err = loadfile(path)
  if not chunk then error(label .. ": " .. tostring(err)) end
  chunk()
  file_src[#file_src + 1] = label .. " ← " .. path
end

-- ── JSON serializer (deterministic key order, %.15g numbers) ───────────────
local function is_array(t)
  local n = 0
  for k in pairs(t) do
    if type(k) ~= "number" or k < 1 or k % 1 ~= 0 then return false end
    if k > n then n = k end
  end
  for k in pairs(t) do if k > n then return false end end
  for i = 1, n do if t[i] == nil then return false end end
  return true
end

local function js_string(s)
  local out = { '"' }
  for i = 1, #s do
    local b = s:byte(i)
    if b == 34 then out[#out + 1] = '\\"'
    elseif b == 92 then out[#out + 1] = "\\\\"
    elseif b == 10 then out[#out + 1] = "\\n"
    elseif b == 13 then out[#out + 1] = "\\r"
    elseif b == 9 then out[#out + 1] = "\\t"
    elseif b < 32 or b == 127 then out[#out + 1] = string.format("\\u%04x", b)
    else out[#out + 1] = s:sub(i, i) end
  end
  out[#out + 1] = '"'
  return table.concat(out)
end

local function serialize(v, out)
  local t = type(v)
  if t == "nil" then return end
  if t == "boolean" then
    out[#out + 1] = v and "true" or "false"
    return
  end
  if t == "number" then
    if v ~= v or v == math.huge or v == -math.huge then
      out[#out + 1] = "null"
    elseif v == math.floor(v) and math.abs(v) < 1e15 then
      out[#out + 1] = string.format("%d", v)
    else
      out[#out + 1] = string.format("%.15g", v)
    end
    return
  end
  if t == "string" then
    out[#out + 1] = js_string(v)
    return
  end
  if t == "table" then
    local keys = {}
    for k in pairs(v) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    if is_array(v) then
      out[#out + 1] = "["
      for i = 1, #keys do
        if i > 1 then out[#out + 1] = "," end
        serialize(v[keys[i]], out)
      end
      out[#out + 1] = "]"
    else
      out[#out + 1] = "{"
      local first = true
      for i, k in ipairs(keys) do
        local sub = {}
        serialize(v[k], sub)
        if #sub > 0 then -- skip nil-valued keys (Lua data idiom)
          if not first then out[#out + 1] = "," end
          first = false
          out[#out + 1] = js_string(tostring(k)) .. ":" .. table.concat(sub)
        end
      end
      out[#out + 1] = "}"
    end
    return
  end
  error("cannot serialize " .. t)
end

-- ── Load the game data ─────────────────────────────────────────────────────
-- 1. core engine helper functions
dofile_capture(GAME .. "/core/prototypes/noise-functions.lua", "core noise-functions")
-- 2. vanilla (Nauvis) expressions
dofile_capture(GAME .. "/base/prototypes/noise-expressions.lua", "base noise-expressions")
-- 3. planet map_gen_settings (base defines nauvis; space-age adds the four)
local planet_mg = require("__base__/prototypes/planet/planet-map-gen")
require("__space-age__/prototypes/planet/planet-map-gen")
-- 4. per-planet expression files (vulcanus/gleba/fulgora/aquilo)
dofile_capture(GAME .. "/space-age/prototypes/planet/planet-vulcanus-map-gen.lua", "vulcanus map-gen")
dofile_capture(GAME .. "/space-age/prototypes/planet/planet-gleba-map-gen.lua", "gleba map-gen")
dofile_capture(GAME .. "/space-age/prototypes/planet/planet-fulgora-map-gen.lua", "fulgora map-gen")
dofile_capture(GAME .. "/space-age/prototypes/planet/planet-aquilo-map-gen.lua", "aquilo map-gen")

local planets = {}
planets.nauvis = planet_mg.nauvis()
for _, name in ipairs({ "vulcanus", "gleba", "fulgora", "aquilo" }) do
  planets[name] = planet_mg[name]()
end

-- ── Write JSON ─────────────────────────────────────────────────────────────
os.execute('mkdir -p "' .. OUT .. '"')
local files = {
  ["noise-functions.json"] = captured.functions,
  ["expressions.json"] = captured.expressions,
  ["planets.json"] = planets,
  ["resource-autoplace.json"] = captured.resources,
}
for fname, tbl in pairs(files) do
  local out = {}
  serialize(tbl, out)
  local fh = io.open(OUT .. "/" .. fname, "w")
  fh:write(table.concat(out), "\n")
  fh:close()
end

print("extracted from " .. GAME)
print("  noise-functions:     " .. count(captured.functions))
print("  expressions:         " .. count(captured.expressions))
print("  resource autoplace:  " .. count(captured.resources))
print("  planets:             " .. count(planets) .. " (nauvis, vulcanus, gleba, fulgora, aquilo)")
print("sources:")
for _, s in ipairs(file_src) do print("  " .. s) end
