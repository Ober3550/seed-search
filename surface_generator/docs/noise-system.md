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

| Operation | Inputs | Consts | Outputs | Description |
|---|---|---|---|---|
| `BasisNoise` | 2 | 6 | 0 | Perlin/simplex base noise: seed, scale, octaves |
| `MultioctaveNoise` | 2 | 8 | 0 | Fractal octave sum with persistence |
| `VariablePersistenceMultioctaveNoise` | 3 | 7 | 0 | Per-octave persistence control |
| `QuickMultioctaveNoise` | 2 | 10 | 0 | Optimized multi-octave |
| `VoronoiNoise` | 2 | 5 | 0 | Cellular/Worley noise |
| `SpotNoise` | 2 | 11 | 4 | Random spot/point noise with density |
| `DistanceFromNearestPoint` | 2 | 2 | 0 | Distance field from nearest point in set |
| `RandomPenalty` | 3 | 2 | 0 | Random suppression of values |
| `Ridge` | 3 | 0 | 0 | Ridge noise (abs + invert) |
| `Terrace` | 2 | 2 | 0 | Quantize/terrace into steps |
| `Clamp` | — | — | — | Clamp to range |
| `GridOperation` | — | — | — | Grid cell operations |
| `If` | 3 | 0 | 0 | Conditional: if(a, b, c) → a >= 0 ? b : c |
| `Multisampling` | — | — | — | Jitter/supersample |
| `OffsetPoints` | 0 | 2 | 0 | Offset point set |

### Unary Operations (math functions)

`UnaryExpression<UnaryOperation<Type, FuncPtr, Flags>>`

| Operation | Function |
|---|---|
| `Type 1` | `unaryMinus` (negate) |
| `Type 15` | `bitwiseNot` |
| `Type 16` | `abs` |
| `Type 18` | `ceil` |
| `Type 19` | `cos` |
| `Type 20` | `floor` |
| `Type 21` | `log2` |

## Key Addresses (arm64)

| Function | Address |
|---|---|
| `NoiseProgramBuilder::compileExpression` | `0x10015e5b9c` |
| `NoiseProgramBuilder::getCompiledExpression` | `0x10015e5ee4` |
| `NoiseProgramBuilder::computeChecksum` | `0x10015e5b2c` |
| `NoiseProgramBuilder::requestRegister` | `0x10015e5cc4` |
| `NoiseProgramBuilder::allocateFloatRegister` | `0x10015e5f58` |
| `NoiseProgramBuilder::getOperation` | `0x10015e5ed8` |
| `ComplexExpression<BasisNoise, 2, 6, 0>` ctor | `0x10015e953c` |
| `ComplexExpression<VoronoiNoise, 2, 5, 0>` ctor | `0x10015eca60` |
| `ComplexExpression<MultioctaveNoise, 2, 8, 0>` | (symbol exists) |
| `ComplexExpression<SpotNoise, 2, 11, 4>` ctor | `0x10016104d4` |
| `ComplexExpression<DistanceFromNearestPoint, 2, 2, 0>` | (symbol exists) |
| `ComplexExpression<RandomPenalty, 3, 2, 0>` | (symbol exists) |
| `ComplexExpression<Ridge, 3, 0, 0>` | (symbol exists) |
| `ComplexExpression<Terrace, 2, 2, 0>` | (symbol exists) |

## Named Noise Expressions (from Factorio data stage)

These are the standard noise expressions that control terrain:

| Name | Purpose |
|---|---|
| `elevation` | Base terrain height |
| `elevation_island` | Island/continent shape |
| `elevation_lakes` | Lake depressions |
| `cliff_elevation` | Cliff placement height |
| `cliff_elevation_0` | Cliff elevation variant |
| `cliff_elevation_interval` | Cliff spacing |
| `cliffiness` | Cliff probability |
| `starting_area` | Spawn clearing zone |
| `control:temperature:bias` | Temperature autoplace bias |
| `control:temperature:frequency` | Temperature autoplace frequency |
| `control:moisture:bias` | Moisture autoplace bias |
| `control:moisture:frequency` | Moisture autoplace frequency |

Resource autoplace expressions are defined per-resource in the data stage
(e.g., `iron-ore` has `probability_expression` and `richness_expression`).
