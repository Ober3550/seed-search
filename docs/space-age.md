# Space Age (Factorio 2.0) Surface Generation

A general, data-driven surface generator: it reads the same map-generation data
the game does (noise expressions, noise functions, tile autoplace expressions,
planet `map_gen_settings`) and runs it through one engine. There is no
per-planet code — Fulgora, Vulcanus, Gleba and Aquilo all go through the same
path, and so would a mod's planets after regenerating the data file.

Target game: `2.0.77` (mac-arm64) at `/Applications/factorio.app`.

## Status

Tile maps, checked against the live game at map seed 341 (2,401 sample points
over ±480 tiles per planet; Fulgora additionally against a full 785,456-tile
in-game dump of the r500 disk):

| Planet   | Tiles matching the game  | Notes                                    |
| -------- | ------------------------ | ---------------------------------------- |
| Aquilo   | 99.7%                    |                                          |
| Fulgora  | 98.9% (98.66% full r500) |                                          |
| Gleba    | 97.0%                    |                                          |
| Vulcanus | 95.5%                    |                                          |
| Nauvis   | not through this engine  | needs `expression_in_range`, lake points |

Every named expression the tiles depend on matches `calculate_tile_properties`
to float rounding (worst case a few parts in 10^5 on values in the hundreds).
The remaining tile differences sit on the borders between tile regions: the
game runs a tile-transition correction pass after the per-tile competition
(the same pass the SE generator skips), which this generator does not model.
A dense in-game dump confirms the game's own expression values predict its
tiles at the same ~96% on Vulcanus.

Speed: about 2 µs per tile native, 1.6–5.7 µs in wasm — an r500 disk renders
in 0.2–2.2 s in the browser across the worker pool.

### Resources

Resource entities, checked against every resource the game placed in the
r500 square at map seed 341 (position = same tile, amount = total):

| Planet   | Resource             | Game / ours | Same tile | Amount |
| -------- | -------------------- | ----------- | --------- | ------ |
| Vulcanus | calcite              | 5104 / 5105 | 100%      | x1.000 |
| Vulcanus | coal                 | 3576 / 3574 | 99.9%     | x1.000 |
| Vulcanus | tungsten-ore         | 3896 / 3895 | 99.9%     | x1.000 |
| Vulcanus | sulfuric-acid-geyser | 70 / 71     | 3%        | x1.109 |
| Gleba    | stone                | 620 / 620   | 100%      | x1.000 |
| Aquilo   | fluorine-vent        | 26 / 26     | 100%      | x1.000 |
| Aquilo   | lithium-brine        | 33 / 34     | 100%      | x1.035 |
| Aquilo   | crude-oil            | 45 / 61     | 9%        | x1.140 |
| Fulgora  | scrap                | 3307 / 3247 | 47%       | x0.957 |

Placement (`sa_surface.World`) follows the game's chunk pass: a 32x32 chunk
is one evaluation column (so `random_penalty` draws from one stream seeded at
the chunk origin — confirmed by tungsten matching tile for tile), resources
compete group by group in autoplace order, the highest probability wins a
tile, and it is placed when a draw from the chunk's placement stream falls
below it. Tiles whose collision mask has the `resource` layer take none.

Resources whose probability saturates at 1 are exact. The three that are not
(scrap is capped at probability 0.5; geysers and Aquilo crude oil are sparse
by design) depend on the placement stream, which the game shares with every
other entity group in the chunk (ruins, rocks, trees); those groups are not
generated, so the draws differ. Their patches are in the right places with
the right density, but not the same individual tiles.

### Nauvis (base game) resources

Without Space Exploration the page places Nauvis resources with the
base-game port (`ore_placement.zig`), and uses this engine for one thing:
`sa_surface.EntityRolls` replays the rock, tree, enemy and fish placement
rolls of a chunk (their probability expressions compile from the data file;
nothing is placed or drawn) so the resource groups start at the right position
in the chunk's shared placement stream. It only runs in chunks that contain
ore. Against the game at seed 341 over a 3000x3000 area: 72,192 of 72,205
resource entities on the same tile, crude oil 108 of 114 wells (115 placed).

Not done yet:

- Non-resource entities (ruins, rocks, trees, enemy bases) — also what would
  make scrap, geysers and Aquilo crude oil tile-exact.
- Cliffs, decoratives.
- The tile-transition correction pass.
- Nauvis through this engine (it still uses the dedicated generator):
  `expression_in_range` and `starting_lake_positions` are not implemented.
- Tile generation's `random_penalty` batch shape is assumed to be the chunk
  column too (only `vulcanus_metal_tile` depends on it).

## Pipeline

```
factorio --dump-data                      the game's own data stage (any mods)
        │  scripts/sa-build-data.py
        ▼
surface_generator/src/sa_noise_data.json  expressions, functions, tiles, planets
        │  @embedFile
        ▼
sa_data.zig      load definitions + planet wiring
sa_expr.zig      parse the noise-expression DSL
sa_program.zig   compile roots to one straight-line program; evaluate in batches
sa_surface.zig   tile competition (argmax) + resource placement, per chunk
        │
        ├─ sa_main.zig   native CLI (info / check / deps / probe / render)
        └─ sa_wasm.zig   browser module → space_explorer_gui /surface page
```

Regenerate the data after a game update or to target a different mod set:

```sh
python3 scripts/sa-build-data.py            # runs factorio --dump-data
python3 scripts/sa-build-data.py --mods base,quality,elevated-rails,space-age
node install.mjs                            # rebuilds sa.wasm
```

### The data file

| Section       | Content                                                                                                                                                                                                                    |
| ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `expressions` | every named noise-expression, plus one entry per autoplaced prototype under the engine's property names: `tile:<name>:probability`, `entity:<name>:probability`, `entity:<name>:richness`, `decorative:<name>:probability` |
| `functions`   | every noise-function                                                                                                                                                                                                       |
| `tiles`       | layer and map colour of each autoplaced tile                                                                                                                                                                               |
| `planets`     | per planet: `seed_offset`, `property_expression_names`, autoplace controls, cliff settings, and the tile / entity / decorative lists of its `autoplace_settings`                                                           |

### The engine (`sa_program.zig`)

Mirrors how the game compiles noise programs:

- **Lowering.** Named expressions and function calls are inlined into a DAG of
  primitive ops. Scoping follows the data stage: parameters and local
  expressions / local functions of the current definition, then the surface's
  `property_expression_names` overrides (so a bare `elevation` inside
  `water_base` means the planet's elevation), then engine variables, then
  global definitions. Arguments are bound lazily in the caller's scope.
- **Sharing.** Identical sub-expressions are hash-consed, so the elevation
  chain every tile probability references is evaluated once per position.
- **Constant folding.** Anything that depends only on the seed and controls
  folds at compile time, which is how noise-op parameters (seeds, octaves,
  grid sizes) become prebuilt generators. A program is compiled per
  (planet, seed, controls).
- **Evaluation.** Straight-line, over a column of positions, f32 registers.
- **Position contexts.** `multisample(expr, dx, dy)` lowers `expr` again with
  `x`/`y` shifted. `spot_noise` evaluates its density / quantity / radius /
  favorability sub-expressions at a region's candidate points, so those are
  compiled into their own sub-program (which may itself contain spot noise).

Ops: arithmetic, comparisons, `min`/`max` (n-ary), `clamp`, `if`, `&`, `sin`,
`cos`, `sqrt`, `floor`, `ceil`, `exp`, `log2`, `pow`, `var`, `basis_noise`,
`multioctave_noise`, `quick_multioctave_noise`,
`variable_persistence_multioctave_noise`, `random_penalty`, the four
`voronoi_*` outputs, `terrace`, `spot_noise`, `multisample`,
`distance_from_nearest_point[_x|_y]` (starting positions only).

## Facts pinned against the live game

- **Planet seeds.** A planet's surface seed is `map_seed + crc32(planet name)`
  (mod 2^32); Nauvis uses the map seed. Fulgora at map seed 341 is
  2967579351. Comparing a planet at the raw map seed compares two unrelated
  maps — this was the cause of the earlier 37% Fulgora agreement.
- **Sampling position.** Tile generation evaluates a tile at its integer
  coordinate (top-left corner), not its centre.
- **Ties.** Equal probabilities are common by design (Gleba's clamped range
  selectors). The first tile in prototype order — `(order, name)` — wins.
- **Constants.** Constant sub-expressions fold in f32, not double: the
  starting-area angle `map_seed / 360 / 180 * pi` only reproduces the game's
  sin/cos when computed in f32.
- **Multioctave noise.** The octave normalisation is
  `sqrt((q - 1) / (exp2f(log2(q) * n) - 1))` with `q = 1/persistence²` and the
  engine's *approximate* `Math::log2` / `Math::exp2f`, about 1 part in 10^4
  away from the ideal RMS value. `noise.exact` ports the kernels
  operation-for-operation from `ghidra/export/terrain_noise.c`.
- **Voronoi `grid_size`** truncates to an integer (Fulgora's `175 / 8`).
- **Spot noise.** Default candidate count 256, default spacing
  `sqrt(region² / points) / 2`, `hard_region_target_quantity` defaults true;
  candidates are stable-sorted by favorability; spot placement is f32 with
  the engine's approximate cube root.
- **Two engine paths.** Ops whose inputs are the raw position registers take
  a rectangle fast path during map generation; `calculate_tile_properties`
  (the oracle) takes the vector path. They round differently in the last
  bits. The generator implements the vector path.

## Verifying

`calibration/sa-probe/probe_surface.py` boots a headless game, creates the
planet's surface from its prototype, and dumps any named expressions plus the
generated tiles over a grid. `sa_main <planet> probe` writes the same layout,
and `diff_surface.py` compares them expression by expression.

```sh
cd surface_generator && zig build
./zig-out/bin/sa_main fulgora deps | sort > /tmp/names.txt
python3 ../calibration/sa-probe/probe_surface.py fulgora 341 -480:480:-480:480:20 \
    /tmp/game.json --tiles --names-file /tmp/names.txt
./zig-out/bin/sa_main fulgora probe 341 -480:480:-480:480:20 /tmp/ours.json \
    --tiles $(cat /tmp/names.txt)
python3 ../calibration/sa-probe/diff_surface.py /tmp/game.json /tmp/ours.json
```

`zig build test` runs the regression vectors in `src/sa_test.zig` (game tiles
and elevation values for all four planets) without needing the game.

Resources: add `--entities` to both probes. Other tools:
`sa_main <planet> render <seed> <radius> out.png` (also writes
`out-resources.png`, the resource layer on a transparent background),
`sa_main <planet> check` (what compiles), `sa_main <planet> info`.

## Reverse-engineering references

- `surface_generator/docs/noise-system.md` — noise VM notes, voronoi hash.
- `ghidra/export/terrain_noise.c`, `multioctave_core.c` — basis / multioctave
  / quick / variable-persistence kernels.
- `ghidra/export/spot_noise.c` — spot list generation, placement, op run.
- `ghidra/export/voronoi.c`, `terrace.c` — voronoi and terrace ops.
- `calibration/sa-probe/README.md` — the per-op probe harness used to pin the
  voronoi and terrace ports.
