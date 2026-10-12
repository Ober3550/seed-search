# Space Exploration: the entities layer

Rocks, trees, cliffs and enemy nests on Space Exploration planets, moons and
Nauvis, placed by the same pass as the Space Age planets
([space-age.md](space-age.md), "Entities") with Space Exploration's own data
and settings.

- `surface_generator/src/se_noise_data.json` - the map-generation data of the
  SE mod set (base + space-exploration + alien-biomes), built by
  `scripts/sa-build-data.py`.
- `surface_generator/src/se_zone.zig` - the map-gen settings SE gives a
  surface, rebuilt from what the universe generator knows.
- `surface_generator/src/se_wasm.zig`, `layer: 3` with `"entities": true` -
  the pass itself, run on the terrain the page has already drawn.

## How a zone's surface is defined

SE's planets and moons are not planet prototypes. `Zone.create_surface`
(`scripts/zone.lua`) builds the surface's `map_gen_settings` when a player
first reaches the zone:

| Setting                    | Where it comes from                                                             |
| -------------------------- | ------------------------------------------------------------------------------- |
| seed                       | the zone's seed                                                                 |
| what may spawn             | a fixed list (`Zone.set_autoplace_settings_for_solid`): 117 entities, 161 tiles |
| `hot`, `cold`              | temperature tag; frequency x 5000 / radius                                      |
| `trees`, `enemy-base`      | trees / enemy tag, not scaled                                                   |
| resources                  | the universe generator's controls; a size of 0 keeps the resource off the list  |
| `planet-size`              | frequency 1 / 6 / 2^(radius x 6 / 10000 - 6)                                    |
| cliffs                     | cliff tag: interval 40 / frequency, first level a quarter of it, richness       |
| `starting_area`            | 0.5                                                                             |
| `water`                    | the map's own (1 by default) - see below                                        |
| `rocks`, the cliff control | **rolled when the surface is created** - see below                              |

The data builder writes that list as one more planet, `se-zone` (Nauvis's
wiring with the zone lists):

```sh
python3 scripts/sa-build-data.py --dump <SE data-raw-dump.json> \
    --mods base,space-exploration,alien-biomes \
    --se-zone-lua <space-exploration>/scripts/zone.lua --no-decoratives \
    --out surface_generator/src/se_noise_data.json
```

Things the live game showed that the mod's source does not say:

- **The moisture, aux and water tags change nothing but the tile list.** SE
  writes them to settings the 2.0 engine no longer reads
  (`control-setting:moisture:bias`, `mapgen.water`, ...). A live zone's water
  control stays 1 / 1; only `water_none` matters, by leaving the water tiles
  off the list. The zone terrain used a water size of 1.5 before, which put
  water where the game has none away from a moon's centre.
- **Every surface has a starting lake**, on the same ring as Nauvis's, placed
  from the surface's seed. A zone's elevation only matches the game with it.
- **A waterless zone still has its elevation**: the snow and ice variants read
  it. Treating it as flat gave 38% of a frozen moon's tiles; with it, 99.97%.
- The engine divides the cliff interval by the cliff control's frequency and
  multiplies the richness by its size.

## What the seed does not decide

`Zone.create_surface` fills every control a tag does not set with
`math.random()` - the game's shared generator, whose state depends on
everything that happened in the save before the surface was created. On a
planet or moon those are:

- `rocks`: frequency 0.17 + random x random x 2 (then x 5000 / radius). The
  alien-biomes rocks take their noise's octave count from it, so it decides
  where the rock fields are.
- the cliff control: frequency 0.17 + random x random x 10 (then x 5000 /
  radius) and size 0.1 + random x 0.8. They set the spacing of the cliff
  levels and how continuous the cliffs are.

No two saves agree on these, so `se_zone.Rolls` holds the medians. Rocks and
cliffs come out in the right amounts and shapes but not at the positions of
any particular save. Trees and enemy nests depend only on the tags and the
seed - but they are placed after the rocks from the same per-chunk random
stream, and they are dropped where a rock or cliff is in the way, so their
individual positions shift with the rolls too. The forests and the bases do
not move.

A request can carry the real rolls (`zone.rolls = { rocks_frequency,
cliff_frequency, cliff_size }`, the zone's own controls as SE stores them);
that is how the pass itself is checked.

## Accuracy

Live game: Factorio 2.0.77, Space Exploration 0.7.57, alien-biomes 0.7.4, map
seed 1000, default map settings. `calibration/sa-probe/probe_se_zone.py` lets
SE create the zone's surface and dumps its settings, tiles and entities.

The pass, given the game's tiles and the game's rolls (entities at the game's
position to a sixteenth of a tile):

| Moon   | Climate                        | Trees         | Rocks         | Huge rocks    | Cliffs        |
| ------ | ------------------------------ | ------------- | ------------- | ------------- | ------------- |
| Hermes | balanced, water, trees, cliffs | 98.7% of 6776 | 98.5% of 1379 | 98.2% of 673  | 95.6% of 1557 |
| Talos  | very hot, water, many trees    | 99.2% of 2389 | 98.7% of 2245 | 98.9% of 1251 | none          |
| Muir   | frozen, no water               | none          | 96.7% of 398  | 98.5% of 270  | none          |

Ore placed by the same data is tile-exact on all three (it decides where the
trees may not stand). Enemy nests land in the game's bases - every game
spawner has one of ours within 8 tiles - but not on its tiles: see "Enemy
nests cannot be exact" in space-age.md.

What the page shows - our own terrain, typical rolls:

| Moon   | Our tiles right | Trees: count game / ours | within 2 tiles | within 8 | Rocks: count game / ours |
| ------ | --------------- | ------------------------ | -------------- | -------- | ------------------------ |
| Hermes | 97.3%           | 6776 / 6924              | 83%            | 99.5%    | 2052 / 2162              |
| Talos  | 96.2%           | 2389 / 2283              | 65%            | 98.2%    | 3496 / 3569              |
| Muir   | 99.97%          | none                     |                |          | 668 / 757                |

With the game's rolls and our tiles the trees are 90% within 2 tiles on
Hermes: the rest of the gap is the terrain. One tile that differs changes how
many draws a group takes and shifts the rest of its chunk.

## Ore

The same pass places the zone's ore, and it is the game's ore: with our own
terrain and our own resource controls, 98.8% to 100% of the game's ore tiles
on four moons (Bluna of seed 80352098, and Hermes, Talos and Muir of seed
1000; the few extra tiles are secondaries whose controls come out a little
high). The older hand-written SE ore code (`se_ore_placement.zig`) gives 50%
to 86% on the same windows - patches missing or elsewhere once away from the
centre. So on the page an SE planet or moon takes its ore from this pass
(`layer: 4`: one request per cell returns the ore and the entities), after
the terrain rather than alongside it. The older code still serves what the
pass does not cover: Krastorio 2 universes, Nauvis under SE, asteroid fields
and surfaces too large to draw at full size.

## Core seams

Core seams (where a core miner can be built) are not autoplaced: SE's
`CoreMiner.generate_core_seam_positions` puts 5 + 95 x radius / 10000 of them
on a golden-angle spiral out from the centre, one per band of radius, each
nudged by a random generator seeded with the zone's seed. They follow from the
seed exactly - 23 of 23 at the game's position on five surfaces (Hermes,
Talos, Muir, Bluna, and Nauvis, which uses its zone seed, not the map seed:
the universe generator returns it as `hs` / `hr`). The page computes them
itself (`coreSeams` in surface.js) and draws them as their own group. The game
also clears the ore and entities under a seam and turns water there into land;
the marker simply covers that area.

## On the page

SE planets, moons and Nauvis get the "Entities" layer (checkboxes per group;
trees are drawn under the ore, everything else over it; rocks start unticked,
since alien-biomes flags them `not-on-map` and the game's own map does not
draw them) when the surface is
drawn at full size - the entities are placed on the tiles of the terrain
canvas. A surface larger than the canvas limit keeps the enemy base areas.

Cost: 3 to 7 us a tile on top of the terrain and ore (a moon of radius 600 in
about a second, a planet of radius 4000 in about 25 seconds, on ten cores).
Two things keep it there: an entity that cannot stand on any tile of a chunk
is not evaluated in it, and `spot_noise` picks out the spots near a chunk once
instead of walking nine regions' spots for every tile.

## Not done

- Krastorio 2 resources (the data file is the SE set without K2; a K2 zone's
  entities are placed without them).
- Biome replacements of the named zones (`zone.biome_replacements`): SE swaps
  tiles after generation there; neither the terrain nor the entities know.
- Entities reaching across a chunk border only see their own chunk.
