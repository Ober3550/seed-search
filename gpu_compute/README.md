# gpu_compute — WebGPU terrain acceleration (wgpu-native)

Compute-shader path for terrain generation. One WGSL kernel runs on **Metal**
(macOS), **Vulkan** (Linux), and **D3D12** (Windows) via
[wgpu-native](https://github.com/gfx-rs/wgpu-native), so we don't rewrite the
kernel per platform. See the `gpu-webgpu-direction` project memory for the why.

## Status: Phase 1 (noise primitive ported + conformance-tested)
The multioctave noise primitive runs on the GPU and matches the CPU oracle to
f32 precision (max abs diff ~1e-7 ≈ 1 ULP).

## Setup & run
```sh
cd gpu_compute
./fetch-wgpu.sh          # download the pinned wgpu-native prebuilt (gitignored)
zig build run            # Phase 0: add-arrays toolchain proof
zig build conformance    # Phase 1: CPU-vs-GPU multioctave noise diff
```
Expected: `✅ Phase 0 OK ...` and `✅ Phase 1 conformance PASS (max abs diff ~1e-7)`.

## Layout
- `src/main.zig`             — Phase 0 host program (add-arrays)
- `src/noise_conformance.zig`— Phase 1 CPU-vs-GPU multioctave diff harness
- `src/wgpu.zig`             — `@cImport` wrapper + `Context` (device/pipeline/buffer/readback helpers)
- `src/shaders/`             — WGSL kernels (`add.wgsl`, `noise.wgsl`; embedded via `@embedFile`)
- `vendor/<triple>/`         — wgpu-native headers + libs (**gitignored**; run fetch-wgpu.sh)
- `build.zig`                — vendor triple per target; links dylib + rpath; imports the CPU `noise` oracle

The CPU noise oracle is `surface_generator/src/noise.zig`, imported directly so
the conformance test calls the exact same code the rest of the pipeline uses.

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
- **Phase 2** — compose full `Elevation.at` (nauvis_hills/macro/detail/
  starting_lake + water threshold), then temp/moisture/aux + biome classify →
  biome-index buffer → render. Extend the conformance harness to each term.
- **Phase 3** — benchmark vs CPU `std.Thread.Pool`; wire in as the GUI "fast
  preview" renderer. **CPU path stays the bit-exact oracle** — GPU transcendentals
  (pow/sqrt) won't match last-bit, so GPU is preview-only.

Tile correction is out of scope (see `biome-accuracy-ceiling` memory).
```
