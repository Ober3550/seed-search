# Factorio Surface Generation — Architecture

Reverse-engineered from Factorio (Space Age/2.0) arm64 binary via Ghidra.

## Generation Pipeline

```
ChunkGenerationRequest
  │
  ├─ 1. AsyncBasicTilesTask         → Terrain tiles (water, grass, desert, etc.)
  │     └─ Uses: elevation noise expression → tile type lookup
  │
  ├─ 2. EntityMapGenerationTask     → Resources & enemies
  │     ├─ CompiledAutoplacer<EntityPrototype>   → ore probability + richness
  │     ├─ CompiledAutoplacer<DecorativePrototype> → trees, rocks, decoratives
  │     └─ CliffGenerator                      → cliff placement
  │
  ├─ 3. TileCorrectionMapGenerationTask → Neighbor tile corrections
  │
  └─ 4. VariationsMapGeneratorTask   → Tile variation application

RegenerationTaskWrapper handles re-runs for entity/decorative regeneration.
```

## Ore Placement is Independent of Terrain

The autoplace system evaluates noise expressions per (x, y, seed) *before* checking
tile validity. The collision mask filter (`collision_mask` per EntityPrototype) is
applied as a post-check against the generated tile type.

This means we can compute ore placement without generating terrain first:
1. Evaluate autoplace probability noise for all positions
2. Record candidates that pass the probability threshold
3. Only generate terrain (elevation → tile type) for chunks with candidates
4. Filter candidates by collision mask

## Key Classes & Addresses (arm64)

### Map Generation Pipeline

| Function                                                                      | Address        | Role                                 |
| ----------------------------------------------------------------------------- | -------------- | ------------------------------------ |
| `Surface::requestToGenerateChunk`                                             | `0x1000639014` | Entry point                          |
| `MapGenerationTask::canStartTask`                                             | `0x10014f3068` | Scheduler gate                       |
| `AsyncBasicTilesTask` ctor                                                    | `0x1002229684` | Terrain tile generation              |
| `EntityMapGenerationTask` ctor                                                | `0x10014caaf0` | Entity + resource + cliff generation |
| `EntityMapGenerationTask::applyCliffs`                                        | `0x10014cc484` | Cliff placement                      |
| `RegenerationTaskWrapper` ctor                                                | `0x100222a720` | Re-generation wrapper                |
| `MapGenerator::regenerateInternal`                                            | `0x10014f9650` | Core regeneration dispatch           |
| `MapGenerator::regenerateEntity`                                              | `0x10014f95f0` | Single-prototype entity regeneration |
| `MapGenerator::regenerateDecorative`                                          | `0x10014fa360` | Decorative regeneration              |
| `MapGenerationManager::AsyncHelper::generateAllOfStatus<AsyncBasicTilesTask>` | `0x10014f1690` | Dispatches basic tile tasks          |
| `MapGenerationManager::AsyncHelper::generateAllOfStatus<AsyncEntityTask>`     | `0x10014f2918` | Dispatches entity tasks              |

### Cliff Generation

| Function                            | Address        |
| ----------------------------------- | -------------- |
| `CliffGenerator::crossingsForChunk` | `0x10014b5650` |
| `CliffGenerator::crossesCliff`      | `0x10014b5598` |
| `CliffGenerator::getNoiseCacheSize` | `0x10014b5624` |

### Autoplace System

| Function                                                          | Address        |
| ----------------------------------------------------------------- | -------------- |
| `CompiledMapGenSettings::prepareAutoplacers<EntityPrototype>`     | `0x10014b9a40` |
| `CompiledMapGenSettings::prepareAutoplacers<TilePrototype>`       | `0x10014ba3f4` |
| `CompiledMapGenSettings::prepareAutoplacers<DecorativePrototype>` | `0x10014b908c` |
| `CompiledMapGenSettings::getRegisterOwner<EntityPrototype>`       | `0x10014bc1c8` |

### Noise System

| Function                                     | Address        |
| -------------------------------------------- | -------------- |
| `NoiseProgramBuilder::compileExpression`     | `0x10015e5b9c` |
| `NoiseProgramBuilder::getCompiledExpression` | `0x10015e5ee4` |
| `NoiseProgramBuilder::computeChecksum`       | `0x10015e5b2c` |
| `NoiseProgramBuilder::requestRegister`       | `0x10015e5cc4` |
| `NoiseProgramBuilder::getOperation`          | `0x10015e5ed8` |

### Collision / Tile Validation

| Function                                                       | Address               |
| -------------------------------------------------------------- | --------------------- |
| `MapGenerator::clearEntitiesForTile`                           | `0x10014fba18`        |
| `MapGenerator::clearEntitiesAndSetTile`                        | `0x10002468fc`        |
| `CollisionSquareDetectionLogic`                                | (multiple addresses)  |
| `PrototypeFilterHelpers::make_collision_mask<EntityPrototype>` | (symbol, address TBD) |
| `PrototypeFilterHelpers::make_collision_mask<TilePrototype>`   | (symbol, address TBD) |

## Source Files (from debug paths in binary)

```
src/Map/
├── MapGenerator.cpp
├── MapGeneratorGui.cpp
├── CompiledMapGenSettings.cpp
├── MapGenerationTask.cpp
├── MapGenerationHelper.cpp
├── MapGenerationManager.cpp
├── BasicTilesMapGenerationTask.cpp
├── TileCorrectionMapGenerationTask.cpp
├── EntityMapGenerationTask.cpp
├── VariationsMapGeneratorTask.cpp
└── CliffGenerator.cpp

src/Noise/
├── Expression/          (NoiseExpression, ComplexExpression, ConstantExpression, etc.)
└── Operation/
    ├── BasisNoise.cpp
    ├── MultioctaveNoise.cpp
    ├── VariablePersistenceMultioctaveNoise.cpp
    ├── VoronoiNoise.cpp
    ├── SpotNoise.cpp
    ├── SpotNoiseCache.cpp
    ├── DistanceFromNearestPoint.cpp
    ├── RandomPenalty.cpp
    ├── Ridge.cpp
    ├── Terrace.cpp
    ├── Clamp.cpp
    ├── GridOperation.cpp
    ├── If.cpp
    └── Multisampling.cpp
```

## Binary Metadata

- **Path**: `/Applications/Factorio.app/Contents/MacOS/factorio`
- **Architecture**: arm64 (Mach-O universal binary, also has x86_64)
- **Size**: 198MB
- **Image base**: `0x100000000`
- **Entry point**: `0x1002EEAC4`
- **Functions analyzed**: 83,263
