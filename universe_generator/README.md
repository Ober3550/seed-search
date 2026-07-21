# Universe Generator

Replicates Factorio: Space Exploration's universe generation algorithm. This module generates star systems, planets, moons, asteroid belts, and asteroid fields for a given seed — including zone resource assignments, gravity wells, and resource yield estimates.

## Status

The Zig implementation under `generator/zig/` (gen.zig, main.zig, data.zig) is a working port from SE's Lua source. It matches the Lua output for seed 341 (the reference seed).

## Key Components

- **RNG** — Factorio's triple-LFSR random number generator
- **Planet/Moon assignment** — Shuffle-based distribution of bodies to stars
- **Tag computation** — Temperature, water, moisture, trees, aux, cliff, enemy tags
- **Primary resource claiming** — Quota-based algorithm with strong claims and bias ordering
- **Resource scoring** — FSR (frequency × size × richness) per resource
- **Gravity wells** — Star and planet gravity well computation for delta-v
- **Yield estimation** — Area × resource score × land fraction → millions of ore

## Usage

```bash
cd universe_generator
zig build run -- 341    # Generate universe for seed 341
```

## Verification

Cross-reference output against SE's Lua universe generator (included in the SE mod).
The reference seed 341 serves as the ground-truth validation case.
