-- Count resources and write JSON on startup
local RADIUS = 738
script.on_event(defines.events.on_tick, function(event)
  if global and global.done then return end
  if game.tick < 120 then return end

  local surface = game.surfaces.nauvis
  local half = RADIUS
  local area = {{-half, -half}, {half, half}}

  local water_tiles = surface.count_tiles_filtered{area=area, name="water"}
  local total_tiles = (2 * half) * (2 * half)
  local land_tiles = total_tiles - water_tiles

  local counts = {}
  local entities = surface.find_entities_filtered{type="resource", area=area}
  for _, e in pairs(entities) do
    local n = e.name
    if not counts[n] then counts[n] = {total = 0, patches = 0} end
    counts[n].total = counts[n].total + e.amount
    counts[n].patches = counts[n].patches + 1
  end

  local result = {
    seed = surface.map_gen_settings.seed,
    radius = RADIUS,
    water = "none",
    freq = 1.0,
    size = 1.0,
    rich = 1.0,
    total_tiles = total_tiles,
    water_tiles = water_tiles,
    land_tiles = land_tiles,
    resources = counts
  }

  local json = helpers.table_to_json(result)
  helpers.write_file("ore-count-" .. tostring(RADIUS) .. ".json", json, false)
  log("ORE_COUNT_DONE: " .. json)
  game.print("ORE_COUNT_DONE")

  if not global then global = {} end
  global.done = true
end)
