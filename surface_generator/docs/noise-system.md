# Noise Expression System

Factorio uses a compiled noise expression VM for all procedural generation:
terrain, resources, cliffs, decoratives — everything is a noise expression.

## Architecture

```
NoiseExpression (abstract)
├── ConstantExpression      — literal float value
├── Number                  — number wrapper
├── String                  — string literal
├── Variable                — named reference (e.g., "x", "y", "distance")
├── LiteralMapPosition      — position-as-value
├── UnaryExpression<Op>     — single-input operation
├── BinaryExpression<Op>    — two-input operation
└── ComplexExpression<Operation, Inputs, Params, Results>
                            — multi-input operation with compile-time arg counts
```

## Compilation Pipeline

```
NoiseExpression tree
    │
    ▼
NoiseProgramBuilder::compileExpression(expr)
    │  - Walks expression tree
    │  - Allocates NoiseRegisters (float slots)
    │  - Resolves named variables to register indices
    │  - Generates flat operation list
    │  - Tracks register lifetimes
    ▼
NoiseProgram (serializable)
    │  - Flat array of operations
    │  - Each operation: opcode + register indices + constants
    │
    ▼
NoiseProgram::evaluate(x, y, seed) → float
    └─ Runs the VM: execute ops in order, store results in registers
```

## Noise Operations

Template: `ComplexExpression<Operation, InputRegisters, ConstantParams, OutputRegisters>`

| Operation                             | Inputs | Consts | Outputs | Description                                     |
| ------------------------------------- | ------ | ------ | ------- | ----------------------------------------------- |
| `BasisNoise`                          | 2      | 6      | 0       | Perlin/simplex base noise: seed, scale, octaves |
| `MultioctaveNoise`                    | 2      | 8      | 0       | Fractal octave sum with persistence             |
| `VariablePersistenceMultioctaveNoise` | 3      | 7      | 0       | Per-octave persistence control                  |
| `QuickMultioctaveNoise`               | 2      | 10     | 0       | Optimized multi-octave                          |
| `VoronoiNoise`                        | 2      | 5      | 0       | Cellular/Worley noise                           |
| `SpotNoise`                           | 2      | 11     | 4       | Random spot/point noise with density            |
| `DistanceFromNearestPoint`            | 2      | 2      | 0       | Distance field from nearest point in set        |
| `RandomPenalty`                       | 3      | 2      | 0       | Random suppression of values                    |
| `Ridge`                               | 3      | 0      | 0       | Ridge noise (abs + invert)                      |
| `Terrace`                             | 2      | 2      | 0       | Quantize/terrace into steps                     |
| `Clamp`                               | —      | —      | —       | Clamp to range                                  |
| `GridOperation`                       | —      | —      | —       | Grid cell operations                            |
| `If`                                  | 3      | 0      | 0       | Conditional: if(a, b, c) → a >= 0 ? b : c       |
| `Multisampling`                       | —      | —      | —       | Jitter/supersample                              |
| `OffsetPoints`                        | 0      | 2      | 0       | Offset point set                                |

### Unary Operations (math functions)

`UnaryExpression<UnaryOperation<Type, FuncPtr, Flags>>`

| Operation | Function              |
| --------- | --------------------- |
| `Type 1`  | `unaryMinus` (negate) |
| `Type 15` | `bitwiseNot`          |
| `Type 16` | `abs`                 |
| `Type 18` | `ceil`                |
| `Type 19` | `cos`                 |
| `Type 20` | `floor`               |
| `Type 21` | `log2`                |

## Key Addresses (arm64)

| Function                                               | Address         |
| ------------------------------------------------------ | --------------- |
| `NoiseProgramBuilder::compileExpression`               | `0x10015e5b9c`  |
| `NoiseProgramBuilder::getCompiledExpression`           | `0x10015e5ee4`  |
| `NoiseProgramBuilder::computeChecksum`                 | `0x10015e5b2c`  |
| `NoiseProgramBuilder::requestRegister`                 | `0x10015e5cc4`  |
| `NoiseProgramBuilder::allocateFloatRegister`           | `0x10015e5f58`  |
| `NoiseProgramBuilder::getOperation`                    | `0x10015e5ed8`  |
| `ComplexExpression<BasisNoise, 2, 6, 0>` ctor          | `0x10015e953c`  |
| `ComplexExpression<VoronoiNoise, 2, 5, 0>` ctor        | `0x10015eca60`  |
| `ComplexExpression<MultioctaveNoise, 2, 8, 0>`         | (symbol exists) |
| `ComplexExpression<SpotNoise, 2, 11, 4>` ctor          | `0x10016104d4`  |
| `ComplexExpression<DistanceFromNearestPoint, 2, 2, 0>` | (symbol exists) |
| `ComplexExpression<RandomPenalty, 3, 2, 0>`            | (symbol exists) |
| `ComplexExpression<Ridge, 3, 0, 0>`                    | (symbol exists) |
| `ComplexExpression<Terrace, 2, 2, 0>`                  | (symbol exists) |

## Named Noise Expressions (from Factorio data stage)

These are the standard noise expressions that control terrain:

| Name                            | Purpose                         |
| ------------------------------- | ------------------------------- |
| `elevation`                     | Base terrain height             |
| `elevation_island`              | Island/continent shape          |
| `elevation_lakes`               | Lake depressions                |
| `cliff_elevation`               | Cliff placement height          |
| `cliff_elevation_0`             | Cliff elevation variant         |
| `cliff_elevation_interval`      | Cliff spacing                   |
| `cliffiness`                    | Cliff probability               |
| `starting_area`                 | Spawn clearing zone             |
| `control:temperature:bias`      | Temperature autoplace bias      |
| `control:temperature:frequency` | Temperature autoplace frequency |
| `control:moisture:bias`         | Moisture autoplace bias         |
| `control:moisture:frequency`    | Moisture autoplace frequency    |

Resource autoplace expressions are defined per-resource in the data stage
(e.g., `iron-ore` has `probability_expression` and `richness_expression`).

## Space Age 2.0 additions (RE'd 2026-09-02, factorio-arm64 2.0.77)

The 2.0 planet data (fulgora/gleba/vulcanus/aquilo) calls four voronoi
functions + terrace that 1.1's engine didn't have. All symbols are intact in
the arm64 slice (`ghidra/export/voronoi.c`, `ghidra/export/terrace.c`).

### VoronoiNoise (`NoiseOperations::VoronoiNoise`)

Compiled as `ComplexExpression<VoronoiNoise, 2, 5, 0>` (2 input registers =
x-vector + y-vector; object also carries output registers). Object layout:

| offset | field |
| ------ | ----- |
| +0x08..+0x14 | 4 OUTPUT register indexes (nearest d0, d1-d0, edge/pyramid, cell id) |
| +0x18, +0x1c | input registers: x-coord vector, y-coord vector |
| +0x20 | u32 seed const (hash of `seed1`) |
| +0x24 | u16 grid_size |
| +0x26 | u8 distance_type |
| +0x28 | f32 jitter ∈ [0,1] |

Per sample (vectorized over a row of positions):

1. `cell = floor(x/grid_size), floor(y/grid_size)` (float→int conversion with
   ±2^31 saturation).
2. `VoronoiPoints(cell, ring)` builds the jittered cell-point neighborhood
   (ring 1 or 2 wide depending on jitter/type). Each point = {px, py, id} in
   cell-relative grid units, where
   `px,py = u32(hash)/2^32 · jitter + (1-jitter)/2` and
   `id = u32(hash)/2^32` — see the hash below.
3. For each of the 9/25 candidates evaluate distance in the chosen metric:
   chebyshev `max|dx|,|dy|`, manhattan `|dx|+|dy|`, euclidean `√(dx²+dy²)`,
   minkowski3 `∛(dx³+dy³)` (`parseDistanceType`: chebyshev=0 manhattan=1
   euclidean=2 minkowski3=3).
4. Track nearest d0 and second-nearest d1.
5. Writes up to 4 outputs:
   - A (+0x08): d0
   - B (+0x0c): d1 - d0
   - C (+0x10): distance to the bisector between the two nearest points
     (the "pyramid"); not defined for minkowski3
   - D (+0x14): the winning point's `id`

`NoiseExpressions::VoronoiNoiseWrapper` (VoronoiType 0..3) exposes ONE output
as a noise function value: type 0 = `voronoi_spot_noise` (output A), type 1 =
`voronoi_facet_noise` (B), type 2 = `voronoi_pyramid_noise` (C; throws
"Voronoi pyramid noise with Minkowski3 distance is not supported"), type 3 =
`voronoi_cell_id` (D). Key factories at 0x102261ad8/0x102261ef4/0x102261f44/
0x102261f94 (the NativeNoiseFunctions registry table lives at ~0x102d57c40,
VoronoiType entries are indices 10-13).

**Per-cell point hash** (`VoronoiPoints::VoronoiPoints` @ 0x10226c098): 32-bit
mixing with a per-use salt on top of `cell → (cx*0x1001+0x7ed55d16)`, then two
mix rounds of `x = ((x ^ x>>0x13 ^ 0xc761c23c) * 0x21)` /
`x = ((x + 0xe9f8cc1d ^ (x + 0x165667b1) << 9) * 9 + 0xfd7046c5)`, combined as
`seed ^ (hcy>>16) ^ (hcx>>16) ^ hcy ^ hcx`, then re-mixed with salts
0x7ed55d16/+1/+2 for x-jitter / y-jitter / id. Exact u32 sequence is still to
be pinned from the decompile's 64-bit register lowering before porting.

### Terrace (`NoiseOperations::Terrace`, `ComplexExpression<Terrace,2,2,0>`)

Object: inputs at +0x08/+0x0c, output +0x10, offset f32 at +0x14, step f32 at
+0x18. Per sample with a second input `blend`:
`q=(v-offset)/step; qf=(int)q; frac=q-qf; t = blend<frac ? (frac-blend)/(1-blend) : 0; out = offset+step*(qf+t)`.
blend=0 → identity; blend=1 → pure quantization to `step` boundaries
(used to make "terraced" height fields). `Terrace::run` @ 0x1015f1450.
