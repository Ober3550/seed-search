# Autoplace & Collision System

How Factorio decides where to place resources, decoratives, and enemies.

## Autoplace Specification

Each prototype (EntityPrototype, DecorativePrototype, TilePrototype) can have an
`AutoplaceSpecification` that defines:

```
AutoplaceSpecification {
    probability_expression: NamedNoiseExpression   → P(x, y) ∈ [0, 1]
    richness_expression:   NamedNoiseExpression     → richness multiplier
    peaks:                 AutoplacePeak[]           → probability/richness curve mapping
    placement_density:     float                     → attempts per chunk region
    tile_restriction:      TileID[]                  → allowed tile types (optional)
}
```

### Peaks

Peaks map noise values to probability/richness curves:

```
AutoplacePeak {
    influence:  float    → noise value for peak center
    richness:   float    → base richness at peak
    width:      float    → peak width (probability spread)
    // Derived:
    //   probability = exp(-((noise - influence)² / (2 * width²)))
    //   richness = richness * probability
}
```

Multiple peaks allow resources to appear in multiple bands
(e.g., iron at both low and high elevations).

## Compilation

```
AutoplaceSpecification (data stage, per prototype)
    │
    ▼
CompiledMapGenSettings::prepareAutoplacers<EntityPrototype>
    │  - Compiles probability_expression → NoiseProgram
    │  - Compiles richness_expression → NoiseProgram
    │  - Extracts peaks, placement_density
    │  - Sorts by priority
    ▼
CompiledAutoplacer<EntityPrototype>
    │  - Ready to evaluate per (x, y)
    │
    ▼
EntityMapGenerationTask
    │  - Iterates over chunk tiles
    │  - Evaluates probability noise
    │  - RNG roll: if pass → evaluate richness → place entity
    │  - Checks collision_mask against tile
    └── Result: Entity placed or skipped
```

## Key Addresses (arm64)

| Function | Address |
|---|---|
| `CompiledMapGenSettings::prepareAutoplacers<EntityPrototype>` | `0x10014b9a40` |
| `CompiledMapGenSettings::prepareAutoplacers<DecorativePrototype>` | `0x10014b908c` |
| `CompiledMapGenSettings::prepareAutoplacers<TilePrototype>` | `0x10014ba3f4` |
| `CompiledMapGenSettings::getRegisterOwner<EntityPrototype>` | `0x10014bc1c8` |

## Collision Mask / Tile Restriction

Every EntityPrototype has a `collision_mask` that determines which tile types
block placement. The check happens AFTER autoplace evaluation:

```c++
// Pseudocode from RE
bool EntityMapGenerationTask::tryPlaceEntity(x, y, compiled_autoplacer) {
    // Step 1: Evaluate noise — independent of tile
    float prob = compiled_autoplacer.probability_program.evaluate(x, y, seed);
    if (prob < threshold) return false;

    // Step 2: RNG roll
    float roll = rng.float();
    if (roll > prob) return false;

    // Step 3: Check collision mask against actual tile
    TilePrototype* tile = surface.getTile(x, y);
    if (entity_prototype.collision_mask.collidesWith(tile->collision_mask))
        return false;  // Can't place on this tile

    // Step 4: Place with richness
    float richness_base = compiled_autoplacer.richness_program.evaluate(x, y, seed);
    uint32_t amount = computeAmount(richness_base, peaks);
    surface.createEntity(entity_prototype, x, y, amount);
    return true;
}
```

### Default Collision Masks

Vanilla Factorio restricts resources to non-water tiles:

| Resource | Blocked By |
|---|---|
| iron-ore, copper-ore, coal, stone | water, deepwater, water-green, deepwater-green |
| uranium-ore | water, deepwater, water-green, deepwater-green |
| crude-oil | (nothing — can appear on water) |

### Key Functions

| Function | Role |
|---|---|
| `PrototypeFilterHelpers::make_collision_mask<EntityPrototype>` | Builds entity collision mask from prototype |
| `PrototypeFilterHelpers::make_collision_mask<TilePrototype>` | Builds tile collision mask |
| `MapGenerator::clearEntitiesForTile` (`0x10014fba18`) | Removes entities when tile changes |
| `MapGenerator::clearEntitiesAndSetTile` (`0x10002468fc`) | Sets tile + clears conflicting entities |
| `CollisionSquareDetectionLogic` | Entity-tile collision detection |

## Implications for Ore-First Generation

Since the collision mask check is the LAST step, we can:

1. **Evaluate autoplace probability** for all resources at all positions
   → This is pure noise evaluation, no terrain needed
2. **Record candidates** where probability passes threshold
3. **Generate minimal terrain** only for chunks with candidates
4. **Filter** candidates against collision masks → final ore positions
5. **Richness** is also noise-based, evaluated only for placed resources
