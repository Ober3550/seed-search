# Surface Generator (Factorio Surface Generation)

## Goal

**Quickly generate Factorio surfaces with ore placement as the primary input.**

Instead of the standard approach where terrain drives ore placement, this project
flips the pipeline: specify what ores you want, where you want them, and generate
a valid Factorio surface (Nauvis-like) around those constraints.

This enables:
- **Rapid iteration** — generate candidate surfaces for SE planet mining outposts
  without the full game
- **Seed search** — find seeds that produce desired ore patterns on specific planets
- **Deterministic replay** — given a seed and planet parameters, reproduce the
  exact surface layout
- **Verification** — compare generated output against real Factorio saves to
  confirm algorithm correctness

## Reverse Engineering Approach

1. **Binary analysis** — Load `factorio` (Mach-O arm64/x86_64) into Ghidra
   - Target symbols: `MapGenSettings`, `autoplace`, `noise`, `chunk_generate`
   - Identify the RNG seeding chain from map exchange string → per-chunk state
2. **Algorithm extraction** — Reimplement Factorio's noise layers and autoplace
   logic in Zig
3. **Validation** — Capture real chunk data from the game (via Lua commands or
   save parsing) and compare byte-for-byte with generated output

## Test Generation (Ground Truth)

A captured surface from the real game will serve as the validation target:
- **Method**: Use Factorio's `/c` console command or a mod to export chunk data
  at specific coordinates
- **Format**: Serialized tile/entity data for a 32×32 chunk region at a known
  seed and map gen settings
- **Saved in**: `surface_generator/test_data/` as binary dumps + metadata JSON

The Zig implementation is considered **correct** when it produces bit-identical
output to the captured test chunks.

## Implementation Plan

1. [ ] Load Factorio binary into Ghidra, identify map generation pipeline
2. [ ] Extract and document the noise expression tree (noise layers)
3. [ ] Extract autoplace probability functions per resource
4. [ ] Implement RNG + noise in Zig
5. [ ] Implement tile generation (terrain, water)
6. [ ] Implement resource autoplace
7. [ ] Validate against captured test data
8. [ ] Build CLI tool: `surfacegen --seed N --preset default --ores iron-ore,copper-ore`

## Dependencies

- [Zig](https://ziglang.org/) 0.16.x
- [Ghidra](https://ghidra-sre.org/) 12.1+ (for reverse engineering)
- Factorio (for capturing test data)

## Related Modules

- `../universe_generator/` — SE universe-level generation (star systems, planet assignment)
- `../generator/zig/` — Existing SE seed finder (uses gen.zig for universe + zone resources)
