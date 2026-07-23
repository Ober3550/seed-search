-- Surface ore dumper — dumps all resource entities on a named surface as JSONL + BMP.
-- Usage (console): /ore-dump <surface_name> [radius]
-- Output: script-output/ore-dump/<surface>.jsonl and .bmp

local function dump_surface(surface_name, radius_override)
  local surface = game.surfaces[surface_name]
  if not surface then
    game.print("[ore-dump] Surface '" .. surface_name .. "' not found")
    return
  end

  local radius = radius_override or (surface.map_gen_settings.width or 2000) / 2
  local half = math.floor(radius)
  local area = {{-half, -half}, {half, half}}

  local entities = surface.find_entities_filtered{type = "resource", area = area, limit = 500000}
  log("[ore-dump] Found " .. #entities .. " entities on " .. surface_name)

  -- JSONL output
  local jsonl_lines = {}
  for _, e in pairs(entities) do
    table.insert(jsonl_lines,
      string.format('{"x":%.1f,"y":%.1f,"n":"%s","a":%d}',
        e.position.x, e.position.y, e.name, e.amount))
  end

  local dir = "ore-dump"
  local jsonl_path = dir .. "/" .. surface_name .. ".jsonl"
  local jsonl_content = table.concat(jsonl_lines, "\n")
  helpers.write_file(jsonl_path, jsonl_content, false)
  log("[ore-dump] Wrote " .. jsonl_path .. " (" .. #entities .. " lines)")

  -- BMP output (greyscale intensity based on ore amount, capped at 20000)
  local size = half * 2
  -- Each pixel: 3 bytes RGB
  local pixels = {}
  local palette = {
    ["iron-ore"]        = {106, 134, 148},
    ["copper-ore"]      = {205, 99, 55},
    ["coal"]            = {60, 60, 60},
    ["stone"]           = {176, 156, 109},
    ["uranium-ore"]     = {0, 179, 0},
    ["crude-oil"]       = {199, 51, 196},
    ["se-vulcanite"]    = {230, 120, 60},
    ["se-cryonite"]     = {90, 200, 230},
    ["se-vitamelange"]  = {150, 90, 200},
    ["kr-imersite"]     = {200, 180, 50},
    ["kr-mineral-water"]= {100, 100, 255},
    ["kr-rare-metal-ore"] = {180, 140, 50},
  }
  local default_color = {128, 128, 128}
  local max_amount = 20000

  for _, e in pairs(entities) do
    local px = math.floor(e.position.x) + half
    local py = math.floor(e.position.y) + half
    if px >= 0 and px < size and py >= 0 and py < size then
      local idx = (py * size + px) * 3 + 1
      local color = palette[e.name] or default_color
      -- Scale brightness by amount (0.2 to 1.0)
      local factor = 0.2 + 0.8 * math.min(e.amount / max_amount, 1.0)
      pixels[idx]     = string.char(math.floor(color[1] * factor))
      pixels[idx + 1] = string.char(math.floor(color[2] * factor))
      pixels[idx + 2] = string.char(math.floor(color[3] * factor))
    end
  end

  -- BMP header
  local file_size = 54 + size * size * 3
  local header = string.char(
    0x42, 0x4D,                          -- 'BM'
    file_size % 256, math.floor(file_size / 256) % 256,
    math.floor(file_size / 65536) % 256, math.floor(file_size / 16777216) % 256,
    0, 0, 0, 0,                          -- reserved
    54, 0, 0, 0,                         -- data offset
    40, 0, 0, 0,                         -- DIB header size
    size % 256, math.floor(size / 256) % 256,
    math.floor(size / 65536) % 256, math.floor(size / 16777216) % 256,  -- width
    size % 256, math.floor(size / 256) % 256,
    math.floor(size / 65536) % 256, math.floor(size / 16777216) % 256,  -- height
    1, 0,                                -- planes
    24, 0,                               -- bits per pixel
    0, 0, 0, 0,                          -- compression
    0, 0, 0, 0,                          -- image size (0 = OK for BI_RGB)
    0, 0, 0, 0,                          -- X pixels per meter
    0, 0, 0, 0,                          -- Y pixels per meter
    0, 0, 0, 0,                          -- colors used
    0, 0, 0, 0                           -- important colors
  )

  -- Fill any missing pixels with dark background
  for i = 1, size * size * 3 do
    if not pixels[i] then
      pixels[i] = string.char(20)
    end
  end

  local bmp_path = dir .. "/" .. surface_name .. ".bmp"
  helpers.write_file(bmp_path, header .. table.concat(pixels), false)
  log("[ore-dump] Wrote " .. bmp_path .. " (" .. size .. "x" .. size .. ")")

  game.print("[ore-dump] Done: " .. surface_name .. " — " .. #entities .. " entities dumped")
end

commands.add_command("ore-dump",
  "ore-dump <surface_name> [radius] — Dump all resource entities on a surface as JSONL + BMP",
  function(cmd)
    local parts = {}
    for part in cmd.parameter:gmatch("%S+") do
      table.insert(parts, part)
    end
    if #parts < 1 then
      game.print("[ore-dump] Usage: /ore-dump <surface_name> [radius]")
      return
    end
    local surface_name = parts[1]
    local radius = nil
    if #parts >= 2 then
      radius = tonumber(parts[2])
    end
    dump_surface(surface_name, radius)
  end
)

log("[ore-dump] Mod loaded. Use /ore-dump <surface> [radius] to dump.")
