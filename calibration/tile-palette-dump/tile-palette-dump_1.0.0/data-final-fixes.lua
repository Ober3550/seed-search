-- Data-stage tile palette dump. Runs AFTER every prototype is loaded, so
-- data.raw.tile holds the fully-resolved tile prototypes (template helpers,
-- lerped/computed map_colors etc. already expanded by the game).
--
-- Emits one log line per tile to factorio-current.log (the data stage cannot
-- write files):
--   TPD\t<name>\t<r>\t<g>\t<b>\t<layer>\t<subgroup>
-- map_color may be {a,b,c} (0..255 ints or 0..1 floats) or {r=..,g=..,b=..}.
-- 0..1 floats are scaled to 0..255. Subgroup is the vanilla planet set key.
local function norm(v)
  return math.floor(v * 255 + 0.5)
end
local function dump()
  for name, proto in pairs(data.raw.tile) do
    local mc = proto.map_color
    local r, g, b = 0, 0, 0
    if mc then
      if mc.r or mc.g or mc.b then
        r, g, b = mc.r or 0, mc.g or 0, mc.b or 0
      else
        r, g, b = mc[1] or 0, mc[2] or 0, mc[3] or 0
      end
      local m = math.max(r, g, b)
      if m <= 1.0001 then
        r, g, b = norm(r), norm(g), norm(b)
      else
        r, g, b = math.floor(r + 0.5), math.floor(g + 0.5), math.floor(b + 0.5)
      end
    end
    log(string.format("TPD\t%s\t%d\t%d\t%d\t%d\t%s",
      name, r, g, b, proto.layer or 0, proto.subgroup or ""))
  end
  log("TPD\t__DONE__\t" .. tostring(#data.raw.tile))
end
dump()
