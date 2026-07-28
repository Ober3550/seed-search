# gpu_compute — WebGPU terrain acceleration (wgpu-native)

Compute-shader path for terrain generation. One WGSL kernel runs on **Metal**
(macOS), **Vulkan** (Linux), and **D3D12** (Windows) via
[wgpu-native](https://github.com/gfx-rs/wgpu-native), so we don't rewrite the
kernel per platform. See the `gpu-webgpu-direction` project memory for the why.

## Status: Phase 3 complete — full terrain render on GPU (~18x vs 10-core CPU)
The entire pipeline (elevation + temp/moisture/aux + biome classify) runs in one
GPU dispatch. 1024² render: GPU 215 ms vs CPU 10-thread 3970 ms (**18.5x**) /
1-thread 28.9 s (**134x**), with 99.997% biome agreement.

## Setup & run
```sh
cd gpu_compute
./fetch-wgpu.sh                        # download the pinned wgpu-native prebuilt (gitignored)
zig build run                         # Phase 0: add-arrays toolchain proof
zig build conformance                 # Phase 1: CPU-vs-GPU multioctave noise diff
zig build elevation                   # Phase 2: full elevation + water-mask agreement
zig build tma                         # Phase 3a: temperature/moisture/aux diff
zig build biome                       # Phase 3b: biome-index agreement (100%)
zig build render -Doptimize=ReleaseFast   # chained render -> render-out.bmp + benchmark
```

## Layout
- `src/main.zig`                 — Phase 0 host program (add-arrays)
- `src/noise_conformance.zig`    — Phase 1 CPU-vs-GPU multioctave diff harness
- `src/elevation_conformance.zig`— Phase 2 full elevation + water-mask harness
- `src/wgpu.zig`                 — `@cImport` wrapper + `Context` (device/pipeline/buffer/readback)
- `src/shaders/`                 — WGSL kernels (`add`, `noise`, `elevation`; `@embedFile`)
- `vendor/<triple>/`             — wgpu-native headers + libs (**gitignored**; run fetch-wgpu.sh)
- `build.zig`                    — vendor triple per target; links dylib + rpath; imports the CPU oracle

The CPU oracle is `surface_generator/src/root.zig` (re-exports `noise`,
`terrain`, …), imported directly so the tests call the exact same code the rest
of the pipeline uses.

## Pinned version
**wgpu-native v29.0.1.1**. The C API (StringView, callback-info async) shifts
between releases, so `src/wgpu.zig` uses `@cImport` to stay in sync with
whatever `fetch-wgpu.sh` pulled. To bump: change `WGPU_VERSION` in
`fetch-wgpu.sh`, re-fetch, and fix any compile breaks in `main.zig`.

## Roadmap
- **Phase 0** ✅ add-arrays proof.
- **Phase 1** ✅ multioctave noise primitive on GPU + CPU-vs-GPU conformance
  (max abs diff ~1e-7). This is the guard that keeps the WGSL kernel and the Zig
  CPU oracle from drifting.
- **Phase 2** ✅ full `Elevation.at` (nauvis_hills/plateaus/bridges/macro/detail
  via 7 single generators) + water threshold. Water-mask agreement 100.000%
  (1/262k shoreline tile). starting_lake skipped when `slake_n==0` (SE moons).
- **Phase 3** ✅ temp/moisture/aux (per-octave `quick_multioctave`, 27 gens) +
  biome classify (156 biomes + 4 water tiles, 158 gens, 100% index agreement in
  isolation) + chained render (`render.wgsl`, 192 gens, one dispatch) + benchmark.
- **Phase 4 (next)** — per-cell center-outward dispatch for progressive display,
  and wire in as the GUI "fast preview" renderer. **CPU path stays the oracle**
  — chained f64→f32 drift flips a handful of biome-edge tiles (~30/1M), so GPU
  is preview-only.

Tile correction is out of scope (see `biome-accuracy-ceiling` memory).
```
