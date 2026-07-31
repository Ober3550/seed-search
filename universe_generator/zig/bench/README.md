# SE Universe Generation Benchmarks

Compares the performance of the Lua (reference) and Zig (ported) universe generators.

## Quick Run

```bash
# Run both benchmarks (50 seeds each)
./runner/native/zig/bench/bench.sh 50

# Zig only (native, very fast)
time for i in $(seq 1 50); do ./runner/native/zig/seedgen > /dev/null 2>&1; done
```

## Files

- `bench.sh` — Shell script that runs both Lua (Docker) and Zig benchmarks
- `bench_lua.lua` — Lua benchmark harness (requires extracted SE mod files)
- `../seedgen` — Zig binary (pre-built, or build with `zig build-exe runner/native/zig/main.zig -femit-bin=runner/native/zig/seedgen -O ReleaseFast`)

## Expected Results (Apple Silicon M-series)

| Implementation                | 50 seeds  | Per seed  |
| ----------------------------- | --------- | --------- |
| Zig (native ARM64)            | ~300ms    | ~6ms      |
| Lua (Docker, emulated x86_64) | ~40,000ms | ~800ms    |
| **Speedup**                   |           | **~130×** |

On native x86_64 Linux, Lua runs ~30-50% faster (no emulation overhead), giving Zig a ~50-80× advantage.

## Why Zig is faster

1. **Compiled to machine code** — no bytecode interpretation overhead
2. **Arena allocation** — single free at the end, no GC pauses
3. **Cache-friendly data** — contiguous arrays (ArrayLists) vs Lua's hash tables
4. **No string hashing** — Zig string slices are just pointer+length; Lua hashes every table key lookup
