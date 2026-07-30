# SE Universe Seed Finder

Fast parallel seed generator for Space Exploration (Factorio 0.7.x) written in Zig.
Filters seeds by naquium field distance and productivity modules, outputs Calidus-system
JSONL for analysis.

## Install

Builds the Zig components (`seedgen`, `segen`, the `gpu_*` compute binaries) and
installs the web server's dependencies. Works on macOS, Linux, and Windows.

**Prerequisites:** [Zig 0.16.x](https://ziglang.org/download/) and
[Node ≥18](https://nodejs.org/) on your `PATH`.

### Option A — install straight from GitHub (only the relevant source)

`npm` clones the repo, pulls **only** the source the app needs (per the `files`
allowlist in `package.json` — no calibration/ghidra/output/etc.), then a
`postinstall` hook builds the Zig binaries and downloads the pinned
`wgpu-native` prebuilt for your platform:

```sh
npm install github:Ober3550/seed-search
npx seed-search            # → http://localhost:3456
```

The `github:` spec makes `npm` shell out to `git clone`. If `git` isn't on your
`PATH`, install from the tarball endpoint instead — same package, no `git`:

```sh
npm install https://github.com/Ober3550/seed-search/tarball/HEAD
```

### Option B — clone and run the installer

```sh
git clone https://github.com/Ober3550/seed-search.git && cd seed-search
node install.mjs      # any platform — this is the installer
npm start             # → http://localhost:3456
```

On **Windows**, from `cmd.exe` or PowerShell:

```bat
git clone https://github.com/Ober3550/seed-search.git && cd seed-search
install.cmd
npm start
```

`install.cmd` (Windows) and `./install.sh` (macOS / Linux) are one-line
bootstrappers that do nothing but locate Node and call `install.mjs`.

Both are safe to re-run (every step is idempotent). `node install.mjs
--build-only` builds just the Zig binaries (skips the server's `npm install`).

### Windows notes

Nothing in the install path is PowerShell, deliberately. `.ps1` files are
refused under the default `Restricted` ExecutionPolicy on Windows client
installs, and a `.ps1` downloaded from GitHub carries Mark-of-the-Web so even
`RemoteSigned` rejects it. `install.cmd` and `node install.mjs` are unaffected,
and `npm` runs the `postinstall` hook through `cmd.exe`, not PowerShell.

**The policy does still block `npm` itself.** Node's Windows installer ships
`npm.ps1` alongside `npm.cmd`, and PowerShell prefers the `.ps1`, so under
`Restricted` every npm command fails before it starts:

```
npm : File C:\Program Files\nodejs\npm.ps1 cannot be loaded because running
scripts is disabled on this system.
```

That message means npm **is** installed and PowerShell refused to run it — a
missing npm reads `The term 'npm' is not recognized...` instead. The same
applies to `npx`, and to any CLI installed by npm: it writes `.ps1`, `.cmd` and
bash shims into `node_modules\.bin`, and PowerShell picks the blocked one.

Pick whichever you prefer:

```powershell
# Fix it once, per-user, no admin. npm.ps1 is a local file, so RemoteSigned
# allows it; only downloaded scripts stay blocked.
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned

# Or bypass the shim per-command, changing nothing on the machine:
npm.cmd install github:Ober3550/seed-search
npm.cmd start

# Or run from cmd.exe instead of PowerShell, which resolves npm.cmd on its own.
```

None of this affects `install.cmd` or `node install.mjs` — `install.mjs`
spawns `npm.cmd` explicitly on Windows.

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
