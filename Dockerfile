# Worker image for the seed-search Zig binaries (universe/surface/GPU).
#
# The binaries are near-static after build(gpu): statically link wgpu-native:
#   - seedgen / segen link only libc
#   - gpu_terrain / gpu_ore / gpu_biome / gpu_stitch link libc + libm
# So a slim glibc base is all that's required at runtime — no Zig toolchain,
# no libpq, no wgpu .so. The GPU drivers are dlopened from the host via
# libdl/libm at runtime and are NOT baked into this image.
#
# The image is meant to be driven by seed-search's job-manager, which runs
# each worker as:
#   docker run --rm -v <repo>/output:/workspace/output -e ... <image> <cmd>
# with the worker-selected env vars (START_SEED, END_SEED, SE_K2, tail
# cutoffs, ALL_ZONES, ...) and stdout piped to the bucket's seeds.jsonl.
#
# DISK FOOTPRINT (measured 2026-08-10, for resource-conscious deployment):
#   - image Size ~47 MiB on disk (one-time per host, shared across all workers)
#   - ~0 MiB per running worker: the writable layer stays empty (output goes to
#     the bind-mounted /workspace/output volume), and spawnWorker uses --rm so
#     the container + layer are removed on exit. No per-worker disk accumulation.
# Per-worker runtime caps are set via spawnWorker env: SE_WORKER_MEM (2g,
# --memory/--memory-swap), SE_WORKER_CPUS (1), SE_WORKER_SHARES (256).
#
# The only real disk usage is the generated data in the mounted output volume.

FROM debian:bookworm-slim

WORKDIR /workspace

# Seedgen (universe generation / expand) + segen (surface) + GPU compute.
COPY universe_generator/zig/seedgen /usr/local/bin/seedgen
COPY surface_generator/zig-out/bin/segen /usr/local/bin/segen
COPY gpu_compute/zig-out/bin/gpu_terrain /usr/local/bin/gpu_terrain
COPY gpu_compute/zig-out/bin/gpu_biome  /usr/local/bin/gpu_biome
COPY gpu_compute/zig-out/bin/gpu_ore    /usr/local/bin/gpu_ore
COPY gpu_compute/zig-out/bin/gpu_stitch /usr/local/bin/gpu_stitch

RUN chmod +x /usr/local/bin/seedgen /usr/local/bin/segen \
    /usr/local/bin/gpu_terrain /usr/local/bin/gpu_biome \
    /usr/local/bin/gpu_ore /usr/local/bin/gpu_stitch \
  && mkdir -p /workspace/output

# No default ENTRYPOINT/CMD: job-manager passes the binary + args explicitly
# (docker run --rm <image> seedgen ...). Cross-architecture GPU passthrough
# (--device=/dev/dri or /dev/kfd) is the operator's responsibility.
