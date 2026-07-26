-- Single probe at order 'c[a]' (immediately after the 'c' resources group):
-- everything before it generates exactly as in the plain world, and its dots
-- read the true cumulative RNG consumption through group 'c'.
local p = table.deepcopy(data.raw.resource["iron-ore"])
p.name = "probe-after-c"
p.order = "c[a]"
p.map_color = {1, 0, 1}
p.autoplace = {
  probability_expression = "0.5",
  richness_expression = "1000",
  order = "c[a]"
}
data:extend{p}
local mgs = data.raw.planet and data.raw.planet.nauvis and data.raw.planet.nauvis.map_gen_settings
if mgs and mgs.autoplace_settings and mgs.autoplace_settings.entity and mgs.autoplace_settings.entity.settings then
  mgs.autoplace_settings.entity.settings["probe-after-c"] = {}
end
