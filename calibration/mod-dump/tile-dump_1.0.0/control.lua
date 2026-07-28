-- tile-dump: write the terrain tiles of a surface to JSONL as ground truth for
-- the offline terrain generator. Each line: {"x":ix,"y":iy,"t":"tile-name","w":0|1}
--   w = 1 if the tile blocks resources/entities (water etc.), else 0.
--
-- Usage (RCON or console):
--   /tile-dump <surface-name> [radius]   (radius default 520; disk-bounded)
-- Writes script-output/tile-dump-<surface>.jsonl

-- Precompute which tile prototypes block ground entities (water-like).
local function tile_is_water(proto)
  -- A tile a resource/miner cannot sit on: its collision mask blocks the
  -- ground/resource layers. In practice these are the water/deep tiles.
  local m = proto.collision_mask
  if not m then return false end
  local layers = m.layers or m
  for name, _ in pairs(layers) do
    if name == "water_tile" or name == "water-tile" or name == "empty_space" then
      return true
    end
  end
  return false
end

local function dump(surface_name, radius)
  local s = game.surfaces[surface_name]
  if not s then
    game.print("tile-dump: no surface '" .. tostring(surface_name) .. "'")
    return
  end
  radius = radius or 520
  local r2 = radius * radius
  local lines = {}
  local n = 0
  -- request generation so tiles exist, then read them
  for cy = -radius, radius - 1, 32 do
    for cx = -radius, radius - 1, 32 do
      s.request_to_generate_chunks({ cx, cy }, 0)
    end
  end
  s.force_generate_chunk_requests()

  for iy = -radius, radius - 1 do
    for ix = -radius, radius - 1 do
      -- disk bound (tile center)
      local dx = ix + 0.5
      local dy = iy + 0.5
      if dx * dx + dy * dy <= r2 then
        local t = s.get_tile(ix, iy)
        if t and t.valid then
          local proto = t.prototype
          local w = tile_is_water(proto) and 1 or 0
          n = n + 1
          lines[n] = string.format('{"x":%d,"y":%d,"t":"%s","w":%d}', ix, iy, t.name, w)
        end
      end
    end
  end
  helpers.write_file("tile-dump-" .. surface_name .. ".jsonl", table.concat(lines, "\n") .. "\n", false)
  game.print("tile-dump: wrote " .. n .. " tiles for " .. surface_name)
end

commands.add_command("tile-dump", "Dump surface tiles: /tile-dump <surface> [radius]", function(cmd)
  local args = {}
  for w in string.gmatch(cmd.parameter or "", "%S+") do
    args[#args + 1] = w
  end
  dump(args[1] or "nauvis", tonumber(args[2]))
end)

-- ===========================================================================
-- tile-bmp: render a surface's tiles directly to a BMP using each tile
-- prototype's live map_color. This is the terrain ground truth: water tiles
-- carry their own map_color, so a single BMP of every tile's map_color is the
-- combined tile-type + water surface. Also writes a legend JSON mapping each
-- tile name -> {r,g,b, water}.
-- Usage: /tile-bmp <surface> [radius]   (radius default 520; disk-bounded)
-- Writes script-output/tile-bmp-<surface>.bmp and tile-legend-<surface>.json

-- normalize a LuaTilePrototype map_color (Color, components 0..1 or 0..255) to 0..255 ints
local function map_color_rgb(proto)
  local c = proto.map_color
  if not c then return 40, 40, 40 end
  local r, g, b = c.r or 0, c.g or 0, c.b or 0
  if r <= 1.0 and g <= 1.0 and b <= 1.0 then
    r, g, b = r * 255, g * 255, b * 255
  end
  local function clamp8(v) v = math.floor(v + 0.5); if v < 0 then return 0 elseif v > 255 then return 255 else return v end end
  return clamp8(r), clamp8(g), clamp8(b)
end

local function le32(n)
  return string.char(n % 256, math.floor(n / 256) % 256,
                     math.floor(n / 65536) % 256, math.floor(n / 16777216) % 256)
end

local function bmp_header(width, height, file_size)
  return "BM" .. le32(file_size) .. le32(0) .. le32(54)
      .. le32(40) .. le32(width) .. le32(height)
      .. string.char(1, 0, 24, 0) .. le32(0) .. le32(0)
      .. le32(0) .. le32(0) .. le32(0) .. le32(0)
end

local function dump_bmp(surface_name, radius, shape)
  local s = game.surfaces[surface_name]
  if not s then
    game.print("tile-bmp: no surface '" .. tostring(surface_name) .. "'")
    return
  end
  radius = radius or 520
  -- Asteroid fields (and belts) are rectangular, not disk-shaped like planets;
  -- pass "square" to dump the full 2*radius square instead of a disk crop.
  local square = (shape == "square")
  local half = math.floor(radius)
  local size = half * 2
  local r2 = radius * radius

  -- request generation so tiles exist
  for cy = -half, half - 1, 32 do
    for cx = -half, half - 1, 32 do
      s.request_to_generate_chunks({ cx, cy }, 0)
    end
  end
  s.force_generate_chunk_requests()

  -- color cache per tile-name, and legend
  local color_cache = {}
  local legend = {}
  local function color_for(name)
    local c = color_cache[name]
    if c then return c end
    local proto = prototypes.tile[name]
    local r, g, b = map_color_rgb(proto)
    c = string.char(b, g, r) -- BMP pixel order is BGR
    color_cache[name] = c
    local w = tile_is_water(proto) and 1 or 0
    legend[name] = string.format('{"r":%d,"g":%d,"b":%d,"water":%d}', r, g, b, w)
    return c
  end

  -- BMP rows are bottom-up: file row 0 = world y = -half (matches ore-dump).
  -- Row byte length must be padded to a multiple of 4.
  local row_pad = (4 - (size * 3) % 4) % 4
  local pad = string.rep("\0", row_pad)
  local bg = string.char(20, 20, 20)
  local rows = {}
  for py = 0, size - 1 do
    local iy = py - half
    local cells = {}
    for px = 0, size - 1 do
      local ix = px - half
      local dx = ix + 0.5
      local dy = iy + 0.5
      if square or dx * dx + dy * dy <= r2 then
        cells[px + 1] = color_for(s.get_tile(ix, iy).name)
      else
        cells[px + 1] = bg
      end
    end
    rows[py + 1] = table.concat(cells) .. pad
  end

  local body = table.concat(rows)
  local file_size = 54 + #body
  helpers.write_file("tile-bmp-" .. surface_name .. ".bmp",
    bmp_header(size, size, file_size) .. body, false)

  local legend_parts = {}
  for name, entry in pairs(legend) do
    legend_parts[#legend_parts + 1] = string.format('"%s":%s', name, entry)
  end
  helpers.write_file("tile-legend-" .. surface_name .. ".json",
    "{" .. table.concat(legend_parts, ",") .. "}", false)

  local ntiles = 0
  for _ in pairs(legend) do ntiles = ntiles + 1 end
  game.print(string.format("tile-bmp: wrote %dx%d BMP for %s (%d distinct tiles)",
    size, size, surface_name, ntiles))
end

commands.add_command("tile-bmp", "Render surface tiles to BMP via map_color: /tile-bmp <surface> [radius] [square]", function(cmd)
  local args = {}
  for w in string.gmatch(cmd.parameter or "", "%S+") do
    args[#args + 1] = w
  end
  dump_bmp(args[1] or "nauvis", tonumber(args[2]), args[3])
end)
