# Space Exploration Resource Generation Rules

Extracted from Space Exploration 0.7.57 (`se_extracted/space-exploration_0.7.57/`).
SE overrides vanilla resource autoplace with its own noise function
`se_resource_autoplace_all_patches` and settings wrapper.

Sources:
- `prototypes/resource_autoplace_overrides.lua` — SE constants + noise function + `resource_autoplace_settings`
- `prototypes/phase-3/resources.lua` — applies autoplace to every `data.raw.resource` with defaults
- `data.lua` (lines 54-87) — the `se_resources` per-resource override table

The **per-zone resource selection & richness bias** is separate — that's the
universe generator (`universe_generator/`, `computeZoneResources`). This doc is
the **per-resource tile-placement** rules that run once a zone's resource set +
map-gen controls are known.

---

## 1. SE-wide constants (differ from vanilla `__core__`)

| Constant                                                 | SE                     | vanilla  | Where used                        |
| -------------------------------------------------------- | ---------------------- | -------- | --------------------------------- |
| `base_distance` / `double_density_distance`              | **5000**               | 1300     | density/richness distance scaling |
| `regular_patch_fade_in_distance`                         | **320**                | 300      | fade-in ring width                |
| `starting_resource_placement_radius`                     | **140**                | 120      | starting patch region             |
| `starting_patches_split`                                 | **1/4**                | 1/2      | starting spot quantity divisor    |
| `candidate_spot_count`                                   | **64** (all resources) | 21/22/32 | spot candidates per region        |
| `suggested_minimum_candidate_point_spacing` (starting)   | **128**                | 32       | Poisson spacing                   |
| `rs_suggested_minimum_candidate_point_spacing` (regular) | **128**                | 45.2548  | Poisson spacing                   |
| `size_boost`                                             | **4**                  | 0        | flat spot-radius bonus            |
| `maximum_spot_basement_radius` (starting)                | **64**                 | 128      | basement cull radius              |
| `maximum_spot_basement_radius` (regular)                 | 128                    | 128      | basement cull radius              |
| `starting_amount_val`                                    | **100000**             | 20000    | starting patch total              |
| `starting_rq_factor` divisor                             | **/8**                 | /7       | starting radius factor            |

## 2. Structural differences vs. the vanilla port we already have

These are the code changes needed to turn our Nauvis engine into the SE engine:

1. **`se_distance` remap** (replaces raw `distance` everywhere):
   ```
   se_distance = clamp(5000 + clamp(control:planet-size:richness, 0, 1) * (distance - 5000), 0, 5000)
   ```
   For non-homeworld zones SE sets `planet-size:richness = 0`, so `se_distance = 5000`
   (constant) → density/patch-size/richness become **distance-independent** on those zones.
   On the homeworld it behaves ~like vanilla out to 5000.

2. **Control sliders are raised to power 0.8**: `setting_scale(v) = v^0.8`, applied to
   `frequency_multiplier`, `size_multiplier`, and the richness post-multiplier.

3. **`spot_radius_expression = size_boost + min(32, rq * q^(1/3))`** (regular) — a flat +4.
   Starting: `size_boost/2 + starting_rq_factor * q^(1/3)`.

4. **Regular blob term adds veins**:
   ```
   (blobs0 + basis_noise{1/64,1.5} - 1/3 + 0.8 * vein * random_probability) * regular_blob_amplitude_at(se_distance)
   vein = 1 - 10 * abs(multioctave_noise{persistence=0.5, input_scale=1/4, octaves=6, seed1=seed1})
   ```
   Starting adds `0.2 * start_vein * random_probability`, `start_vein` uses `input_scale=1`.
   (Note: `random_probability` here is the per-resource value, even though the noise
   function itself is passed `random_probability = 1` — see wrapper below.)

5. **`spots_per_km2_near_start = base_spots_per_km2 * frequency_multiplier`**, and
   `regular_spot_quantity_base_at(d) = regular_density_at(d) * 1e6 / spots_per_km2_near_start`.

6. **`random_probability = 1` is hardcoded into the noise expression** (so spot quantity
   is NOT thinned by random_probability). Instead the wrapper applies `random_penalty`
   to the *probability* expression and `/ random_probability` to *richness* (see §4).

7. **richness distance multiplier**: `max(1, (5000 + sed) / (5000 + 5000))` where
   `sed = se_distance - 320` (for starting-area resources) — with `se_distance=5000` on
   space zones this is `max(1, (5000+4680)/10000) = max(1,0.968) = 1` (flat).

8. **`starting_rq_factor = starting_rq_factor_multiplier / 8`** (vanilla /7).

Everything else (spot_noise op, region seeding, random_penalty op, basis_noise op,
cone contribution, max-combine) is identical to the vanilla port — only the wrapping
expressions and constants change.

## 3. The SE noise function `se_resource_autoplace_all_patches`

Parameters (16): `base_density, base_spots_per_km2, candidate_spot_count,
frequency_multiplier, has_starting_area_placement, random_spot_size_minimum,
random_spot_size_maximum, regular_blob_amplitude_multiplier, regular_patch_set_count,
regular_patch_set_index, regular_rq_factor, seed1, size_multiplier,
starting_blob_amplitude_multiplier, starting_patch_set_count, starting_patch_set_index,
starting_rq_factor, random_probability`.

Top: `if(has_starting_area_placement == 1, max(starting_patches, regular_patches), regular_patches)`.

Regular `spot_noise{}` params: `region_size=1024`, `candidate_spot_count=64`,
`suggested_minimum_candidate_point_spacing=128`, `hard_region_target_quantity=0`,
`maximum_spot_basement_radius=128`, `basement_value = -6*max(regular_blob_amplitude_at(...), starting_blob_amplitude)`.
Density/quantity/radius as in §2.3/§2.5. Full expressions in the source file.

## 4. Settings wrapper (`resource_autoplace_settings`) → per-resource expressions

```
probability = clamp(var('default-<name>-patches'), 0, 1)
              [ * random_penalty{source=1, amplitude=1/random_probability} if random_probability<1 ]
richness    = var('default-<name>-patches')
              [ / random_probability ]
              [ + additional_richness ]
              [ max(.., minimum_richness) ]
              * max(1, (5000 + (se_distance - 320)) / 10000)          -- richness_distance_multiplier
              * (richness_post_multiplier * (control:<name>:richness)^0.8)
control = <name>   (each resource has its own autoplace control)
```

## 5. Per-resource parameters

Defaults (phase-3): `has_starting_area_placement=true`, `base_density=5`,
`regular_rq_factor_multiplier=1.1`, `starting_rq_factor_multiplier=1`,
`base_spots_per_km2=2.5` (noise default; fluid branch uses 1.8), `seed1=100`,
`random_spot_size_minimum=0.25`, `random_spot_size_maximum=2.0`.

Fluid branch (resources with `collision_box[1][1] < -0.5`, e.g. oil-like): defaults
`base_spots_per_km2=1.8`, and if no `random_probability` set: `random_probability=1/48`,
`random_spot_size_min/max=1`, `additional_richness=220000`, `has_starting=false`.

| Resource         | base_density | base_spots_per_km2 | random_prob | rq_mult (reg/start) | random_spot_size (min/max) | has_starting | additional_richness | order |
| ---------------- | ------------ | ------------------ | ----------- | ------------------- | -------------------------- | ------------ | ------------------- | ----- |
| iron-ore         | 14           | 2.5                | 1           | 1.1 / 1.5           | 0.25 / 2.0                 | yes          | 0                   | c-a   |
| copper-ore       | 12           | 2.5                | 1           | 1.1 / 1.5           | 0.25 / 2.0                 | yes          | 0                   | c-b   |
| stone            | 12           | 2.5                | 1           | 1.1 / 1.5           | 0.25 / 2.0                 | yes          | 0                   | c-c   |
| coal             | 9            | 2.5                | 1           | 1.1 / 1.5           | 0.25 / 2.0                 | yes          | 0                   | c-e   |
| uranium-ore      | 1            | 2                  | 1           | 1.1 / 1             | 2 / 4                      | **no**       | 0                   | c-d   |
| crude-oil        | 8            | 2.5                | **1/24**    | 1.2 / 1.5           | 1 / 1                      | yes          | **220000**          | e-a   |
| se-vulcanite     | 10           | 5                  | 1           | 1.1 / 1             | 0.25 / 2.0                 | yes          | 0                   | b-v   |
| se-cryonite      | 10           | 5                  | 1           | 1.1 / 1             | 0.25 / 2.0                 | yes          | 0                   | b-c   |
| se-vitamelange   | 10           | 2.5                | 1           | 1.1 / 1             | 0.25 / 2.0                 | yes          | 0                   | a-a   |
| se-iridium-ore   | 5            | 2.5                | 1           | 1.1 / 1             | 0.25 / 2.0                 | yes          | 0                   | a-b   |
| se-holmium-ore   | 5            | 2.5                | 1           | 1.1 / 1             | 0.25 / 2.0                 | yes          | 0                   | a-b   |
| se-beryllium-ore | 5            | 2.5                | 1           | 1.1 / 1             | 0.25 / 2.0                 | yes          | 0                   | a-b   |
| se-naquium-ore   | 1            | 2.5                | 1           | 1.1 / 1             | 0.25 / 2.0                 | yes          | 0                   | a-a   |
| se-water-ice     | 5            | 2.5                | 1           | 1.1 / 1             | 0.25 / 2.0                 | yes          | 0                   | f-a   |
| se-methane-ice   | 5            | 2.5                | 1           | 1.1 / 1             | 0.25 / 2.0                 | yes          | 0                   | f-b   |

`se-` prefix = `data_util.mod_prefix` (`"se-"`). Krastorio2 compat adds
`kr-rare-metal-ore`, `kr-mineral-water`, `kr-imersite` when K2 present (see
`phase-1/compatibility/krastorio2/resource-gen.lua`).

## 6. Per-zone controls — all static, mostly already computed

The per-zone `control:<name>:frequency/size/richness` values are **not** runtime-only;
they're derived from static zone data + the zone seed, and `universe_generator` already
computes them:

- **Static zone presets**: `scripts/universe-raw.lua` defines each named planet/moon with
  `primary_resource`, `preset_resource_bias = {<resource> = 0..1}`, and climate `tags`.
- **Per-zone resource controls** (`freq`, `size`, `richness` per resource): computed by
  `universe_generator/zig/gen.zig` `computeZoneResources` (lines 528-544):
  ```
  resource_value = (RESOURCE_SECONDARY_IRREGULARITY*base_bias
                    + (1-RESOURCE_SECONDARY_IRREGULARITY)*ordered_bias) ^ RESOURCE_POWER
                   (primary resource: resource_value = 1 + RESOURCE_PRIMARY_BOOST)
  freq     = lerp(freq_lo, freq_hi, resource_value)
  size     = lerp(size_lo, size_hi, resource_value)
  richness = lerp(rich_lo, rich_hi, resource_value)
  ```
  It currently returns only the collapsed `fsr = freq*size*richness` (normalized). **To
  drive this autoplace engine, expose `freq`/`size`/`richness` individually** — they map
  straight to `control:<name>:frequency/size/richness` (then SE applies `^0.8`).
  The `*_lo`/`*_hi` bounds are zone-type dependent (see the constants near that function).
- **Applying to the surface**: `Zone.apply_controls_to_mapgen` + `set_autoplace_settings_for_solid`
  / `_for_space` (zone.lua) copy `zone.controls` into `map_gen_settings.autoplace_controls`,
  clamp `richness`/`size >= 0`, multiply frequency by `Zone.get_frequency_multiplier(zone)`,
  and (space zones) set `planet-size:richness = 0` → `se_distance = 5000` constant.

### Remaining genuinely-runtime item
- **`skip_offset` / `regular_patch_set_count`**: patch-set indexes are assigned in the
  order `phase-3/resources.lua` iterates `data.raw.resource`. This is data-stage
  deterministic (not per-zone), so capture it once — either replicate the iteration order
  or dump the compiled `regular_patch_set_index` per resource a single time.
