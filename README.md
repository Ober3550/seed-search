# SE Universe Seed Finder

Fast parallel seed generator for Space Exploration (Factorio 0.7.x) written in Zig.
Filters seeds by naquium field distance and productivity modules, outputs Calidus-system
JSONL for analysis.

## Prerequisites

Install these first. `install.mjs` checks the first two before it builds
anything and stops with an explanation if one is missing or the wrong version:

- **[Zig 0.16.x](https://ziglang.org/download/)** — builds `seedgen`, `segen`
  and the `gpu_*` binaries. 0.15 and 0.17 will not work; the installer rejects
  anything outside 0.16.x. Verify with `zig version`.
- **[Node.js ≥18](https://nodejs.org/)** — runs the installer, the web server
  and the analyzer. Ships `npm`. Verify with `node --version`.
- **[git](https://git-scm.com/)** — to clone the repo in the first place.

All three must be on your `PATH` in the shell you run the installer from.
Beyond them the installer fetches everything it needs (the `wgpu-native`
prebuilt, htmx, the npm packages).

## Install

Clone the repo and run the installer. The same three commands work on macOS,
Linux, and Windows (from `cmd.exe` or PowerShell):

```sh
git clone https://github.com/Ober3550/seed-search.git
cd seed-search
node install.mjs      # this is the installer, on every platform
npm start             # → http://localhost:3456
```

`node install.mjs` is the single, cross-platform installer — there are no
per-platform bootstrap scripts to pick between. Run it before the first
`npm start`, and re-run it after pulling. It is safe to re-run: every step is
idempotent (Zig rebuilds incrementally, downloads are skipped when already
present, `npm install` is a no-op when up to date).

### What the installer does

1. Builds `seedgen` → `universe_generator/zig/` (the universe generator).
2. Builds `segen` → `surface_generator/zig-out/bin/` (the CPU surface generator).
3. Downloads the pinned `wgpu-native` prebuilt for your platform into
   `gpu_compute/vendor/<triple>/` (gitignored).
4. Builds the `gpu_*` compute binaries → `gpu_compute/zig-out/bin/`. On Windows
   it also copies `wgpu_native.dll` next to them: PE has no rpath, so the
   binaries can only find the library in their own directory.
5. Fetches htmx → `space_explorer_gui/public/htmx.min.js` (checksum-verified).
6. Installs the web server's npm dependencies.

The GUI is entirely htmx-driven, so without `htmx.min.js` the page still renders
but no button does anything — queueing a job sends no request at all. The server
warns on startup if that file is missing or stubbed.

`node install.mjs --build-only` runs steps 1–5 and skips the server's `npm
install`. `node install.mjs --help` lists the flags and the environment
overrides (`WGPU_VERSION`, `HTMX_VERSION`).

### Windows notes

Nothing in the install path is PowerShell, deliberately. `.ps1` files are
refused under the default `Restricted` ExecutionPolicy on Windows client
installs, and a `.ps1` downloaded from GitHub carries Mark-of-the-Web so even
`RemoteSigned` rejects it. `node install.mjs` is unaffected — it is plain Node,
invoked directly.

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

This only affects `npm start`; `node install.mjs` runs either way, because it
spawns `npm.cmd` explicitly on Windows. Pick whichever you prefer:

```powershell
# Fix it once, per-user, no admin. npm.ps1 is a local file, so RemoteSigned
# allows it; only downloaded scripts stay blocked.
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned

# Or bypass the shim per-command, changing nothing on the machine:
npm.cmd start

# Or run from cmd.exe instead of PowerShell, which resolves npm.cmd on its own.
```

## Project structure

```
├── universe_generator/zig/  Zig seed generator (main.zig, gen.zig, data.zig)
├── surface_generator/       Zig surface/ore generator
├── gpu_compute/             Zig GPU terrain/ore/biome kernels
├── space_explorer_gui/      Web explorer + job manager (npm start)
├── verifier/                JS analyzer + Lua comparison harness
├── output/                  Generated JSONL files (gitignored)
├── install.mjs              Cross-platform installer (builds all Zig components)
├── docker-compose.yml
└── .env.example             Template for local configuration
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

Start the server and queue 100K-seed buckets from the GUI — the built-in job
manager runs them in parallel and imports the results:

```bash
npm start             # → http://localhost:3456
```

To run a single bucket directly against the generator binary:

```bash
START_SEED=0 END_SEED=100000 SE_K2=1 \
  universe_generator/zig/seedgen > output/seeds_100000.jsonl
```

Bucket output goes to `output/<bucket>/seeds.jsonl`.

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
