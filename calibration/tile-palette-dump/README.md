# tile-palette-dump — authoritative tile map-colour dump (2.0.77)

The SA/base planet tile prototypes define their `map_color` with template
helpers and computed expressions (e.g. fulgora `oil-ocean-deep`'s
`{49*1.15, 31*1.15, 35*1.15}`, aquilo's `lerp_color_no_alpha(...)`), so
statically reading the Lua is wrong. This mod runs in the **data stage** (after
every prototype is loaded, so the game has fully resolved each tile) and logs
every `data.raw.tile` entry:

```
TPD\t<name>\t<r>\t<g>\t<b>\t<layer>\t<subgroup>
```

The data stage can't write files, so the dump goes to `factorio-current.log`
(the runner below pulls it out).

## Run

```sh
scripts/extract-tile-palettes.sh
```

This boots the headless game once (mods dir = `base` + this mod only; space-age
is the built-in DLC and loads automatically) and writes:

- `surface_generator/biome/tiles-dump.json` — every tile's
  name / colour (0–255) / layer / subgroup (regenerable).
- `surface_generator/biome/planet-tiles.json` — per-planet palettes
  (`nauvis|vulcanus|fulgora|gleba|aquilo` → `[{name, color, layer}]`), keyed by
  each planet's `autoplace_settings.tile.settings` list from
  `sa-data/planets.json`.

Regenerate after the game updates (bump the version comment in the outputs).

## Output contract

Colours are 0–255 ints (0–1 float map_colors scaled by 255, other computed
colours rounded by the game's own math). `layer` is the tile layer from the
prototype. `subgroup` is the planet tileset key (e.g. `fulgora-tiles`,
`nauvis-tiles`) — empty for special tiles.
