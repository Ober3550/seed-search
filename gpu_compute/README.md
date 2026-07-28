# gpu_compute — WebGPU terrain acceleration (wgpu-native)

Compute-shader path for terrain generation. One WGSL kernel runs on **Metal**
(macOS), **Vulkan** (Linux), and **D3D12** (Windows) via
[wgpu-native](https://github.com/gfx-rs/wgpu-native), so we don't rewrite the
kernel per platform. See the `gpu-webgpu-direction` project memory for the why.

## Status: Phase 0 (toolchain proof)
`src/main.zig` runs `src/shaders/add.wgsl` headless — uploads two f32 arrays,
computes `out[i] = a[i] + b[i]` on the GPU, reads back, and verifies. This
proves device → pipeline → dispatch → readback before porting real noise.

## Setup & run
```sh
cd gpu_compute
./fetch-wgpu.sh          # download the pinned wgpu-native prebuilt (gitignored)
zig build run            # builds + runs Phase 0
```
Expected: `✅ Phase 0 OK — 1048576 elements, out[i] == a[i]+b[i] ...`

## Layout
- `src/main.zig`     — Phase 0 host program (adapter/device/pipeline/dispatch)
- `src/wgpu.zig`     — `@cImport` wrapper over webgpu.h/wgpu.h + StringView helpers
- `src/shaders/`     — WGSL kernels (embedded via `@embedFile`)
- `vendor/<triple>/` — wgpu-native headers + libs (**gitignored**; run fetch-wgpu.sh)
- `build.zig`        — picks the vendor triple from the target; links the dylib + rpath

## Pinned version
**wgpu-native v29.0.1.1**. The C API (StringView, callback-info async) shifts
between releases, so `src/wgpu.zig` uses `@cImport` to stay in sync with
whatever `fetch-wgpu.sh` pulled. To bump: change `WGPU_VERSION` in
`fetch-wgpu.sh`, re-fetch, and fix any compile breaks in `main.zig`.

## Roadmap
- **Phase 0** ✅ add-arrays proof (this).
- **Phase 1** — port elevation/water noise; CPU-vs-GPU max-abs-diff conformance
  test (keeps the WGSL kernel and the Zig CPU oracle from drifting).
- **Phase 2** — temp/moisture/aux + biome classify → biome-index buffer → render.
- **Phase 3** — benchmark vs CPU `std.Thread.Pool`; wire in as the GUI "fast
  preview" renderer. **CPU path stays the bit-exact oracle** — GPU transcendentals
  (pow/sqrt) won't match last-bit, so GPU is preview-only.

Tile correction is out of scope (see `biome-accuracy-ceiling` memory).
```
