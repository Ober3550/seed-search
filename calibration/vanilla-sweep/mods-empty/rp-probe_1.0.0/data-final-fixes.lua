-- Probe resource: placed exactly where the map-gen column's random_penalty draw
-- is < 1/64 (probability is binary, so the pass-2 roll always passes).
local p = table.deepcopy(data.raw.resource["iron-ore"])
p.name = "probe-dots"
p.order = "a"
p.map_color = {1, 0, 1}
p.autoplace = {
  probability_expression = "if(random_penalty{x = x, y = y, source = 1, amplitude = 64} > 0, 1, 0)",
  richness_expression = "1000",
  order = "a"
}
data:extend{p}

-- Nauvis lists placeable entities explicitly — register the probe resource.
local mgs = data.raw.planet and data.raw.planet.nauvis and data.raw.planet.nauvis.map_gen_settings
if mgs and mgs.autoplace_settings and mgs.autoplace_settings.entity and mgs.autoplace_settings.entity.settings then
  mgs.autoplace_settings.entity.settings["probe-dots"] = {}
end
