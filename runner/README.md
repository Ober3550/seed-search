# Runner

Distributed execution infrastructure for the seed finder.

## Files

- `manager.lua` — distributed task manager: fetches work from the server, spawns
  worker processes, and uploads results
- `bin/` — Lua interpreter binaries (native Linux x86_64)
- `blob/` — source tarballs for the native modules compiled into `bin/lua`
- `mods/` — Space Exploration mod zip (runtime dependency of the generator)
- `output/` — generated binary universe files, one per chunk
- `docs/` — detailed documentation (generation algorithm, PRNG accounting, port status)

## Usage

From the repo root:

```sh
./run.sh      # Linux
run.bat       # Windows
```

This launches `manager.lua` via the native Lua interpreter. The manager reads
`_config.json` and `_queue.json` from this directory.

## Docker

On Apple Silicon (or other non-Linux hosts), the `bin/lua` interpreter runs
through the `seedlua` image:

```sh
docker build --platform linux/amd64 -t seedlua - <<'EOF'
FROM --platform=linux/amd64 debian:bookworm-slim
RUN apt-get update -qq && apt-get install -y -qq libreadline8 libcurl4 && rm -rf /var/lib/apt/lists/*
EOF

docker run --rm --platform linux/amd64 -v "$PWD":/w -w /w \
  --entrypoint /w/runner/bin/lua-linux-x86_64 seedlua generator/generate.lua 0
```
