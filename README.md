# SE Universe Seed Finder

Fast parallel seed generator for Space Exploration (Factorio 0.7.x) written in Zig.
Filters seeds by naquium field distance and productivity modules, outputs Calidus-system
JSONL for analysis.

## Install

Builds the Zig components (`seedgen`, `segen`, the `gpu_*` compute binaries),
fetches the GUI's front-end dependency (htmx), and installs the web server's
dependencies. Works on macOS, Linux, and Windows.

Run the installer before the first `npm start`, and re-run it after pulling. The
GUI is entirely htmx-driven, so without `space_explorer_gui/public/htmx.min.js`
the page still renders but no button does anything — queueing a job sends no
request at all. The server warns on startup if that file is missing or stubbed.

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
node install.mjs
npm start
```

`node install.mjs` is the single, cross-platform installer — there are no
per-platform bootstrap scripts to pick between.

It is safe to re-run (every step is idempotent). `node install.mjs
--build-only` builds just the Zig binaries (skips the server's `npm install`).

### Windows notes

Nothing in the install path is PowerShell, deliberately. `.ps1` files are
refused under the default `Restricted` ExecutionPolicy on Windows client
installs, and a `.ps1` downloaded from GitHub carries Mark-of-the-Web so even
`RemoteSigned` rejects it. `node install.mjs` is unaffected,
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

None of this affects `node install.mjs` — `install.mjs`
spawns `npm.cmd` explicitly on Windows.

## Quick start

```bash
# 1. Build the Zig components + install server deps
node install.mjs

# 2. Start the explorer, then queue seed buckets from the GUI
npm start             # → http://localhost:3456
```

## Prerequisites

- [Zig](https://ziglang.org/) 0.16.x
- Node.js >= 18

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
