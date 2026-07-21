# Test Data

Captured surface generation output from the real Factorio game.

## Purpose

Each subdirectory contains a "ground truth" dataset for a specific
seed and map gen setting combination. The Zig surface generator is
considered correct when it produces bit-identical output to these.

## Format

```
test_data/
├── seed_341_default/
│   ├── metadata.json       # Seed, map gen settings, Factorio version
│   ├── chunk_0_0.bin       # Serialized chunk at (0, 0)
│   ├── chunk_0_1.bin       # Serialized chunk at (0, 1)
│   └── ...
└── seed_12345_rich/
    ├── metadata.json
    └── ...
```

## Capture Method

In Factorio, use the console (~) to export chunk data:

```lua
/c local surface = game.player.surface
local chunk = surface.get_chunk(0, 0)
-- Export tiles, resources, entities to file
game.write_file("chunk_0_0.json", serpent.block({
  tiles = ...,
  resources = ...,
}))
```

Or use a mod that serializes chunk data on generation.

## Validation

```bash
# Compare generated chunk against captured ground truth
surfacegen verify --against test_data/seed_341_default --chunk 0,0
```
