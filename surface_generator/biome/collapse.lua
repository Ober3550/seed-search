-- Run alien-biomes' actual collapse logic to emit the per-tile volume boxes.
-- Produces JSON: [{name,group,axis,variant,beach_weight, t_min,t_max,m_min,m_max,a_min,a_max,e_min,e_max}]
-- combine_volume_constraints + collapse are copied verbatim from
-- alien-biomes_0.7.4/prototypes/biome/biomes.lua.

local here = arg[0]:match("(.*/)") or "./"
local biomes = {}
biomes.axes = dofile(here .. "biome-axes.lua")
biomes.spec = dofile(here .. "biome-spec.lua")

biomes.combine_volume_constraints = function(volume, axis, point_a, point_b)
  local r_point_a = point_a
  local r_point_b = point_b
  if biomes.axes[axis].reverse then
    r_point_a = 1 - point_a
    r_point_b = 1 - point_b
  end
  local point_l = math.min(r_point_a, r_point_b)
  local point_h = math.max(r_point_a, r_point_b)
  local dimension = biomes.axes[axis].dimension
  local low = biomes.axes[axis].low
  local high = biomes.axes[axis].high
  local d_point_a = low + (high - low) * point_l
  local d_point_b = low + (high - low) * point_h
  if volume[dimension .. "_min"] then
    volume[dimension .. "_min"] = math.max(d_point_a, volume[dimension .. "_min"])
  else
    volume[dimension .. "_min"] = d_point_a
  end
  if volume[dimension .. "_max"] then
    volume[dimension .. "_max"] = math.min(d_point_b, volume[dimension .. "_max"])
  else
    volume[dimension .. "_max"] = d_point_b
  end
  return volume
end

local function deepcopy(t)
  if type(t) ~= "table" then return t end
  local r = {}
  for k, v in pairs(t) do r[k] = deepcopy(v) end
  return r
end

local collapsed = {}
for group_name, group in pairs(biomes.spec) do
  if group.axes then
    for axis_name, axis in pairs(group.axes) do
      for variant_name, variant in pairs(group.variants) do
        local skip = false
        if variant.limit_axes then
          local pass = false
          for _, allowed in pairs(variant.limit_axes) do
            if axis_name == allowed then pass = true end
          end
          if pass == false then skip = true end
        end
        if not skip then
          local volume = variant.volume and deepcopy(variant.volume) or {}
          for dn, d in pairs(group.dimensions) do biomes.combine_volume_constraints(volume, dn, d[1], d[2]) end
          for dn, d in pairs(axis.dimensions) do biomes.combine_volume_constraints(volume, dn, d[1], d[2]) end
          if variant.dimensions then
            for dn, d in pairs(variant.dimensions) do biomes.combine_volume_constraints(volume, dn, d[1], d[2]) end
          end
          local b = { volume = volume, group = variant.group or group_name, axis = axis_name,
                      variant = variant_name, beach_weight = variant.beach_weight,
                      name = group_name .. "-" .. axis_name .. "-" .. variant_name }
          collapsed[b.name] = b
        end
      end
    end
  else
    for variant_name, variant in pairs(group.variants) do
      local volume = variant.volume and deepcopy(variant.volume) or {}
      for dn, d in pairs(group.dimensions) do biomes.combine_volume_constraints(volume, dn, d[1], d[2]) end
      if variant.dimensions then
        for dn, d in pairs(variant.dimensions) do biomes.combine_volume_constraints(volume, dn, d[1], d[2]) end
      end
      local b = { volume = volume, group = variant.group or group_name, variant = variant_name,
                  beach_weight = variant.beach_weight, name = group_name .. "-" .. variant_name }
      collapsed[b.name] = b
    end
  end
end

local function numornull(v) return v ~= nil and string.format("%.6g", v) or "null" end
local parts = {}
for name, b in pairs(collapsed) do
  local v = b.volume
  parts[#parts + 1] = string.format(
    '{"name":"%s","group":"%s","axis":%s,"variant":"%s","beach_weight":%s,'
    .. '"t_min":%s,"t_max":%s,"m_min":%s,"m_max":%s,"a_min":%s,"a_max":%s,"e_min":%s,"e_max":%s}',
    name, b.group, b.axis and ('"' .. b.axis .. '"') or "null", b.variant,
    numornull(b.beach_weight),
    numornull(v.temperature_min), numornull(v.temperature_max),
    numornull(v.moisture_min), numornull(v.moisture_max),
    numornull(v.aux_min), numornull(v.aux_max),
    numornull(v.elevation_min), numornull(v.elevation_max))
end
table.sort(parts)
print("[\n" .. table.concat(parts, ",\n") .. "\n]")
