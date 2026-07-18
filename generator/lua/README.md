# Generator

Core seed-generation engine for the Space Exploration universe seed finder.

## Files

- `summarize.lua` — generates a Factorio SE universe for a given seed and produces a scored summary
- `se_env.lua` — Factorio runtime stubs and the Space Exploration mod loader
- `se_data.lua` — data tables (resources, zone types, biome tags, star/planet name pools)
- `se_k2.lua` — optional Krastorio2 support (gated by `SE_ENABLE_K2=1`)
- `bin_pack.lua` / `bin_unpack.lua` — compact binary serialization of seed summaries
- `det_pairs.lua` — deterministic `pairs()` iteration for reproducible generation
- `bit32_extra.lua`, `json.lua`, `struct.lua`, `base64.lua`, `serpent.lua`, `factorio-util.lua` — utilities

## CLI tools

```sh
# Generate a chunk of seeds (chunk number from command line):
runner/bin/lua generator/generate.lua 0

# Unpack a binary universe file to JSON:
runner/bin/lua generator/unpack.lua runner/output/universe-0000.bin
```

## Dependencies

Requires the Space Exploration mod zip at `runner/mods/space-exploration_0.7.57.zip`
(or set `FACTORIO_HOME` to a Factorio install with the mod). Native Lua modules
(`rng`, `zip`, `env`, `curl`, `struct`) are compiled into the interpreter at
`runner/bin/lua`.
