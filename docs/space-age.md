# Space Age (Factorio 2.0) Surface Generation

Goal: generate the five Space Age DLC planet surfaces — **Nauvis, Vulcanus,
Fulgora, Gleba, Aquilo** — with the same pipeline the SE surface generator
already uses (Zig → `surface.wasm` → browser /analyze panel), bit-identical to
what the game produces.

Target game: `2.0.77` (mac-arm64) installed at
`/Applications/factorio.app/Contents/data` (base + core + space-age + SE 0.7.57
+ K2). The ghidra project (`ghidra/`) was built from an earlier 2.0.x binary —
symbols/patterns transfer, addresses shift.

## TL;DR — why this is easier than SE was

SE's ore autoplace had to be reverse-engineered from the SE mod's Lua + the
engine's `all_patches` op (hardcoded in `se_ore_placement.zig`). **In 2.0,
almost everything is data**: the planet surfaces are defined by noise
*expressions* in the game's Lua files, and even
`resource_autoplace_all_patches` is now a data-defined noise-function in
`core/prototypes/noise-functions.lua`. The engine primitive set is small; the
rest is expression composition.

So the core new component is a **generic noise-expression parser + evaluator**,
plus the handful of 2.0 engine primitives we don't have yet. Everything else —
terrain, tiles, resources, starting areas — is data.

## What's already here and reusable

| Piece | Where | Status |
| ----- | ----- | ------ |
| Triple-LFSR RNG | `surface_generator/src/rng.zig` | bit-verified vs 1.1/2.0 |
| `basis_noise` (perlin/simplex) | `noise.zig` `BasisNoiseGen` | verified |
| `multioctave_noise` | `noise.zig` `multioctaveNoise*` | verified |
| `quick_multioctave_noise` | `terrain.zig` `qmoGens` | verified |
| `random_penalty` | `noise.zig` `randomPenalty*` | verified |
| `spot_noise` (spot fields) | `noise.zig` `SpotNoiseField` | verified |
| Noise VM RE notes (op table, ctor addrs) | `surface_generator/docs/noise-system.md` | 2.0-era binary, addresses stale |
| WASM build + browser panel + worker + e2e | `se_wasm.zig`, `public/*`, `e2e/` | reuse as-is |
| Ground-truth harness (headless game, probes) | `verifier/`, `calibration/` | extend to 2.0 planets |

## The noise expression DSL

Expressions are Lua strings evaluated by the engine's compiled expression VM.
Grammar features seen in the data:

- Table-style calls: `multioctave_noise{x = x, y = y, seed0 = map_seed, seed1 = 'name', octaves = 4, input_scale = 1/9}`
- Paren calls: `max(a, b)`, `min(...)`, `clamp(v, lo, hi)`, `abs(x)`, `if(cond, a, b)`
- Arithmetic: `+ - * / % ^`, comparisons `> < >= <= ==`, `and or not`
- Variables: `x`, `y`, `map_seed`, `x_from_start`, `y_from_start`, `starting_area`
- Control lookups: `control:iron-ore:frequency` (also `:size`, `:richness`, `:bias`)
- References: `var('name')`, bare names of other expressions
- String seeds: `seed1 = 'fulgora_wobble_x'` (hashed to a number)
- `\z` line continuations (already resolved by Lua when we extract)
- `local_expressions`: per-function local names

## Engine primitives needed (vs what noise.zig has)

Builtins the planet expressions call **directly** (everything else in
`noise-functions.json` is composition):

| Primitive | noise.zig today |
| --------- | --------------- |
| `basis_noise` | ✅ `basisNoise` |
| `multioctave_noise` | ✅ |
| `quick_multioctave_noise` | ✅ |
| `random_penalty` | ✅ |
| `spot_noise` | ✅ `SpotNoiseField` |
| `amplitude_corrected_multioctave_noise` | ⚠️ data-defined in core (uses `multioctave_noise`+`basis_noise`); verify matches `variablePersistence` |
| **`voronoi_cell_id`** | ❌ NEW — grid cell ID with jitter (Fulgora) |
| **`voronoi_pyramid_noise`** | ❌ NEW — pyramid cells (Fulgora/Gleba) |
| **`voronoi_spot_noise`** | ❌ NEW — spot cones per cell (Fulgora) |
| **`voronoi_facet_noise`** | ❌ NEW — facet/edge noise (Fulgora) |
| **`terrace`** | ❌ NEW — quantize into steps (Vulcanus?) |

`voronoi_*`/`terrace` are the only engine RE work. The older binary's
`ComplexExpression<VoronoiNoise, 2, 5, 0>` ctor (`0x10015eca60`) and `Terrace,
2, 2, 0` are the starting points — re-import `ghidra/factorio-arm64` from the
current 2.0.77 binary, diff the op registration table, and check how the 2.0
data-stage maps `voronoi_cell_id{grid_size, distance_type, jitter}` etc. to ops.
Verify against in-game probes (`calculate_tile_properties`) rather than trusting
the decompiler.

## Data extraction (done — this repo)

`scripts/extract-sa-data.lua` shims `data:extend` / `require` /
`data.raw.*` and loads the pure-data game files under stock Lua (system
`lua`; the repo's `runner/bin/lua` is Linux-only). Output lands in
`surface_generator/sa-data/`:

| File | Content |
| ---- | ------- |
| `noise-functions.json` | 41 helper functions (core + base + space-age), source expressions verbatim |
| `expressions.json` | 351 named noise expressions (base + 4 planets) |
| `planets.json` | 5 planet `map_gen_settings`: `property_expression_names`, `autoplace_controls`, `autoplace_settings` (tile/decorative/entity lists), `cliff_settings`, `territory_settings` (Vulcanus demolishers) |
| `resource-autoplace.json` | direct `data.raw.resource.<name>.autoplace` overrides (fulgora scrap) |

Regenerate with: `lua scripts/extract-sa-data.lua` (override the game dir /
out dir as args). Files must be re-run when the game updates (add the version
to the header comment).

### Not yet extracted (needs the lualib helper environment)

The **tile / resource / decorative prototypes** (`base/prototypes/tile/*.lua`,
`base/prototypes/resource/*.lua`, `space-age/prototypes/tile/*.lua`, …) define
autoplace via `data:extend{type="tile", ...}` with
`autoplace = { probability_expression = "..." }`, but their files call lualib
helpers (`tile_variations_template_with_transitions`, …). Two options:
1. Load them through the shim with the helper functions shimmed too (more
   shim work, gets every field: `layer`, `map_color`, `collision_mask`, …).
2. Extract only the fields the generator needs via a targeted Lua script that
   `require`s the lualib (`core/lualib/...`) for real — those are pure Lua.

For rendering we need each tile's **map_color**; for placement its
**probability_expression**, **layer**, **collision_mask**. Resource prototypes
similarly need their autoplace (or the `property_expression_names` from
`planets.json` + `resource-autoplace.json` overrides are enough for the SA
planets, since vanilla resources are wired via the lualib shown below).

## Architecture

```
surface_generator/
├── noise.zig            + voronoi_cell_id/pyramid/spot/facet, terrace
├── noise_expr.zig        NEW: expression parser + evaluator (compiled program)
├── sa_data.zig           NEW: loads sa-data/*.json (embedded at build time)
├── sa_planet.zig         NEW: planet driver (per-tile pipeline, like se_wasm)
└── sa_wasm.zig           NEW: WASM entry, same output contract as se_wasm.zig
                          (RGBA pixels + per-resource summary) → browser panel
```

`noise_expr.zig` should mirror the game's own architecture (documented in
`docs/noise-system.md`): parse the expression into a tree, compile to a flat
op program with register caching, evaluate per (x, y, seed, controls). Bit-exact
reproduction is the target; the game's `calculate_tile_properties` / chunk dumps
are the oracle.

Per-tile pipeline per planet (mirrors the game):

1. **Terrain properties** — evaluate `property_expression_names.{elevation,
   moisture, aux, temperature}` (+ `cliffiness`/`cliff_elevation` for cliffs).
2. **Tile placement** — evaluate every tile's `probability_expression`
   (from the tile prototypes in `autoplace_settings.tile`), highest wins;
   overlays respect tile `layer` ordering; starting area overrides via
   `starting_area`/`starting_spot_at_angle`.
3. **Resource placement** — per entity in `autoplace_settings.entity`:
   `probability_expression` + `richness_expression` (from
   `property_expression_names["entity:X:probability"]` or the prototype
   autoplace); place where probability passes (per-tile RNG draw like the SE
   pass). Controls from `autoplace_controls` (defaults from the map-gen
   settings; the analyze page already has sliders for this).
4. **Render** — tile map colors + resource overlay → RGBA (reuse the segen
   renderer contract).

Nauvis = base game, so its data comes from `base/prototypes/...` + the
`planets.json` nauvis entry (mostly empty overrides — the defaults live in the
prototypes, which is why the tile/resource extraction matters for P1).

## Verification strategy

Extend the existing verifier harness (`verifier/` runs the headless game +
dumps JSON via RCON). Per planet:

1. `game.create_surface` with the planet's `map_gen_settings` at a fixed seed
   (map exchange string), or probe the planet surface directly.
2. Dump per-tile: `surface.find_tiles_filtered` / `get_tile` over a small
   region, and per-entity: `surface.find_entities_filtered`.
3. Probe noise fields with `surface.calculate_tile_properties('elevation'|…,
   x, y)` for exact value comparison (like the SE `--zone-field-probe` path).
4. Compare against the Zig output — tile identities and resource
   positions/amounts must match exactly.

The e2e test (`e2e/analyze-surface.test.mjs`) extends to click a planet and
cross-check against the native binary's output for that planet (same pattern as
the current segen cross-check).

## Phased plan

- **P0 — expression engine.** `noise_expr.zig`: parser + evaluator over the
  existing verified primitives; validate by evaluating expressions that reduce
  to primitives already verified (e.g. a `multioctave_noise{...}` expression
  vs `noise.zig`'s output, `lerp`, `slider_to_linear`, `spot_at_angle`). Add
  `voronoi_*` + `terrace` to `noise.zig`; RE from the current binary; verify
  each against in-game probes on Nauvis.
- **P1 — Nauvis.** Tile + resource prototype extraction; full vanilla 2.0
  surface (grass/dirt/sand/water + iron/copper/coal/stone/uranium/crude-oil +
  starting area). Exercises the whole pipeline on the simplest planet.
- **P2 — Vulcanus + Aquilo.** Lava/volcanic tiles + tungsten/coal/calcite +
  sulfuric acid geysers; frozen ocean + ammonia/lithium. Simple expression
  sets (359–923 lines).
- **P3 — Fulgora + Gleba.** Voronoi island terrain, oil ocean, scrap/ruins,
  holmium-via-scrap; swamp/soil + agriculture resources. Most complex
  (601–1271 lines), needs the voronoi ops.
- **P4 — Integration.** Planet selector on the analyze page (browser WASM),
  controls (frequency/size/richness sliders), e2e cross-checks per planet.

## Key files in the game data

| Path (under `<data>`) | Content |
| --------------------- | ------- |
| `core/prototypes/noise-functions.lua` | engine helper functions (incl. `resource_autoplace_all_patches`!) |
| `core/lualib/resource-autoplace.lua` | how vanilla resources wire controls → expressions |
| `base/prototypes/noise-expressions.lua` | Nauvis terrain/tile/resource expressions |
| `base/prototypes/planet/planet-map-gen.lua` | Nauvis map_gen_settings |
| `space-age/prototypes/planet/planet-map-gen.lua` | 4 planet map_gen_settings |
| `space-age/prototypes/planet/planet-{vulcanus,gleba,fulgora,aquilo}-map-gen.lua` | per-planet expressions + resource autoplace overrides |
| `base/prototypes/tile/tiles.lua`, `space-age/prototypes/tile/tiles-*.lua` | tile prototypes (autoplace, layer, map_color) |
| `base/prototypes/resource/*.lua` | resource prototypes |
