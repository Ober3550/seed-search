# sa-probe — live-game oracle for the Space Age voronoi/terrace ports

Probes Factorio 2.0.77 (`/Applications/factorio.app`) with `calculate_tile_properties`
to pin and regression-test the `noise.zig` `voronoi_*`/`terrace` ops bit-exactly.

## How it works

The game only evaluates *registered* noise-expression names (raw strings in
`property_expression_names` are ignored with a warning; plain numbers are
special-cased). So `gen_probe_mod.py` registers one `noise-expression` prototype
per op config (grid/jitter/metric/seed1/output), and `probe_runs.py` maps up to
six of them onto the engine property slots (`aux`/`moisture`/...) of a Nauvis
map created from `map-gen-settings`, then reads every slot over a tile grid.

```sh
python3 gen_probe_mod.py          # regenerates mods/sa-probe/data.lua
python3 probe_runs.py --run N --grid "x0:x1:y0:y1:step" --out out/runN.jsonl
python3 check4.py <tag> <kind>    # compare a config vs the verified model
```

Configs `a`..`i` cover: euclidean/manhattan/chebyshev/minkowski3 × jitter
0/0.25/0.35/0.5/0.8/1.0 × grids 10/16/24/32/64 × numeric + crc32(string) seeds
(`hxprobe`, `aquilo-cracks`, `fulgora_cells`). `x1/x2.jsonl` hold the exact
planet corners (manhattan/chebyshev jitter 1, minkowski3 0.8, euclidean-1-name).

## What was pinned (2026-09-02)

- Per-cell point hash (ctor disasm `0x10226c098`): raw row/col coordinate →
  `mix(v) = rounds(v*0x1001 + 0x7ed55d16)` with the row axis `ror16`'d first;
  `m = seed ^ (hy>>16) ^ (hx>>16) ^ hy ^ hx`; per-use salts
  `0x7ed55d16/0x7ed56d17/0x7ed57d18` (step 0x1001 — **not** +1/+2) each through
  `rounds(4097*m + salt)` then `h ^ h>>16 ^ 0xb55a4f09`.
  Two easy traps: (1) `mix()` folds, so call it on the raw coordinate; (2)
  `ror16(-1) == -1`, so cells (−1,−1)/(0,0) and (−1,0)/(0,−1) legitimately share
  ids — that's the E1/E2 diagonal-identity pattern, not a bug.
- Distances (f32, engine op order): sample fraction `f32(x/grid) - cell`;
  per point `dx = (px_rel + celloff) - frac`; euclidean `sqrt(dx²+dy²)`,
  manhattan `|dx|+|dy|`, chebyshev `max`, minkowski3
  `exp2f(log2f(s)·0.33333334)` with the **engine's fast** `Math::log2`
  (`0x1025eac10`) and `Math::exp2f` (`0x1025ea988`, bit-level approx) — not libm.
- Outputs: A=d0, B=d1−d0, D=winner cell id, C=pyramid = min over the other
  window points of the distance to the perpendicular bisector of (winner, p).
- Window: sample's floor-cell ± 1 (9 points) for every metric/jitter the SA
  planets use (confirmed empirically; the ctor ring-2 list only covers region
  edges). Minkowski3 pyramid unsupported (game throws).
- Seed: `seed0 + crc32(seed1name)` (mod 2^32) for string seeds.

The game vectors are embedded in the `noise.zig` unit tests, so `zig build
test` in `surface_generator/` is the regression gate without needing a live
game.
