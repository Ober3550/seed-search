# SE Universe Seed Finder

Fast parallel seed generator for Space Exploration (Factorio 0.7.x) written in Zig.
Filters seeds by naquium field distance and productivity modules, outputs Calidus-system
JSONL for analysis.

## Quick start

```bash
# 1. Build
cd generator/zig && zig build-exe main.zig -O ReleaseFast -femit-bin=seedgen -target aarch64-linux-gnu -lc
cd ../..
docker build --platform linux/arm64 -t seed-search-seedgen -f runner/zig/Dockerfile.zig .

# 2. Run 1M seeds with 8 parallel workers
./run_all.sh 1000000 8
```

## Prerequisites

- [Zig](https://ziglang.org/) 0.16.x
- Docker with Linux ARM64 support (for macOS: Docker Desktop)

## Project structure

```
├── generator/zig/   Zig seed generator (main.zig, gen.zig, data.zig)
├── verifier/        JS analyzer + Lua comparison harness
├── output/          Generated JSONL files (gitignored)
├── run_all.sh       Orchestrator: parallel 100K-bucket containers
├── entrypoint.sh    Docker entrypoint (redirects stdout to bucket files)
├── Dockerfile.zig   Docker image for seedgen
├── docker-compose.yml
└── .env.example     Template for local configuration
```

## Configuration

Copy `.env.example` to `.env` and edit:

```sh
cp .env.example .env
```

Key settings:
- `SE_K2` — set to `1` for Krastorio2
- `MIN_NAQ_DV` — skip seeds with no naquium field closer than this (default 20000)
- `MIN_PROD_MODULES` — skip seeds with fewer than N productivity modules (default 4)

## Running

```bash
# Production: 1M seeds, 8 parallel workers, filters on
./run_all.sh 1000000 8

# Without filters (testing)
MIN_NAQ_DV=0 MIN_PROD_MODULES=0 ./run_all.sh 1000000 8

# Single range
docker run --rm --platform linux/arm64 --ulimit stack=1073741824 \
  -v "$(pwd)/output:/workspace/output" \
  -e START_SEED=0 -e END_SEED=100000 -e SE_K2=1 \
  seed-search-seedgen
```

Output files go to `output/seeds_100000.jsonl`, `output/seeds_200000.jsonl`, etc.
Progress logs go to `output/progress.log`.

## Analysis

```bash
# Show Calidus viable bodies (colored table)
node verifier/analyze.js output

# Show all seeds (no PPSS loot filter)
node verifier/analyze.js --all output
```

## Verification

Compare Zig output against Lua (requires Docker):

```bash
./verifier/verify/compare-zig-lua.sh --count 5
```
