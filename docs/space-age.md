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
| Vulcanus | calcite              | 5104 / 5104 | 100%      | x1.000 |
| Vulcanus | coal                 | 3576 / 3576 | 100%      | x1.000 |
| Vulcanus | tungsten-ore         | 3896 / 3896 | 100%      | x1.000 |
| Vulcanus | sulfuric-acid-geyser | 70 / 71     | 100%      | x1.003 |
| Gleba    | stone                | 620 / 620   | 100%      | x1.000 |
| Aquilo   | fluorine-vent        | 26 / 26     | 100%      | x1.000 |
| Aquilo   | lithium-brine        | 33 / 34     | 100%      | x1.035 |
| Aquilo   | crude-oil            | 45 / 49     | 36%       | x1.151 |
| Fulgora  | scrap                | 3307 / 3290 | 91.6%     | x0.987 |

Placement (`sa_surface.World`) follows the game's chunk pass
(`EntityMapGenerationTask::generateEntities`): a 32x32 chunk is one
evaluation column (so `random_penalty` draws from one stream seeded at the
chunk origin). Every autoplaced entity belongs to a group (its autoplace
order); groups are placed in order and share ONE random stream per chunk. A
group sweeps the tiles last to first; on each tile, among its entities that
may stand there (collision layers and tile restriction, both from the data
file), the highest probability wins, the tile takes one draw, and the winner
is placed when the draw is below its probability. Non-resource entities
(rocks, trees, ruins, enemies) then take two more draws for their sub-tile
offset.

Only resources are kept, but every group up to the last resource group is
replayed, because where a resource's rolls start depends on the groups before
it. That is what makes the sparse and probability-capped resources work:
Vulcanus geysers went from 3% to 100% and Fulgora scrap from 47% to 81.5%.

What still differs is whole chunks, not individual tiles: one wrong tile on a
coastline changes how many tiles a group can use, which shifts every later
roll in that chunk. On Fulgora the chunks that fail are the ones where the
generated land/oil boundary differs from the game's; Aquilo's small ice
islands make that proportionally worse. Replaying on the game's own final
tiles (`sa_main probe --entities --tiles-from=game.json`) fixes those Fulgora
chunks (89.9%) but makes Aquilo worse, so the game evidently places entities
on tiles from before its border-correction pass.

### Entities (rocks, trees, plants, cliffs, nests)

`sa_surface.World` with `Options.entities` places every autoplaced entity of a
planet and its cliffs, following the decompiled `EntityMapGenerationTask` and
`CliffGenerator` (`ghidra/export/entity_placement.c`, `entity_cliffs.c`).

Entities:

- a tile's winner takes one draw; when it passes, an entity flagged
  `placeable-off-grid` takes two more for its position within the tile (in
  sixteenths) and any other snaps to the grid without drawing;
- compute phase (`wouldCollide`): it is dropped when its collision box touches
  a tile it collides with;
- apply phase (`applyEntities` -> `Surface::mapGeneratorWouldCollide`): the
  chunk's cliffs go onto the surface first, then its entities in generation
  order, and one is dropped when its box overlaps something already there
  that shares a collision layer - a resource of an earlier group included
  (alien-biomes trees carry the resource layer: no tree stands on ore). Only
  the chunk's own entities are known to us;
- entities of a group that tie on a tile: the first in prototype order
  (order string, then name) wins, as with tiles.

`random_penalty` (most tree and rock probabilities end in one) has two rules
that only show up once several of them share a chunk
(`RandomPenalty::run`, `ghidra/export/autoplace_order.c`): a draw is taken
only where the source is positive - elsewhere the source passes through and
the stream does not advance - and the stream's seed adds the `seed` parameter
to y as a 32-bit float, so a map-seed-sized seed swallows y's low bits. And
`multioctave_noise` with a fractional octave count rounds the count up and
widens the first octave by 2^(count - octaves).

Cliffs sit on a grid of 4x4-tile cells. `cliff_elevation` and `cliffiness` are
sampled at the cell corners and smoothed (by `cliff_smoothing`) towards the
bilinear interpolation of every 4th corner; a cell edge is crossed where the
elevation passes a cliff level (`cliff_elevation_0 + k * interval`) between its
corners and their mean cliffiness is above one half; a cell with more than two
crossed edges, or a pattern no piece fits, loses crossings one at a time
(left, top, right, bottom, never one on the chunk border); the pattern left
picks one of the 20 orientations. Three things only the comparison with the
game showed: `cliff_smoothing` is 1 when a planet leaves it out (Vulcanus);
`multisample()` offsets count steps of the grid being evaluated, so 4 tiles on
the cliff grid; and the orientation enum's order (kept in the data file).

At the game's position (to a sixteenth of a tile), map seed 341, r500:

| Planet   | Cliffs game / ours | Cliffs same position | Other entities game / ours | Same position |
| -------- | ------------------ | -------------------- | -------------------------- | ------------- |
| Vulcanus | 7899 / 8061        | 99.1%                | 19797 / 19922              | 97.6%         |
| Fulgora  | 2700 / 2755        | 99.1%                | 6335 / 6252                | 87.1%         |
| Gleba    | 2581 / 2549        | 97.6%                | 29399 / 30071              | 24.7%         |
| Aquilo   | none               |                      | 535 / 593                  | 36.8%         |

On the game's own tiles Gleba's entities are 98.4%: the rules are right, and
what is left is our tiles - one tile that differs changes how many draws a
group takes and shifts the rest of that chunk. Counts are within a few percent
everywhere. Units (pentapods, demolishers) are not autoplaced entities.

Base-game Nauvis goes through the same code from `se_wasm.zig` (`layer: 3`),
on the tiles the Nauvis generator produces (or, on the page, on the terrain
already drawn by the GPU kernel, sent along with the request - working them
out again on the CPU costs about 20 us a tile). The Nauvis resources are not
evaluated there, only their draws. Against the game (seed 341, r480): trees
98.1% and rocks 96% on the game's tile, every cliff and every spawner within 2
tiles, worms 81% within 2.

Enemy nests cannot be exact anywhere: the game spawns a few units with each
spawner as it is placed, at positions that do not come from the chunk's
stream, and those units block the nests rolled after it. We place the nests
the rolls allow - the same bases, a few more buildings than the game keeps.

The surface page draws all this as its "Entities" layer for the Space Age
planets, base-game Nauvis and - with their own data file and settings - the
Space Exploration planets and moons: see
[space-exploration-entities.md](space-exploration-entities.md). A surface too
large to draw at full size shows enemy base areas instead (below).

### Enemy base areas

The surface page can shade where the game is able to place enemy nests
(spawners and worms). It is the area, not the nests: a tile is shaded when an
enemy building may stand on it and its placement probability is positive
before the random penalty, with the opacity following the probability on a log
scale (`sa_surface.enemyAlpha`).

- Space Age planets: `World.render` evaluates the planet's own spawner / worm
  probability expressions (a second small program, `no_penalty` workspace).
  Only Gleba has autoplaced enemies; Vulcanus's demolishers are placed by
  territory, not autoplace, and are not shown.
- Nauvis and Space Exploration zones (`se_wasm.zig`, `layer: 3`): the base
  game's `enemy_base_probability` with the surface's seed and enemy settings.
  A zone takes its `enemy-base` frequency / size from its enemy tag
  (`Universe.control_settings_from_tag`) and has a half-size starting area;
  water is excluded with the zone's elevation. Sampled once per 4x4 block.

Against the game at map seed 341 over a 1280x1280 area: on Nauvis all 181
enemy buildings lie within 3 tiles of a shaded tile (177 on one), with 0.6% of
the area shaded; on Gleba all 35 spawners lie on a shaded tile, with 5.3%
shaded (most of it the faint 1-in-1000 coastal term). The Space Exploration
settings are read from the mod's source and are not checked against a live
SE game.

Placing the nests themselves was tried by continuing the chunk's placement
replay into the enemy groups. It lands in the right areas but places several
times too many (Gleba: 134 against the game's 35): where a nest fits also
depends on collisions with every tree, rock and cliff placed before it, and
cliffs are not modelled.

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

- Drawing the non-resource entities (their rolls are replayed, but nothing
  is output for them).
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
