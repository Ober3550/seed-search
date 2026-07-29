-- Probe noise-expressions to resolve the alien-biomes tile-variation noise ops.
-- Read via calculate_tile_properties({...}, positions).
local function mo(seed1, oct, isdiv, off)
  return "multioctave_noise{x=x,y=y,"..(off and ("offset_x="..off..",") or "")..
         "persistence=0.75,seed0=map_seed,seed1="..seed1..",octaves="..oct..
         ",input_scale=1/6/"..isdiv..",output_scale=0.666}"
end
data:extend({
  -- octave-structure isolation for the terrain-variation op (seed1=1064, is=1/6/4)
  { type="noise-expression", name="probe_o1", expression=mo("1064",1,4,nil) },
  { type="noise-expression", name="probe_o2", expression=mo("1064",2,4,nil) },
  { type="noise-expression", name="probe_o6", expression=mo("1064",6,4,nil) },     -- no offset
  { type="noise-expression", name="probe_o6off", expression=mo("1064",6,4,1000) }, -- with offset_x=1000 (real tv)
  -- snow-family terrain-variation seeds (snow-0..9 = 1147..1156), the real tv op
  -- (offset_x=1000, oct 6, is=1/6/4). Compare against our port per seed.
  { type="noise-expression", name="probe_tv1147", expression=mo("1147",6,4,1000) },
  { type="noise-expression", name="probe_tv1148", expression=mo("1148",6,4,1000) },
  { type="noise-expression", name="probe_tv1149", expression=mo("1149",6,4,1000) },
  { type="noise-expression", name="probe_tv1150", expression=mo("1150",6,4,1000) },
  { type="noise-expression", name="probe_tv1151", expression=mo("1151",6,4,1000) },
  { type="noise-expression", name="probe_tv1152", expression=mo("1152",6,4,1000) },
  { type="noise-expression", name="probe_tv1153", expression=mo("1153",6,4,1000) },
  { type="noise-expression", name="probe_tv1154", expression=mo("1154",6,4,1000) },
  { type="noise-expression", name="probe_tv1155", expression=mo("1155",6,4,1000) },
  { type="noise-expression", name="probe_tv1156", expression=mo("1156",6,4,1000) },
  -- the two string-seeded noises (frozen ice/snow + dirt grass)
  { type="noise-expression", name="probe_water", expression="multioctave_noise{x=x,y=y,persistence=0.75,seed0=map_seed,seed1='water',octaves=5,input_scale=1/6/8,output_scale=0.666}" },
  { type="noise-expression", name="probe_crater", expression="multioctave_noise{x=x,y=y,persistence=0.75,seed0=map_seed,seed1='crater',octaves=5,input_scale=1/6/1,output_scale=0.666}" },
})

-- FULL snow-0..9 probability expressions (reverse the tile selection rule)
data:extend({
  { type="noise-expression", name="probe_s0", expression=[[(plateau_peak_to_noise_expression(temperature,-25,25) + 1.4 * multioctave_noise{x = x,y = y,persistence = 0.75,seed0 = map_seed,seed1 = 'water',octaves = 5,input_scale = 1/6/8,output_scale = 0.666} + min(0, -1 + elevation / 5)) + 0.5 * multioctave_noise{x = x,y = y,offset_x = 1000,persistence = 0.75,seed0 = map_seed,seed1 = 1147,octaves = 6,input_scale = 1/6/4,output_scale = 0.666}]] },
  { type="noise-expression", name="probe_s1", expression=[[(plateau_peak_to_noise_expression(temperature,-25,25) + 1.4 * multioctave_noise{x = x,y = y,persistence = 0.75,seed0 = map_seed,seed1 = 'water',octaves = 5,input_scale = 1/6/8,output_scale = 0.666} + min(0, -1 + elevation / 5)) + 0.5 * multioctave_noise{x = x,y = y,offset_x = 1000,persistence = 0.75,seed0 = map_seed,seed1 = 1148,octaves = 6,input_scale = 1/6/4,output_scale = 0.666}]] },
  { type="noise-expression", name="probe_s2", expression=[[(plateau_peak_to_noise_expression(temperature,-25,25) + 1.4 * multioctave_noise{x = x,y = y,persistence = 0.75,seed0 = map_seed,seed1 = 'water',octaves = 5,input_scale = 1/6/8,output_scale = 0.666} + min(0, -1 + elevation / 5)) + 0.5 * multioctave_noise{x = x,y = y,offset_x = 1000,persistence = 0.75,seed0 = map_seed,seed1 = 1149,octaves = 6,input_scale = 1/6/4,output_scale = 0.666}]] },
  { type="noise-expression", name="probe_s3", expression=[[(plateau_peak_to_noise_expression(temperature,-25,25) + 1.4 * multioctave_noise{x = x,y = y,persistence = 0.75,seed0 = map_seed,seed1 = 'water',octaves = 5,input_scale = 1/6/8,output_scale = 0.666} + min(0, -1 + elevation / 5)) + 0.5 * multioctave_noise{x = x,y = y,offset_x = 1000,persistence = 0.75,seed0 = map_seed,seed1 = 1150,octaves = 6,input_scale = 1/6/4,output_scale = 0.666}]] },
  { type="noise-expression", name="probe_s4", expression=[[(plateau_peak_to_noise_expression(temperature,-25,25) + 1.4 * multioctave_noise{x = x,y = y,persistence = 0.75,seed0 = map_seed,seed1 = 'water',octaves = 5,input_scale = 1/6/8,output_scale = 0.666} + min(0, -1 + elevation / 5)) + 0.5 * multioctave_noise{x = x,y = y,offset_x = 1000,persistence = 0.75,seed0 = map_seed,seed1 = 1151,octaves = 6,input_scale = 1/6/4,output_scale = 0.666}]] },
  { type="noise-expression", name="probe_s5", expression=[[max(plateau_peak_to_noise_expression(temperature,-25,25) - -0.6 * multioctave_noise{x = x,y = y,persistence = 0.75,seed0 = map_seed,seed1 = 'water',octaves = 5,input_scale = 1/6/8,output_scale = 0.666}, plateau_peak_to_noise_expression(temperature,-25,25) + min(elevation, 0 - elevation) / 5) + 0.5 * multioctave_noise{x = x,y = y,offset_x = 1000,persistence = 0.75,seed0 = map_seed,seed1 = 1152,octaves = 6,input_scale = 1/6/4,output_scale = 0.666}]] },
  { type="noise-expression", name="probe_s6", expression=[[max(plateau_peak_to_noise_expression(temperature,-25,25) - -0.6 * multioctave_noise{x = x,y = y,persistence = 0.75,seed0 = map_seed,seed1 = 'water',octaves = 5,input_scale = 1/6/8,output_scale = 0.666}, plateau_peak_to_noise_expression(temperature,-25,25) + min(elevation, 0 - elevation) / 5) + 0.5 * multioctave_noise{x = x,y = y,offset_x = 1000,persistence = 0.75,seed0 = map_seed,seed1 = 1153,octaves = 6,input_scale = 1/6/4,output_scale = 0.666}]] },
  { type="noise-expression", name="probe_s7", expression=[[(plateau_peak_to_noise_expression(temperature,-25,25) - -0.6 * multioctave_noise{x = x,y = y,persistence = 0.75,seed0 = map_seed,seed1 = 'water',octaves = 5,input_scale = 1/6/8,output_scale = 0.666} + min(0, -1 + elevation / 5)) + 0.5 * multioctave_noise{x = x,y = y,offset_x = 1000,persistence = 0.75,seed0 = map_seed,seed1 = 1154,octaves = 6,input_scale = 1/6/4,output_scale = 0.666}]] },
  { type="noise-expression", name="probe_s8", expression=[[(plateau_peak_to_noise_expression(temperature,-25,25) - -0.6 * multioctave_noise{x = x,y = y,persistence = 0.75,seed0 = map_seed,seed1 = 'water',octaves = 5,input_scale = 1/6/8,output_scale = 0.666} + min(0, -1 + elevation / 5)) + 0.5 * multioctave_noise{x = x,y = y,offset_x = 1000,persistence = 0.75,seed0 = map_seed,seed1 = 1155,octaves = 6,input_scale = 1/6/4,output_scale = 0.666}]] },
  { type="noise-expression", name="probe_s9", expression=[[max(plateau_peak_to_noise_expression(temperature,-25,25) - -0.6 * multioctave_noise{x = x,y = y,persistence = 0.75,seed0 = map_seed,seed1 = 'water',octaves = 5,input_scale = 1/6/8,output_scale = 0.666}, plateau_peak_to_noise_expression(temperature,-25,25) + min(elevation, 0 - elevation) / 5) + 0.5 * multioctave_noise{x = x,y = y,offset_x = 1000,persistence = 0.75,seed0 = map_seed,seed1 = 1156,octaves = 6,input_scale = 1/6/4,output_scale = 0.666}]] },
})

-- tile-space offset variant of the tv op (x=x+1000) to test map-gen offset semantics
data:extend({
  { type="noise-expression", name="probe_ts1147", expression=[[multioctave_noise{x = x + 1000,y = y,persistence = 0.75,seed0 = map_seed,seed1 = 1147,octaves = 6,input_scale = 1/6/4,output_scale = 0.666}]] },
  { type="noise-expression", name="probe_ts1148", expression=[[multioctave_noise{x = x + 1000,y = y,persistence = 0.75,seed0 = map_seed,seed1 = 1148,octaves = 6,input_scale = 1/6/4,output_scale = 0.666}]] },
  { type="noise-expression", name="probe_ts1149", expression=[[multioctave_noise{x = x + 1000,y = y,persistence = 0.75,seed0 = map_seed,seed1 = 1149,octaves = 6,input_scale = 1/6/4,output_scale = 0.666}]] },
  { type="noise-expression", name="probe_ts1150", expression=[[multioctave_noise{x = x + 1000,y = y,persistence = 0.75,seed0 = map_seed,seed1 = 1150,octaves = 6,input_scale = 1/6/4,output_scale = 0.666}]] },
  { type="noise-expression", name="probe_ts1151", expression=[[multioctave_noise{x = x + 1000,y = y,persistence = 0.75,seed0 = map_seed,seed1 = 1151,octaves = 6,input_scale = 1/6/4,output_scale = 0.666}]] },
  { type="noise-expression", name="probe_ts1152", expression=[[multioctave_noise{x = x + 1000,y = y,persistence = 0.75,seed0 = map_seed,seed1 = 1152,octaves = 6,input_scale = 1/6/4,output_scale = 0.666}]] },
  { type="noise-expression", name="probe_ts1153", expression=[[multioctave_noise{x = x + 1000,y = y,persistence = 0.75,seed0 = map_seed,seed1 = 1153,octaves = 6,input_scale = 1/6/4,output_scale = 0.666}]] },
  { type="noise-expression", name="probe_ts1154", expression=[[multioctave_noise{x = x + 1000,y = y,persistence = 0.75,seed0 = map_seed,seed1 = 1154,octaves = 6,input_scale = 1/6/4,output_scale = 0.666}]] },
  { type="noise-expression", name="probe_ts1155", expression=[[multioctave_noise{x = x + 1000,y = y,persistence = 0.75,seed0 = map_seed,seed1 = 1155,octaves = 6,input_scale = 1/6/4,output_scale = 0.666}]] },
  { type="noise-expression", name="probe_ts1156", expression=[[multioctave_noise{x = x + 1000,y = y,persistence = 0.75,seed0 = map_seed,seed1 = 1156,octaves = 6,input_scale = 1/6/4,output_scale = 0.666}]] },
})

-- mineral-tan vs volcanic-heat full probabilities (boundary puzzle)
data:extend({
  { type="noise-expression", name="probe_mtan", expression=[[max(min(min(plateau_peak_to_noise_expression(aux,0.15,0.15), plateau_peak_to_noise_expression(moisture,0.2,0.2)), plateau_peak_to_noise_expression(temperature,80,20)), min(min(plateau_peak_to_noise_expression(aux,0.15,0.15), plateau_peak_to_noise_expression(moisture,0.2,0.2)), plateau_peak_to_noise_expression(temperature,80,20)) + min(elevation, 0 - elevation) / 5) + 0.5 * multioctave_noise{x = x,y = y,offset_x = 1000,persistence = 0.75,seed0 = map_seed,seed1 = 1043,octaves = 6,input_scale = 1/6/4,output_scale = 0.666}]] },
  { type="noise-expression", name="probe_vheat1", expression=[[min(plateau_peak_to_noise_expression(aux,0.35,0.35), plateau_peak_to_noise_expression(temperature,110,10)) + 0.5 * multioctave_noise{x = x,y = y,offset_x = 1000,persistence = 0.75,seed0 = map_seed,seed1 = 1131,octaves = 6,input_scale = 1/6/4,output_scale = 0.666}]] },
  { type="noise-expression", name="probe_vheat2", expression=[[(min(plateau_peak_to_noise_expression(aux,0.35,0.35), plateau_peak_to_noise_expression(temperature,127.5,7.5)) + min(0, -1 + elevation / 5)) + 0.5 * multioctave_noise{x = x,y = y,offset_x = 1000,persistence = 0.75,seed0 = map_seed,seed1 = 1132,octaves = 6,input_scale = 1/6/4,output_scale = 0.666}]] },
  { type="noise-expression", name="probe_vheat3", expression=[[(min(plateau_peak_to_noise_expression(aux,0.35,0.35), plateau_peak_to_noise_expression(temperature,140,5)) + min(0, -1 + elevation / 5)) + 0.5 * multioctave_noise{x = x,y = y,offset_x = 1000,persistence = 0.75,seed0 = map_seed,seed1 = 1133,octaves = 6,input_scale = 1/6/4,output_scale = 0.666}]] },
  { type="noise-expression", name="probe_mtandirt6", expression=[[(min(min(plateau_peak_to_noise_expression(aux,0.15,0.15), plateau_peak_to_noise_expression(moisture,0.5,0.1)), plateau_peak_to_noise_expression(temperature,80,20)) + min(0, -1 + elevation / 5)) + 0.5 * multioctave_noise{x = x,y = y,offset_x = 1000,persistence = 0.75,seed0 = map_seed,seed1 = 1042,octaves = 6,input_scale = 1/6/4,output_scale = 0.666}]] },
})

-- Asteroid-field billows probe: the exact multioctave used by se-asteroid
-- autoplace (prototypes/phase-3/noise-programs.lua). Compare vs asteroid.zig.
data:extend({
  { type="noise-expression", name="probe_asteroid_mo",
    expression="multioctave_noise{x=x/5, y=y/5, persistence=0.7, seed0=map_seed, seed1=1, octaves=4, input_scale=1/6, output_scale=1}" },
})

-- Full se-asteroid minus se-space margin + the resolved control values.
local am = "multioctave_noise{x=x/5,y=y/5,persistence=0.7,seed0=map_seed,seed1=1,octaves=4,input_scale=1/6,output_scale=1}"
data:extend({
  { type="noise-expression", name="probe_ast_margin",
    expression="-1 + max(-25, min(0, var('control:planet-size:size') - 25)) + min(y/var('control:planet-size:size'), 0 - y/var('control:planet-size:size')) + max("..am..", 0 - "..am..")" },
  { type="noise-expression", name="probe_ps_size", expression="var('control:planet-size:size')" },
  { type="noise-expression", name="probe_ps_freq", expression="var('control:planet-size:frequency')" },
})
