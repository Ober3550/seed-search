# gpu_compute — WebGPU terrain acceleration (wgpu-native)

Compute-shader path for terrain generation. One WGSL kernel runs on **Metal**
(macOS), **Vulkan** (Linux), and **D3D12** (Windows) via
[wgpu-native](https://github.com/gfx-rs/wgpu-native), so we don't rewrite the
kernel per platform. See the `gpu-webgpu-direction` project memory for the why.

## Status: Phase 2 (full elevation + water threshold on GPU)
The complete `Elevation.at` composition runs on the GPU. Water-mask agreement
vs the CPU oracle is 100.000% (1 shoreline tile of 262k, at elevation ~2e-4).

## Setup & run
```sh
cd gpu_compute
./fetch-wgpu.sh          # download the pinned wgpu-native prebuilt (gitignored)
zig build run            # Phase 0: add-arrays toolchain proof
zig build conformance    # Phase 1: CPU-vs-GPU multioctave noise diff
zig build elevation      # Phase 2: full elevation + water-mask agreement
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
- **Phase 3** — temp/moisture/aux (uses per-octave `quick_multioctave` → upload
  N generator sets) + biome classify → biome-index buffer → render. Then
  benchmark vs CPU `std.Thread.Pool` and wire in as the GUI "fast preview".
  **CPU path stays the oracle** — the f64→f32 composition drift (~1e-4) means a
  rare shoreline/biome-edge tile flips, so GPU is preview-only.

Tile correction is out of scope (see `biome-accuracy-ceiling` memory).
```
